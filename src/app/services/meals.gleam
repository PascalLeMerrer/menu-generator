import gleam/list
import gleam/option
import gleam/result
import tempo
import youid/uuid

import app/adapters/meal as meal_adapter
import app/adapters/recipe as recipe_adapter
import app/models/meal
import app/models/recipe
import app/web.{type Context}

// Generates a list of meals, each one including a single, random recipe
pub fn generate_random_meals(
  ctx: Context,
  dates: List(tempo.DateTime),
) -> Result(List(#(meal.Meal, recipe.Recipe)), String) {
  let meals = meal.for_dates(dates)
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
    recipe_adapter.get_random(ctx.connection, count)
    |> result.partition
  case random_recipes, decoding_errors {
    valid_recipes, [] -> {
      let maybe_cloned_recipes =
        valid_recipes
        |> add_recipes_to_meals(meals)
        |> recipe_adapter.bulk_insert(ctx.connection)
        |> result.partition
      case maybe_cloned_recipes {
        #(cloned_recipes, []) -> Ok(list.zip(meals, cloned_recipes))
        #(_, [_, ..]) -> Error("Erreur lors de la copie des recettes")
      }
    }
    _, _ -> Error("Erreur lors de la lecture des recettes à copier")
  }
}

// replaces the current recipe in a given meal with a random one
// TODO: ensure the new one is not the same as the previous one
pub fn replace_recipe(
  ctx: Context,
  meal_id: uuid.Uuid,
  recipe_id: uuid.Uuid,
) -> Result(List(#(meal.Meal, recipe.Recipe)), String) {
  let meal = meal_adapter.get(meal_id, ctx.connection)

  case meal {
    [Ok(valid_meal)] -> {
      let selected_recipes = add_random_recipes_to_meals(ctx, [valid_meal])
      case selected_recipes {
        Ok(_) -> {
          let _ = recipe_adapter.delete_(recipe_id, ctx.connection)

          selected_recipes
        }
        Error(_) -> selected_recipes
      }
    }
    _ -> Error("Erreur lors de la lecture du repas à modifier")
  }
}

fn add_recipes_to_meals(
  recipes: List(recipe.Recipe),
  meals: List(meal.Meal),
) -> List(recipe.Recipe) {
  list.zip(meals, recipes)
  |> list.map(fn(item) { add_to_meal(item.0, item.1) })
}

fn add_to_meal(meal: meal.Meal, recipe: recipe.Recipe) -> recipe.Recipe {
  recipe.Recipe(
    ..recipe,
    meal_id: option.Some(meal.uuid),
    uuid: option.Some(uuid.v4()),
  )
}
