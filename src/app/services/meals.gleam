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
) -> Result(List(#(meal.Meal, List(recipe.Recipe))), String) {
  let meals = meal.for_dates(dates)
  case meal_adapter.insert(meals, ctx.connection) {
    Error(_) -> Error("Erreur d'enregistrement des repas")
    Ok(_) -> {
      add_random_recipe_to_meals(ctx, meals, excluding: [])
    }
  }
}

fn add_random_recipe_to_meals(
  ctx: Context,
  meals: List(meal.Meal),
  excluding recipes_to_exlude: List(uuid.Uuid),
) -> Result(List(#(meal.Meal, List(recipe.Recipe))), String) {
  let count = list.length(meals)
  let #(random_recipes, decoding_errors) =
    recipe_adapter.get_random(count, recipes_to_exlude, ctx.connection)
    |> result.partition

  case random_recipes, decoding_errors {
    valid_recipes, [] -> {
      let maybe_cloned_recipes =
        valid_recipes
        |> add_recipes_to_meals(meals)
        |> recipe_adapter.bulk_insert(ctx.connection)
        |> result.partition

      case maybe_cloned_recipes {
        #(cloned_recipes, []) -> {
          let recipe_lists =
            cloned_recipes
            |> list.reverse
            |> list.map(fn(r) { [r] })

          Ok(list.zip(meals, recipe_lists))
        }
        #(_, [_, ..]) -> Error("Erreur lors de la copie des recettes")
      }
    }
    _, _ -> Error("Erreur lors de la lecture des recettes à copier")
  }
}

// adds a given recipe to a meal
pub fn suggest(ctx: Context, a_meal: meal.Meal, a_recipe: recipe.Recipe) {
  let updated_recipe = add_to_meal(a_meal, a_recipe)
  let inserted_recipe =
    recipe_adapter.bulk_insert([updated_recipe], ctx.connection)
    |> result.all
  let meal_recipes =
    recipe_adapter.find_by_meal_id(a_meal.uuid, ctx.connection)
    |> result.all
  case meal_recipes, inserted_recipe {
    Ok(valid_recipes), Ok(_) -> {
      Ok(valid_recipes)
    }
    Error(_), _ -> Error("Erreur de lecture des recettes associées au repas")
    _, Error(_) ->
      Error("Erreur de l'écriture de la nouvelle recettes associée au repas")
  }
}

// replaces the given recipe in a given meal with a random one
pub fn replace_recipe_with_random_one(
  ctx: Context,
  meal_id: uuid.Uuid,
  recipe_id: uuid.Uuid,
) -> Result(#(meal.Meal, List(recipe.Recipe)), String) {
  let meal = meal_adapter.get(meal_id, ctx.connection)

  case meal {
    Ok(valid_meal) -> {
      let meals_with_selected_recipes =
        add_random_recipe_to_meals(ctx, [valid_meal], excluding: [recipe_id])
      case meals_with_selected_recipes {
        Ok(_) -> {
          let _ = recipe_adapter.delete(recipe_id, ctx.connection)

          let recipes =
            recipe_adapter.find_by_meal_id(meal_id, ctx.connection)
            |> result.all
          case recipes {
            Ok(meal_recipes) -> Ok(#(valid_meal, meal_recipes))
            Error(_) ->
              Error(
                "Erreur lors de la recherche des recettes associées au repas "
                <> uuid.to_string(meal_id),
              )
          }
        }
        Error(error_message) -> Error(error_message)
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

pub fn add_to_meal(meal: meal.Meal, recipe: recipe.Recipe) -> recipe.Recipe {
  recipe.Recipe(..recipe, meal_id: option.Some(meal.uuid), uuid: uuid.v4())
}
