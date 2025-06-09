import app/helpers/date as date_helper
import app/models/meal
import app/models/recipe
import gleam/list
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

pub fn view(
  meal_to_display: meal.Meal,
  meal_recipes: List(recipe.Recipe),
) -> Element(t) {
  let meal_id = meal_to_display.uuid |> uuid.to_string()
  let date_label = meal_to_display.date |> date_helper.meal_moments

  div(
    [class("meal")],
    [
      span([class("date")], [
        text(date_label),
        text(" "),
        text(
          meal_to_display.date
          |> datetime.get_date
          |> date.format(tempo.CustomDate("DD/MM/YYYY")),
        ),
      ]),
      span(
        [
          class("action"),
          hx.post("recipes-select"),
          hx.vals(json.object([#("meal_id", meal_id |> json.string)]), False),
          hx.target(hx.CssSelector("#main")),
        ],
        [text("Ajouter une recette")],
      ),
      span(
        [
          class("action"),
          hx.delete("meals/" <> meal_id),
          // the closest div, i.e. the parent
          hx.target(hx.CssSelector("closest .meal")),
          hx.swap(hx.OuterHTML, option.None),
        ],
        [text("Supprimer le repas")],
      ),
    ]
      |> list.append(list.map(meal_recipes, fn(r) { view_recipe(meal_id, r) })),
  )
}

fn view_recipe(meal_id: String, recipe: recipe.Recipe) {
  let image_url = case recipe.image {
    "" -> "/static/placeholder-100x100.png"
    _ -> recipe.image
  }
  let recipe_meal_id =
    recipe.meal_id
    |> option.map(uuid.to_string)
    |> option.unwrap("")

  case recipe_meal_id == meal_id {
    True -> {
      let recipe_id = recipe.uuid |> uuid.to_string
      div([class("meal-recipe")], [
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
              hx.target(hx.CssSelector("closest .meal")),
              hx.swap(hx.OuterHTML, option.None),
            ],
            [text("Suggérer")],
          ),
          span(
            [
              class("action"),
              hx.delete("recipes/" <> recipe_id),
              hx.target(hx.CssSelector("closest .meal-recipe")),
              hx.swap(hx.OuterHTML, option.None),
            ],
            [text("Supprimer")],
          ),
          span(
            [
              class("action"),
              hx.post("recipes-metadata"),
              hx.vals(
                json.object([#("recipe_id", recipe_id |> json.string)]),
                False,
              ),
              hx.target(hx.CssSelector("next .metadata")),
            ],
            [text("Détails")],
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
        div([class("metadata")], []),
        div([class("ingredients")], []),
        div([class("steps")], []),
      ])
    }
    False -> element.none()
  }
}
