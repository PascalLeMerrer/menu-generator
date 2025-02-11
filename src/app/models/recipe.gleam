import gleam/dynamic
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/string
import youid/uuid

pub type Recipe {
  Recipe(
    image: String,
    ingredients: List(String),
    meal_id: Option(uuid.Uuid),
    steps: String,
    title: String,
  )
}

pub const separator = "@"

pub fn decode(
  fields: dynamic.Dynamic,
) -> Result(Recipe, List(dynamic.DecodeError)) {
  let decoded_record =
    fields
    |> dynamic.tuple5(
      dynamic.string,
      dynamic.string,
      dynamic.optional(dynamic.string),
      dynamic.string,
      dynamic.string,
    )()
  case decoded_record {
    Ok(#(image, ingredients, meal_id, steps, title)) -> {
      let meal_uuid = case meal_id {
        None -> None
        Some(id) ->
          case uuid.from_string(id) {
            Ok(valid_uuid) -> Some(valid_uuid)
            Error(_) -> {
              io.print_error("ERROR: " <> id <> " is not a valid recipe UUID")
              None
            }
          }
      }

      Ok(Recipe(
        image: image,
        ingredients: ingredients |> string.split(separator),
        meal_id: meal_uuid,
        steps: steps,
        title: title,
      ))
    }
    Error(decoding_errors) -> Error(decoding_errors)
  }
}
