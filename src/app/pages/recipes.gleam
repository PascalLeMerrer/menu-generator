import app/helpers/decoding
import app/models/recipe
import gleam/dynamic/decode
import gleam/list
import hx
import lustre/attribute.{class, height, src, width}
import lustre/element.{type Element, text}
import lustre/element/html.{div, img, li, span, ul}
import wisp

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
    Ok(valid_recipe) -> [
      {
        let image_url = case valid_recipe.image {
          "" -> "/static/placeholder-100x100.png"
          _ -> valid_recipe.image
        }

        img([src(image_url), height(100), width(100)])
      },
      text(valid_recipe.title),
    ]
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
