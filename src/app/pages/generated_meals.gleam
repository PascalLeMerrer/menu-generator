import app/models/meal
import app/models/recipe
import app/pages/meal_renderer
import gleam/list
import lustre/element.{type Element, text}
import lustre/element/html.{div, h2}

pub fn page(meals: List(#(meal.Meal, List(recipe.Recipe)))) -> Element(t) {
  div([], [
    h2([], [text("Menus proposés")]),
    ..{
      meals
      |> list.map(fn(meal_and_recipe) {
        let #(valid_meal, valid_recipe) = meal_and_recipe
        meal_renderer.view(valid_meal, valid_recipe)
      })
    }
  ])
}
