import app/models/meal
import gleam/dynamic
import gleam/dynamic/decode as dd

import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import wisp
import youid/uuid

// uuid is not None if and only if the recipe instance is attached to a meal
pub type Recipe {
  Recipe(
    image: String,
    ingredients: List(String),
    meal_id: Option(uuid.Uuid),
    steps: String,
    title: String,
    uuid: Option(uuid.Uuid),
  )
}

pub const separator = "@"

pub fn decode(fields: dynamic.Dynamic) -> Result(Recipe, List(dd.DecodeError)) {
  let decoder = {
    use image <- dd.field(0, dd.string)
    use ingredients <- dd.field(1, dd.string)
    use meal_id <- dd.field(2, dd.optional(dd.string))
    use steps <- dd.field(3, dd.string)
    use title <- dd.field(4, dd.string)
    use recipe_id <- dd.field(5, dd.optional(dd.string))
    dd.success(#(image, ingredients, meal_id, steps, title, recipe_id))
  }
  let decoded_record = dd.run(fields, decoder)
  case decoded_record {
    Ok(#(image, ingredients, meal_id, steps, title, recipe_id)) -> {
      let meal_uuid = case meal_id {
        None -> None
        Some(id) ->
          case uuid.from_string(id) {
            Ok(valid_uuid) -> Some(valid_uuid)
            Error(_) -> {
              wisp.log_error("ERROR: " <> id <> " is not a valid meal UUID")
              None
            }
          }
      }

      let recipe_uuid = case recipe_id {
        None -> None
        Some(id) ->
          case uuid.from_string(id) {
            Ok(valid_uuid) -> Some(valid_uuid)
            Error(_) -> {
              wisp.log_error("ERROR: " <> id <> " is not a valid recipe UUID")
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
        uuid: recipe_uuid,
      ))
    }
    Error(decoding_errors) -> Error(decoding_errors)
  }
}

pub fn add_recipes_to_meals(
  recipes: List(Recipe),
  meals: List(meal.Meal),
) -> List(Recipe) {
  list.zip(meals, recipes)
  |> list.map(fn(item) { add_to_meal(item.0, item.1) })
}

pub fn add_to_meal(meal: meal.Meal, recipe: Recipe) -> Recipe {
  Recipe(..recipe, meal_id: Some(meal.uuid), uuid: Some(uuid.v4()))
}
