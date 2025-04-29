import app/models/meal
import app/models/recipe
import gleam/json
import gleam/list
import gleam/option
import hx
import lustre/attribute.{class, height, src, width}
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
  let recipe_id =
    recipe.uuid |> echo |> option.map(uuid.to_string) |> option.unwrap("")

  div([class("generated_menu")], [
    span([class("date")], [text(date)]),
    img([class("image"), src(image_url), height(100), width(100)]),
    span([class("title")], [text(recipe.title)]),
    div([class("actions")], [
      span(
        [
          class(""),
          hx.post("replace-recipe"),
          hx.vals(
            json.object([
              #("meal_id", meal_id |> json.string),
              #("recipe_id", recipe_id |> json.string),
            ]),
            False,
          ),
          // the closest div, i.e. the parent
          hx.target(hx.CssSelector("closest .generated_menu")),
          hx.swap(hx.OuterHTML, option.None),
        ],
        [text("Remplacer")],
      ),
      span(
        [
          class(""),
          hx.post("recipe-ingredients"),
          hx.vals(
            json.object([#("recipe_id", recipe_id |> json.string)]),
            False,
          ),
          hx.target(hx.CssSelector("next .ingredients")),
          // hx.swap(hx.OuterHTML, option.None),
        ],
        [text("Ingrédients")],
      ),
    ]),
    div([class("ingredients")], []),
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
