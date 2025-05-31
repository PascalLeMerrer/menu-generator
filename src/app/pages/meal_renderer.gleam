import app/helpers/date as date_helper
import app/models/meal
import app/models/recipe
import lustre/element.{type Element, text}
import tempo
import tempo/date
import tempo/datetime

import gleam/json
import gleam/option
import hx
import lustre/attribute.{class, height, src, width}
import lustre/element/html.{div, img, span}
import youid/uuid

pub fn view(meal_and_recipe: #(meal.Meal, recipe.Recipe)) -> Element(t) {
  let #(generated_meal, recipe) = meal_and_recipe
  let image_url = case recipe.image {
    "" -> "/static/placeholder-100x100.png"
    _ -> recipe.image
  }
  let meal_id = generated_meal.uuid |> uuid.to_string()
  let recipe_id = recipe.uuid |> uuid.to_string
  let date_label = generated_meal.date |> date_helper.meal_moments
  div([class("generated_menu")], [
    span([class("date")], [
      text(date_label),
      text(" "),
      text(
        generated_meal.date
        |> datetime.get_date
        |> date.format(tempo.CustomDate("DD/MM/YYYY")),
      ),
    ]),
    img([class("image"), src(image_url), height(100), width(100)]),
    span([class("title")], [text(recipe.title)]),
    div([class("actions")], [
      span(
        [
          class("action"),
          hx.post("recipes-replace"),
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
        [text("Suggérer")],
      ),
      span(
        [
          class("action"),
          hx.delete("meals/" <> meal_id),
          // the closest div, i.e. the parent
          hx.target(hx.CssSelector("closest .generated_menu")),
          hx.swap(hx.OuterHTML, option.None),
        ],
        [text("Supprimer")],
      ),
      span(
        [
          class("action"),
          hx.post("recipes-ingredients"),
          hx.vals(
            json.object([#("recipe_id", recipe_id |> json.string)]),
            False,
          ),
          hx.target(hx.CssSelector("next .ingredients")),
        ],
        [text("Ingrédients")],
      ),
      span(
        [
          class("action"),
          hx.post("recipes-steps"),
          hx.vals(
            json.object([#("recipe_id", recipe_id |> json.string)]),
            False,
          ),
          hx.target(hx.CssSelector("next .steps")),
        ],
        [text("Étapes")],
      ),
    ]),
    div([class("ingredients")], []),
    div([class("steps")], []),
  ])
}
