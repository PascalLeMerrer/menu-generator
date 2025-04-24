import app/models/meal
import app/models/recipe
import gleam/list
import lustre/element.{type Element, text}
import lustre/element/html.{div, h1, li, ul}
import tempo
import tempo/datetime

pub fn index(meals: List(#(meal.Meal, recipe.Recipe))) -> Element(t) {
  div([], [
    h1([], [text("Menus proposés")]),
    ul(
      [],
      meals
        |> list.map(fn(meal) { view_meal(meal) }),
    ),
  ])
}

fn view_meal(meal_and_recipe: #(meal.Meal, recipe.Recipe)) -> Element(t) {
  let #(meal, recipe) = meal_and_recipe
  let date = meal.date |> datetime.format(tempo.Custom("ddd"))
  li([], [text(date), text(" "), text(recipe.title)])
}
