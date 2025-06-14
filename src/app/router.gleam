import app/adapters/meal as meal_adapter
import app/adapters/recipe as recipe_adapter
import app/helpers/decoding
import app/models/date as date_model
import app/pages/date_selection
import app/pages/error
import app/pages/generated_meals
import app/pages/home
import app/pages/layout.{layout}
import app/pages/meal_renderer
import app/pages/meals as meal_list_page
import app/pages/recipes
import app/pages/upload
import app/pages/upload_result
import app/routes/recipe_routes
import app/services/meals
import app/web.{type Context}
import gleam/http
import gleam/int
import gleam/json.{
  UnableToDecode, UnexpectedByte, UnexpectedEndOfInput, UnexpectedFormat,
  UnexpectedSequence,
}
import gleam/list
import gleam/option
import gleam/result
import gleam/string_tree
import simplifile
import tempo/datetime
import tempo/duration
import tempo/instant
import youid/uuid

import lustre/element
import wisp.{type Request, type Response}

const days_in_week = 7

pub fn handle_request(req: Request, ctx: Context) -> Response {
  web.middleware(req, ctx, fn(_req) {
    case wisp.path_segments(req) {
      [] -> {
        [home.page()]
        |> layout
        |> render
      }

      ["date-select"] -> {
        let today = instant.now() |> instant.as_local_date()
        date_selection.page(date_model.for_potential_meals(today))
        |> render
      }

      ["meals", meal_id] -> {
        let parsed_parameters = {
          use parsed_meal_id <- result.try({ uuid.from_string(meal_id) })
          Ok(parsed_meal_id)
        }
        case parsed_parameters {
          Ok(valid_meal_id) ->
            case req.method {
              http.Delete -> {
                case meal_adapter.delete(valid_meal_id, ctx.connection) {
                  Ok(_) -> string_tree.new() |> wisp.html_response(200)
                  Error(_) -> error_message("L'effacement du repas a échoué")
                }
              }
              _ -> wisp.method_not_allowed([])
            }
          Error(Nil) ->
            error_message(
              meal_id <> " n'est pas un identifiant de repas valide",
            )
        }
      }

      ["meals-generate"] -> {
        use req <- web.middleware(req, ctx)
        use formdata <- wisp.require_form(req)

        let meal_dates =
          formdata.values
          |> list.key_filter("meal_date")
          |> list.try_map(fn(meal_date) { int.parse(meal_date) })
          |> result.map(fn(dates) {
            list.map(dates, fn(meal_date) {
              datetime.from_unix_milli(meal_date)
            })
          })

        let meals = case meal_dates {
          Ok(valid_dates) -> meals.generate_random_meals(ctx, valid_dates)
          Error(_) -> Error("dates invalides")
        }
        case meals {
          Ok(generated_meals) -> {
            [generated_meals.page(generated_meals)]
            |> layout
            |> render
          }
          Error(message) -> error_message(message)
        }
      }

      ["meals-list"] -> {
        let one_week_ago =
          instant.now()
          |> instant.as_local_datetime
          |> datetime.subtract(duration.days(days_in_week))
        let recent_meals = meal_adapter.get_after(one_week_ago, ctx.connection)
        let recipes = case recent_meals |> result.all {
          Error(_) -> []
          Ok(meals) -> {
            meals
            |> list.map(fn(m) {
              recipe_adapter.find_by_meal_id(m.uuid, ctx.connection)
            })
            |> list.flatten
          }
        }

        meal_list_page.page(recent_meals, recipes)
        |> render
      }

      ["recipes", recipe_id] -> {
        let parsed_parameters = {
          use parsed_recipe_id <- result.try({ uuid.from_string(recipe_id) })
          Ok(parsed_recipe_id)
        }
        case parsed_parameters {
          Ok(valid_recipe_id) ->
            case req.method {
              http.Delete -> {
                case recipe_adapter.delete(valid_recipe_id, ctx.connection) {
                  Ok(_) -> string_tree.new() |> wisp.html_response(200)
                  Error(_) ->
                    error_message("L'effacement de la recette a échoué")
                }
              }
              _ -> wisp.method_not_allowed([])
            }
          Error(Nil) ->
            error_message(
              recipe_id <> " n'est pas un identifiant de recette valide",
            )
        }
      }

      ["recipes-import"] -> {
        [upload.page()]
        |> layout
        |> render
      }

      ["recipes-add-to-meal"] -> {
        use req <- web.middleware(req, ctx)
        use formdata <- wisp.require_form(req)
        let parsed_parameters = {
          use meal_id <- result.try(list.key_find(formdata.values, "meal_id"))
          use parsed_meal_id <- result.try({ uuid.from_string(meal_id) })
          use recipe_id <- result.try(list.key_find(
            formdata.values,
            "recipe_id",
          ))
          use parsed_recipe_id <- result.try({ uuid.from_string(recipe_id) })
          Ok(#(parsed_meal_id, parsed_recipe_id))
        }

        case parsed_parameters {
          Ok(#(valid_meal_id, valid_recipe_id)) -> {
            let recipe = recipe_adapter.get(valid_recipe_id, ctx.connection)
            let meal = meal_adapter.get(valid_meal_id, ctx.connection)

            case meal, recipe {
              Ok(valid_meal), Ok(valid_recipe) -> {
                let updated_recipe = meals.add_to_meal(valid_meal, valid_recipe)
                let inserted_recipe =
                  recipe_adapter.bulk_insert([updated_recipe], ctx.connection)
                  |> result.all
                let meal_recipes =
                  recipe_adapter.find_by_meal_id(valid_meal_id, ctx.connection)
                  |> result.all
                case meal_recipes, inserted_recipe {
                  Ok(valid_recipes), Ok(_) -> {
                    {
                      [meal_renderer.view(valid_meal, valid_recipes)]
                      |> layout
                      |> render
                      |> wisp.set_header(
                        "HX-location",
                        "{\"path\": \"meals-list\", \"target\": \"#main\"}",
                      )
                    }
                  }
                  Error(_), _ ->
                    error_message(
                      "Erreur de lecture des recettes associées au repas",
                    )
                  _, Error(_) ->
                    error_message(
                      "Erreur de l'écriture de la nouvelle recettes associée au repas",
                    )
                }
              }
              Error(message), _ -> error_message(message)
              _, Error(message) -> error_message(message)
            }
          }
          Error(_) ->
            error_message(
              "l'identifiant du repas ou de la recette est invalide",
            )
        }
      }

      ["recipes-ingredients"] -> {
        use req <- web.middleware(req, ctx)
        use formdata <- wisp.require_form(req)

        let parsed_recipe_id = {
          use recipe_id <- result.try(list.key_find(
            formdata.values,
            "recipe_id",
          ))
          use parsed_recipe_id <- result.try({ uuid.from_string(recipe_id) })
          Ok(parsed_recipe_id)
        }

        case parsed_recipe_id {
          Ok(valid_recipe_id) -> {
            let recipe =
              recipe_adapter.find_by_id(valid_recipe_id, ctx.connection)

            case recipe {
              [Ok(valid_recipe)] ->
                [recipes.view_ingredients(valid_recipe)]
                |> layout
                |> render
              [Error(_)] -> error_message("ingrédients non trouvés (1)")
              [] -> error_message("ingrédients non trouvés (2)")
              [_, _, ..] -> error_message("ingrédients non trouvés (3)")
            }
          }
          Error(_) -> error_message("l'identifiant de la recette est invalide")
        }
      }

      ["recipes-list"] -> {
        let all_recipes = recipe_adapter.get_all(ctx.connection)
        recipes.page(all_recipes, option.None)
        |> render
      }

      ["recipes-metadata"] -> {
        use req <- web.middleware(req, ctx)
        use formdata <- wisp.require_form(req)

        let parsed_recipe_id = {
          use recipe_id <- result.try(list.key_find(
            formdata.values,
            "recipe_id",
          ))
          use parsed_recipe_id <- result.try({ uuid.from_string(recipe_id) })
          Ok(parsed_recipe_id)
        }

        case parsed_recipe_id {
          Ok(valid_recipe_id) -> {
            let recipe =
              recipe_adapter.find_by_id(valid_recipe_id, ctx.connection)

            case recipe {
              [Ok(valid_recipe)] ->
                [recipes.view_metadata(valid_recipe)]
                |> layout
                |> render
              [Error(_)] -> error_message("métadonnées non trouvées (1)")
              [] -> error_message("métadonnées non trouvées (2)")
              [_, _, ..] -> error_message("métadonnées non trouvées (3)")
            }
          }
          Error(_) -> error_message("l'identifiant de la recette est invalide")
        }
      }

      ["recipes-replace"] -> {
        use req <- web.middleware(req, ctx)
        use formdata <- wisp.require_form(req)
        let parsed_parameters = {
          use meal_id <- result.try(list.key_find(formdata.values, "meal_id"))
          use parsed_meal_id <- result.try({ uuid.from_string(meal_id) })
          use recipe_id <- result.try(list.key_find(
            formdata.values,
            "recipe_id",
          ))
          use valid_recipe_id <- result.try({ uuid.from_string(recipe_id) })
          Ok(#(parsed_meal_id, valid_recipe_id))
        }

        case parsed_parameters {
          Ok(#(valid_meal_id, parsed_recipe_id)) -> {
            let meals =
              meals.replace_recipe_with_random_one(
                ctx,
                valid_meal_id,
                parsed_recipe_id,
              )

            case meals {
              Ok(#(updated_meal, meal_recipes)) ->
                [meal_renderer.view(updated_meal, meal_recipes)]
                |> layout
                |> render
              Error(message) -> error_message(message)
            }
          }
          Error(_) ->
            error_message(
              "l'identifiant du repas ou de la recette est invalide",
            )
        }
      }

      ["recipes-search"] -> {
        use req <- web.middleware(req, ctx)
        use formdata <- wisp.require_form(req)

        let parameters = {
          use searched_string <- result.try(list.key_find(
            formdata.values,
            "searched_string",
          ))
          use meal_id <- result.try(list.key_find(formdata.values, "meal_id"))
          Ok(#(searched_string, meal_id))
        }

        case parameters {
          Ok(#("", meal_id_or_empty)) -> {
            let meal_to_change = some_meal_id(meal_id_or_empty)
            let all_recipes = recipe_adapter.get_all(ctx.connection)
            recipes.page(all_recipes, meal_to_change)
            |> render
          }
          Ok(#(non_empty_string, maybe_meal_id)) -> {
            let meal_to_change = some_meal_id(maybe_meal_id)
            let filtered_recipes =
              recipe_adapter.find_by_content(non_empty_string, ctx.connection)

            recipes.page(filtered_recipes, meal_to_change)
            |> render
          }
          Error(_) -> error_message("Critère de recherche invalide")
        }
      }

      // displays the list of recipes in order to select one to be added to the given meal
      ["recipes-select"] -> {
        use req <- web.middleware(req, ctx)
        use formdata <- wisp.require_form(req)

        let id_of_meal_to_change = {
          use meal_id <- result.try(list.key_find(formdata.values, "meal_id"))
          use parsed_meal_id <- result.try({ uuid.from_string(meal_id) })
          Ok(parsed_meal_id)
        }
        let meal_to_change = option.from_result(id_of_meal_to_change)

        let all_recipes = recipe_adapter.get_all(ctx.connection)

        recipes.page(all_recipes, meal_to_change)
        |> render
      }

      ["recipes-steps"] -> {
        use req <- web.middleware(req, ctx)
        use formdata <- wisp.require_form(req)

        let parsed_recipe_id = {
          use recipe_id <- result.try(list.key_find(
            formdata.values,
            "recipe_id",
          ))
          use parsed_recipe_id <- result.try({ uuid.from_string(recipe_id) })
          Ok(parsed_recipe_id)
        }

        case parsed_recipe_id {
          Ok(valid_recipe_id) -> {
            let recipe =
              recipe_adapter.find_by_id(valid_recipe_id, ctx.connection)

            case recipe {
              [Ok(valid_recipe)] ->
                [recipes.view_steps(valid_recipe)]
                |> layout
                |> render
              [Error(_)] -> error_message("étapes non trouvées (1)")
              [] -> error_message("étapes non trouvées (2)")
              [_, _, ..] -> error_message("étapes non trouvées (3)")
            }
          }
          Error(_) -> error_message("l'identifiant de la recette est invalide")
        }
      }

      ["recipes-upload"] -> {
        use <- wisp.require_method(req, http.Post)
        use formdata <- wisp.require_form(req)
        let result: Result(String, Nil) = {
          // Note the name of the input is used to find the value.
          use file <- result.try(list.key_find(formdata.files, "uploaded-file"))

          // The file has been streamed to a temporary file on the disc, so there's no
          // risk of large files causing memory issues.
          // The `.path` field contains the path to this file, which you may choose to
          // move or read using a library like `simplifile`. When the request is done the
          // temporary file is deleted.
          wisp.log_info("File uploaded to " <> file.path)
          Ok(file.path)
        }

        case result {
          Ok(path) -> {
            let assert Ok(file_content) = simplifile.read(from: path)
            case recipe_routes.from_xml(file_content) {
              Ok(parsed_recipes) -> {
                let _ = recipe_adapter.delete_unlinked(ctx.connection)
                let _ =
                  recipe_adapter.bulk_insert(parsed_recipes, ctx.connection)

                [upload_result.page(parsed_recipes)]
                |> layout
                |> render
              }
              Error(UnexpectedEndOfInput) -> {
                wisp.log_error("UnexpectedEndOfInput")
                wisp.bad_request()
              }
              Error(UnexpectedByte(str)) -> {
                wisp.log_error("UnexpectedByte " <> str)
                wisp.bad_request()
              }
              Error(UnexpectedSequence(str)) -> {
                wisp.log_error("UnexpectedSequence " <> str)
                wisp.bad_request()
              }
              Error(UnexpectedFormat(errors)) -> {
                wisp.log_error(
                  errors |> decoding.dynamic_decoding_errors_to_string,
                )
                wisp.bad_request()
              }
              Error(UnableToDecode(errors)) -> {
                wisp.log_error(errors |> decoding.decoding_errors_to_string)
                wisp.bad_request()
              }
            }
          }
          Error(_) -> {
            wisp.bad_request()
          }
        }
      }

      // All the empty responses
      ["internal-server-error"] -> wisp.internal_server_error()
      ["unprocessable-entity"] -> wisp.unprocessable_entity()
      ["method-not-allowed"] -> wisp.method_not_allowed([])
      ["entity-too-large"] -> wisp.entity_too_large()
      ["bad-request"] -> wisp.bad_request()
      _ -> wisp.not_found()
    }
  })
}

fn error_message(message: String) -> Response {
  error.page("Erreur : " <> message)
  |> render
}

fn render(html_nodes: element.Element(a)) -> Response {
  html_nodes
  |> element.to_document_string_builder
  |> wisp.html_response(200)
}

fn some_meal_id(maybe_meal_id: String) -> option.Option(uuid.Uuid) {
  case maybe_meal_id {
    "" -> option.None
    _ ->
      maybe_meal_id
      |> uuid.from_string
      |> option.from_result
  }
}
