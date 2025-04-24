import app/models/meal
import app/models/recipe
import gleam/list
import lustre/attribute.{class, height, src, width}
import lustre/element.{type Element, text}
import lustre/element/html.{div, h2, img, li, span, ul}
import tempo
import tempo/date
import tempo/datetime

pub fn index(meals: List(#(meal.Meal, recipe.Recipe))) -> Element(t) {
  div([], [
    h2([], [text("Menus proposés")]),
    ul(
      [],
      meals
        |> list.map(fn(meal) { view_meal(meal) }),
    ),
  ])
}

fn view_meal(meal_and_recipe: #(meal.Meal, recipe.Recipe)) -> Element(t) {
  let #(meal, recipe) = meal_and_recipe
  let date = meal.date |> localised_date
  let image_url = case recipe.image {
    "" -> "/static/placeholder-100x100.png"
    _ -> recipe.image
  }
  li([class("generated_menu")], [
    span([], [text(date)]),
    img([src(image_url), height(100), width(100)]),
    span([], [text(recipe.title)]),
  ])
}

pub fn localised_date(date: tempo.DateTime) -> String {
  let day_of_week =
    date
    |> datetime.get_date
    |> date.to_day_of_week
  case day_of_week {
    date.Mon -> "Lundi"
    date.Tue -> "Mardi"
    date.Wed -> "Mercredi"
    date.Thu -> "Jeudi"
    date.Fri -> "Vendredi"
    date.Sat -> "Samedi"
    date.Sun -> "Dimanche"
  }
}
