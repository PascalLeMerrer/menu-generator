import app/helpers/decoding
import app/models/recipe
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/string
import hx
import lustre/attribute.{class, height, src, width}
import lustre/element.{type Element, text}
import lustre/element/html.{div, img, li, ol, span, ul}
import wisp
import youid/uuid

pub fn index(
  recipes: List(Result(recipe.Recipe, List(decode.DecodeError))),
) -> Element(t) {
  ul(
    [class("unstyled")],
    recipes
      |> list.map(fn(recipe) { view_recipe(recipe) }),
  )
}

fn view_recipe(
  maybe_recipe: Result(recipe.Recipe, List(decode.DecodeError)),
) -> Element(t) {
  li([], case maybe_recipe {
    Error(errors) -> {
      let _ = {
        wisp.log_error(errors |> decoding.decoding_errors_to_string)
      }
      [text("Erreur de décodage de la recette ")]
    }
    Ok(valid_recipe) -> {
      let image_url = case valid_recipe.image {
        "" -> "/static/placeholder-100x100.png"
        _ -> valid_recipe.image
      }
      let recipe_id = valid_recipe.uuid |> uuid.to_string

      [
        div([class("recipe")], [
          img([class("image"), src(image_url), height(100), width(100)]),
          span([class("title")], [text(valid_recipe.title)]),
          div([class("actions")], [
            span(
              [
                class("action"),
                hx.post("recipe-ingredients"),
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
                hx.post("recipe-steps"),
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
        ]),
      ]
    }
  })
}

pub fn view_ingredients(recipe: recipe.Recipe) -> Element(t) {
  div([hx.ext(["remove"]), class("horizontal-container")], [
    ul(
      [class("ingredient-list")],
      recipe.ingredients
        |> list.map(fn(ingredient) { li([], [text(ingredient)]) }),
    ),
    span([attribute.data("remove", "true"), class("close-button")], [
      text("masquer"),
    ]),
  ])
}

pub fn view_steps(recipe: recipe.Recipe) -> Element(t) {
  div([hx.ext(["remove"]), class("horizontal-container")], [
    ol(
      [class("step-list")],
      recipe.steps
        |> string.split("\n")
        |> list.map(fn(step) { li([], [text(step)]) }),
    ),
    span([attribute.data("remove", "true"), class("close-button")], [
      text("masquer"),
    ]),
  ])
}
