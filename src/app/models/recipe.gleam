import gleam/dynamic
import gleam/dynamic/decode as dd

import gleam/option.{type Option, None, Some}
import gleam/string
import wisp
import youid/uuid

pub type Recipe {
  Recipe(
    cooking_duration: Option(Int),
    image: String,
    ingredients: List(String),
    meal_id: Option(uuid.Uuid),
    preparation_duration: Option(Int),
    steps: String,
    title: String,
    total_duration: Option(Int),
    uuid: uuid.Uuid,
  )
}

pub const separator = "@"

pub fn decode(fields: dynamic.Dynamic) -> Result(Recipe, List(dd.DecodeError)) {
  let decoder = {
    use cooking_duration <- dd.field(0, dd.optional(dd.int))
    use image <- dd.field(1, dd.string)
    use ingredients <- dd.field(2, dd.string)
    use meal_id <- dd.field(3, dd.optional(dd.string))
    use preparation_duration <- dd.field(4, dd.optional(dd.int))
    use steps <- dd.field(5, dd.string)
    use title <- dd.field(6, dd.string)
    use total_duration <- dd.field(7, dd.optional(dd.int))
    use recipe_id <- dd.field(8, dd.optional(dd.string))
    dd.success(#(
      cooking_duration,
      image,
      ingredients,
      meal_id,
      preparation_duration,
      steps,
      title,
      total_duration,
      recipe_id,
    ))
  }
  let decoded_record = dd.run(fields, decoder)
  case decoded_record {
    Ok(#(
      cooking_duration,
      image,
      ingredients,
      meal_id,
      preparation_duration,
      steps,
      title,
      total_duration,
      recipe_id,
    )) -> {
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

      case recipe_id {
        None -> {
          wisp.log_error("Identifiant de recette manquant")
          Error([
            dd.DecodeError(
              expected: "Identifiant de recette",
              found: "None",
              path: [],
            ),
          ])
        }
        Some(id) ->
          case uuid.from_string(id) {
            Ok(valid_uuid) ->
              Ok(Recipe(
                cooking_duration: cooking_duration,
                image: image,
                ingredients: ingredients |> string.split(separator),
                meal_id: meal_uuid,
                preparation_duration: preparation_duration,
                steps: steps,
                title: title,
                total_duration: total_duration,
                uuid: valid_uuid,
              ))

            Error(_) -> {
              wisp.log_error("ERROR: " <> id <> " is not a valid recipe UUID")
              Error([
                dd.DecodeError(
                  expected: "Identifiant de recette",
                  found: id,
                  path: [],
                ),
              ])
            }
          }
      }
    }
    Error(decoding_errors) -> Error(decoding_errors)
  }
}
