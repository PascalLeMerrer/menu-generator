import app/helpers/decoding
import app/models/meal
import app/models/recipe
import app/pages/meal_renderer
import gleam/dynamic/decode
import gleam/list
import gleam/result
import lustre/element.{type Element, text}
import lustre/element/html.{div, h2}
import wisp

pub fn page(
  meals: List(Result(meal.Meal, List(decode.DecodeError))),
  recipes: List(Result(recipe.Recipe, List(decode.DecodeError))),
) -> Element(t) {
  let rendered_meals =
    meals
    |> list.reverse
    |> list.map(fn(meal) { view_maybe_meal(meal, recipes) })

  div([], [h2([], [text("Mes repas")]), ..rendered_meals])
}

fn view_maybe_meal(
  maybe_meal: Result(meal.Meal, List(decode.DecodeError)),
  maybe_recipes: List(Result(recipe.Recipe, List(decode.DecodeError))),
) -> Element(t) {
  let recipes = maybe_recipes |> result.all
  case maybe_meal, recipes {
    Error(errors), _ -> {
      let _ = {
        wisp.log_error(errors |> decoding.decoding_errors_to_string)
      }
      text("Erreur de décodage du repas")
    }
    _, Error(errors) -> {
      let _ = {
        wisp.log_error(errors |> decoding.decoding_errors_to_string)
      }
      text("Erreur de décodage des recettes")
    }
    Ok(valid_meal), Ok(valid_recipes) ->
      meal_renderer.view(valid_meal, valid_recipes)
  }
}
