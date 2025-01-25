import gleam/dynamic
import gleam/string

pub type MealRecipe {
  MealRecipe(
    image: String,
    ingredients: List(String),
    meal_id: Int,
    steps: List(String),
    title: String,
  )
}

pub const separator = "@"

pub fn decode(
  fields: dynamic.Dynamic,
) -> Result(MealRecipe, List(dynamic.DecodeError)) {
  let decoded_record =
    fields
    |> dynamic.tuple5(
      dynamic.string,
      dynamic.string,
      dynamic.int,
      dynamic.string,
      dynamic.string,
    )()
  case decoded_record {
    Ok(#(image, ingredients, meal_id, steps, title)) ->
      Ok(MealRecipe(
        image: image,
        ingredients: ingredients |> string.split(separator),
        meal_id: meal_id,
        steps: steps |> string.split(separator),
        title: title,
      ))
    Error(decoding_errors) -> Error(decoding_errors)
  }
}
