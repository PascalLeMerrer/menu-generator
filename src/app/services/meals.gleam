import app/adapters/recipes
import gleam/list
import gleam/result
import gleam/string
import tempo
import tempo/date
import tempo/datetime
import tempo/instant
import youid/uuid

import app/adapters/meal as meal_adapter
import app/models/meal
import app/models/recipe
import app/web.{type Context}

// Generates a list of meals, each one including a single, random recipe
// TODO pass the start date and end date as parameters
pub fn generate_random_meals(
  ctx: Context,
) -> Result(List(#(meal.Meal, recipe.Recipe)), String) {
  let meals = meal.for_dates(dates())
  case meal_adapter.insert(ctx.connection, meals) {
    Error(_) -> Error("Erreur d'enregistrement des repas")
    Ok(_) -> {
      add_random_recipes_to_meals(ctx, meals)
    }
  }
}

fn add_random_recipes_to_meals(
  ctx: Context,
  meals: List(meal.Meal),
) -> Result(List(#(meal.Meal, recipe.Recipe)), String) {
  let count = list.length(meals)
  let #(random_recipes, decoding_errors) =
    recipes.get_random(ctx.connection, count)
    |> result.partition
  case random_recipes, decoding_errors {
    valid_recipes, [] -> {
      let cloned_recipes =
        valid_recipes
        |> recipe.add_recipes_to_meals(meals)
        |> recipes.bulk_insert(ctx.connection)
      case cloned_recipes {
        Ok(_) -> Ok(list.zip(meals, valid_recipes))
        Error(_) -> Error("Erreur lors de la copie des recettes")
      }
    }
    _, _ -> Error("Erreur lors de la lecture des recettes à copier")
  }
}

fn dates() -> List(tempo.DateTime) {
  let today = date.current_local()
  today
  |> list.repeat(7)
  |> list.index_map(fn(day, index) {
    day
    |> date.add(index)
    |> date.to_string
    |> string.append("T12:00:00+02:00")
    |> datetime.from_string
    |> result.unwrap(
      tempo.now()
      |> instant.as_local_datetime,
    )
  })
}

// replaces the current recipe in a given meal with a random one
// TODO: ensure the new one is not the same as the previous one
pub fn replace_recipe(
  ctx: Context,
  meal_id: uuid.Uuid,
) -> Result(List(#(meal.Meal, recipe.Recipe)), String) {
  let meal = meal_adapter.get(meal_id, ctx.connection)
  case meal {
    [Ok(valid_meal)] -> add_random_recipes_to_meals(ctx, [valid_meal])
    _ -> Error("Erreur lors de la lecture du repas à modifier")
  }
}
