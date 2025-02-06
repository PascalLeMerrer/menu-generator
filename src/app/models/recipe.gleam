import gleam/dynamic
import gleam/string

pub type Recipe {
  Recipe(image: String, ingredients: List(String), steps: String, title: String)
}

pub const separator = "@"

pub fn decode(
  fields: dynamic.Dynamic,
) -> Result(Recipe, List(dynamic.DecodeError)) {
  let decoded_record =
    fields
    |> dynamic.tuple4(
      dynamic.string,
      dynamic.string,
      dynamic.string,
      dynamic.string,
    )()
  case decoded_record {
    Ok(#(image, ingredients, steps, title)) ->
      Ok(Recipe(
        image: image,
        ingredients: ingredients |> string.split(separator),
        steps: steps,
        title: title,
      ))
    Error(decoding_errors) -> Error(decoding_errors)
  }
}
