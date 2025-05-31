import app/helpers/decoding
import app/models/meal
import app/models/recipe
import app/pages/meal_renderer
import gleam/dynamic/decode
import gleam/list
import lustre/element.{type Element, text}
import lustre/element/html.{div, h2}
import wisp

pub fn index(
  meals: List(Result(#(meal.Meal, recipe.Recipe), List(decode.DecodeError))),
) -> Element(t) {
  let rendered_meals =   
    meals
      |> list.reverse
      |> list.map(fn(meal) { view_maybe_meal(meal) })
      
  div(
    [],
    [
    h2([], [text("Mes repas")]),
      ..rendered_meals
    ]
  )
}

fn view_maybe_meal(
  maybe_meal: Result(#(meal.Meal, recipe.Recipe), List(decode.DecodeError)),
) -> Element(t) {
  case maybe_meal {
    Error(errors) -> {
      let _ = {
        wisp.log_error(errors |> decoding.decoding_errors_to_string)
      }
      text("Erreur de décodage du repas")
    }
    Ok(#(valid_meal, valid_recipe)) ->
      meal_renderer.view(#(valid_meal, valid_recipe))
  }
}
