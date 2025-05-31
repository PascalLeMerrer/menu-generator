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
                echo "step 1"
                case meal_adapter.delete(valid_meal_id, ctx.connection) {
                  Ok(_) -> string_tree.new() |> wisp.html_response(200)
                  Error(_) -> error_message("L'affacement du repas a échoué")
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
          Ok(generated_meals) ->
            [generated_meals.page(generated_meals)]
            |> layout
            |> render
          Error(message) -> error_message(message)
        }
      }

      ["meals-list"] -> {
        let one_week_ago =
          instant.now()
          |> instant.as_local_datetime
          |> datetime.subtract(duration.days(days_in_week))
        let all_meals = meal_adapter.get_after(ctx.connection, one_week_ago)
        meal_list_page.page(all_meals)
        |> render
      }

      ["recipes-import"] -> {
        [upload.page()]
        |> layout
        |> render
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
              recipe_adapter.find_by_id(ctx.connection, valid_recipe_id)

            case recipe {
              [Ok(valid_recipe)] ->
                [recipes.view_ingredients(valid_recipe)]
                |> layout
                |> render
              [Error(_)] -> error_message("ingrédients non trouvés 1")
              [] -> error_message("ingrédients non trouvés 2")
              [_, _, ..] -> error_message("ingrédients non trouvés 3")
            }
          }
          Error(_) -> error_message("l'identifiant de la recette est invalide")
        }
      }

      ["recipes-list"] -> {
        let all_recipes = recipe_adapter.get_all(ctx.connection)
        recipes.page(all_recipes)
        |> render
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
          use parsed_recipe_id <- result.try({ uuid.from_string(recipe_id) })
          Ok(#(parsed_meal_id, parsed_recipe_id))
        }

        case parsed_parameters {
          Ok(#(valid_meal_id, parsed_recipe_id)) -> {
            let meals =
              meals.replace_recipe(ctx, valid_meal_id, parsed_recipe_id)

            case meals {
              Ok([generated_meals]) ->
                [meal_renderer.view(generated_meals)]
                |> layout
                |> render
              Error(message) -> error_message(message)
              Ok([]) -> error_message("aucun menu généré")
              Ok([_, _, ..]) -> error_message("multiples menus générés")
            }
          }
          Error(_) ->
            error_message(
              "l'identifiant du repas ou de la recette est invalide",
            )
        }
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
              recipe_adapter.find_by_id(ctx.connection, valid_recipe_id)

            case recipe {
              [Ok(valid_recipe)] ->
                [recipes.view_steps(valid_recipe)]
                |> layout
                |> render
              [Error(_)] -> error_message("étapes non trouvées 1")
              [] -> error_message("étapes non trouvées 2")
              [_, _, ..] -> error_message("étapes non trouvées 3")
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
                  parsed_recipes |> recipe_adapter.bulk_insert(ctx.connection)
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
