import app/models/recipe
import gleam/dynamic/decode as dd
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import tempo
import tempo/datetime
import wisp
import youid/uuid

pub type Meal {
  Meal(
    date: tempo.DateTime,
    menu_id: uuid.Uuid,
    uuid: uuid.Uuid,
    recipe: option.Option(recipe.Recipe),
  )
}

pub fn decode(fields: dd.Dynamic) -> Result(Meal, List(dd.DecodeError)) {
  let decoder = {
    use date <- dd.field(0, dd.int)
    use menu_id <- dd.field(1, dd.string)
    use meal_uuid <- dd.field(2, dd.string)
    dd.success(#(date, menu_id, meal_uuid))
  }
  let decoded_record = dd.run(fields, decoder)
  case decoded_record {
    Ok(#(date, menu_id, meal_uuid)) -> {
      let maybe_uuid = meal_uuid |> uuid.from_string
      let maybe_menu_id = menu_id |> uuid.from_string
      case maybe_uuid, maybe_menu_id {
        Ok(valid_uuid), Ok(valid_menu_id) ->
          Ok(Meal(
            date |> datetime.from_unix_seconds,
            valid_menu_id,
            valid_uuid,
            option.None,
          ))
        Error(_), _ ->
          Error([
            dd.DecodeError(expected: "Valid uuid V4", found: meal_uuid, path: [
              "meal", "meal_uuid",
            ]),
          ])
        Ok(_), Error(_) ->
          Error([
            dd.DecodeError(expected: "Valid uuid V4", found: menu_id, path: [
              "meal", "menu_id",
            ]),
          ])
      }
    }
    Error(decoding_errors) -> Error(decoding_errors)
  }
}

pub fn decode_meal_with_recipe(
  fields: dd.Dynamic,
) -> Result(#(Meal, recipe.Recipe), List(dd.DecodeError)) {
  let decoder = {
    use date <- dd.field(0, dd.int)
    use menu_id <- dd.field(1, dd.string)
    use meal_uuid <- dd.field(2, dd.string)
    use cooking_duration <- dd.field(3, dd.optional(dd.int))
    use image <- dd.field(4, dd.string)
    use ingredients <- dd.field(5, dd.string)
    use preparation_duration <- dd.field(6, dd.optional(dd.int))
    use steps <- dd.field(7, dd.string)
    use title <- dd.field(8, dd.string)
    use total_duration <- dd.field(9, dd.optional(dd.int))
    use recipe_id <- dd.field(10, dd.optional(dd.string))
    dd.success(#(
      date,
      menu_id,
      meal_uuid,
      cooking_duration,
      image,
      ingredients,
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
      date,
      menu_id,
      meal_uuid,
      cooking_duration,
      image,
      ingredients,
      preparation_duration,
      steps,
      title,
      total_duration,
      recipe_id,
    )) -> {
      let maybe_meal_id = meal_uuid |> uuid.from_string
      let maybe_menu_id = menu_id |> uuid.from_string
      let maybe_recipe_id = case recipe_id {
        None -> {
          wisp.log_error("ERROR: invalid recipe UUID")
          Error(Nil)
        }
        Some(id) -> uuid.from_string(id)
      }
      case maybe_meal_id, maybe_menu_id, maybe_recipe_id {
        Ok(valid_meal_id), Ok(valid_menu_id), Ok(valid_recipe_id) ->
          Ok(#(
            Meal(
              date |> datetime.from_unix_seconds,
              valid_menu_id,
              valid_meal_id,
              option.None,
            ),
            recipe.Recipe(
              cooking_duration: cooking_duration,
              image: image,
              ingredients: ingredients |> string.split(recipe.separator),
              meal_id: option.Some(valid_meal_id),
              preparation_duration: preparation_duration,
              steps: steps,
              title: title,
              total_duration: total_duration,
              uuid: valid_recipe_id,
            ),
          ))
        Error(_), _, _ ->
          Error([
            dd.DecodeError(expected: "Valid uuid V4", found: meal_uuid, path: [
              "meal", "meal_uuid",
            ]),
          ])
        Ok(_), Error(_), _ ->
          Error([
            dd.DecodeError(expected: "Valid uuid V4", found: menu_id, path: [
              "meal", "menu_id",
            ]),
          ])
        Ok(_), Ok(_), Error(_) ->
          Error([
            dd.DecodeError(expected: "Valid uuid V4", found: menu_id, path: [
              "meal", "recipe_id",
            ]),
          ])
      }
    }
    Error(decoding_errors) -> Error(decoding_errors)
  }
}

pub fn for_dates(dates: List(tempo.DateTime)) -> List(Meal) {
  let menu_uuid = uuid.v4()

  dates
  |> list.map(fn(date: tempo.DateTime) {
    Meal(date: date, menu_id: menu_uuid, uuid: uuid.v4(), recipe: option.None)
  })
}
