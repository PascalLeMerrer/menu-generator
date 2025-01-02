import app/models/recipe
import app/pages
import app/pages/layout.{layout}
import app/routes/item_routes.{items_middleware}
import app/web.{type Context}
import gleam/http
import gleam/int
import gleam/io
import gleam/json.{
  UnableToDecode, UnexpectedByte, UnexpectedEndOfInput, UnexpectedFormat,
  UnexpectedSequence,
}
import gleam/list
import gleam/result
import gleam/string_tree
import simplifile

import lustre/element
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use _req <- web.middleware(req, ctx)
  use ctx <- items_middleware(req, ctx)

  case wisp.path_segments(req) {
    // Homepage
    [] -> {
      [pages.home(ctx.items)]
      |> layout
      |> element.to_document_string_builder
      |> wisp.html_response(200)
    }
    ["items", "create"] -> {
      use <- wisp.require_method(req, http.Post)
      item_routes.post_create_item(req, ctx)
    }
    ["items", id] -> {
      use <- wisp.require_method(req, http.Delete)
      item_routes.delete_item(req, ctx, id)
    }

    ["upload"] -> {
      use <- wisp.require_method(req, http.Post)
      use formdata <- wisp.require_form(req)
      let result = {
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
          case recipe.from_xml(file_content) {
            Ok(recipes) -> {
              string_tree.new()
              |> string_tree.append(
                "<p>"
                <> { list.length(recipes) |> int.to_string }
                <> " recettes importées</p>",
              )
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
