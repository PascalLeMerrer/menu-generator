import app/adapters/recipes
import app/pages
import app/pages/layout.{layout}
import app/routes/recipe_routes
import app/services/meals
import app/web.{type Context}
import gleam/http
import gleam/io
import gleam/json.{
  UnableToDecode, UnexpectedByte, UnexpectedEndOfInput, UnexpectedFormat,
  UnexpectedSequence,
}
import gleam/list
import gleam/result
import simplifile

import lustre/element
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use _req <- web.middleware(req, ctx)

  case wisp.path_segments(req) {
    [] -> {
      [pages.home()]
      |> layout
      |> element.to_document_string_builder
      |> wisp.html_response(200)
    }
    ["import"] -> {
      [pages.upload()]
      |> layout
      |> element.to_document_string_builder
      |> wisp.html_response(200)
    }
    ["meals"] -> {
      use <- wisp.require_method(req, http.Post)
      let meals = meals.generate_random_meals(ctx)
      case meals {
        Ok(generated_meals) ->
          [pages.generated_meals(generated_meals)]
          |> layout
          |> element.to_document_string_builder
          |> wisp.html_response(200)
        Error(error_message) ->
          pages.error(error_message)
          // TODO factorize the next lines into a render function? Wait for HTMX to be in place
          |> element.to_document_string_builder
          |> wisp.html_response(200)
      }
    }
    ["new-meals"] -> {
      pages.new_meals()
      |> element.to_document_string_builder
      |> wisp.html_response(200)
    }
    ["recipes"] -> {
      let all_recipes = recipes.get_all(ctx.connection)
      pages.recipes(all_recipes)
      |> element.to_document_string_builder
      |> wisp.html_response(200)
    }

    ["recipes", "upload"] -> {
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
              let _ = parsed_recipes |> recipes.bulk_insert(ctx.connection)
              [pages.upload_result(parsed_recipes)]
              |> layout
              |> element.to_document_string_builder
              |> wisp.html_response(200)
            }
            Error(UnexpectedEndOfInput) -> {
              io.println("UnexpectedEndOfInput")
              wisp.bad_request()
            }
            Error(UnexpectedByte(str)) -> {
              io.println("UnexpectedByte " <> str)
              wisp.bad_request()
            }
            Error(UnexpectedSequence(str)) -> {
              io.println("UnexpectedSequence " <> str)
              wisp.bad_request()
            }
            Error(UnexpectedFormat(errors)) -> {
              io.debug(errors)
              wisp.bad_request()
            }
            Error(UnableToDecode(errors)) -> {
              io.debug(errors)
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
}
