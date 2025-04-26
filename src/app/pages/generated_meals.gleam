import app/models/meal
import app/models/recipe
import gleam/json
import gleam/list
import gleam/option
import hx
import lustre/attribute.{class, height, id, src, width}
import lustre/element.{type Element, text}
import lustre/element/html.{div, h2, img, span}
import tempo
import tempo/date
import tempo/datetime
import youid/uuid

pub fn index(meals: List(#(meal.Meal, recipe.Recipe))) -> Element(t) {
  div([], [
    h2([], [text("Menus proposés")]),
    ..{
      meals
      |> list.map(fn(meal) { view_meal(meal) })
    }
  ])
}

pub fn view_meal(meal_and_recipe: #(meal.Meal, recipe.Recipe)) -> Element(t) {
  let #(generated_meal, recipe) = meal_and_recipe
  let date = generated_meal.date |> localised_date
  let image_url = case recipe.image {
    "" -> "/static/placeholder-100x100.png"
    _ -> recipe.image
  }
  let meal_id = generated_meal.uuid |> uuid.to_string()
  div([class("generated_menu")], [
    span([], [text(date)]),
    img([src(image_url), height(100), width(100)]),
    span([], [text(recipe.title)]),
    span(
      [
        hx.post("replace-recipe"),
        hx.vals(json.object([#("meal_id", meal_id |> json.string)]), False),
        // the closest div, i.e. the parent
        hx.target(hx.CssSelector("closest div")),
        hx.swap(hx.OuterHTML, option.None),
      ],
      [text("Remplacer")],
    ),
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
