import app/models/meal
import gleam/list
import lustre/attribute.{class}
import lustre/element.{type Element, text}
import lustre/element/html.{div, h1, li, ul}
import youid/uuid

pub fn index(meals: List(meal.Meal)) -> Element(t) {
  div([class("app")], [
    h1([class("app-title")], [text("Menus proposés")]),
    ul(
      [],
      meals
        |> list.map(fn(meal) { view_meal(meal) }),
    ),
  ])
}

fn view_meal(meal: meal.Meal) -> Element(t) {
  li([], [text(meal.uuid |> uuid.to_string())])
}
