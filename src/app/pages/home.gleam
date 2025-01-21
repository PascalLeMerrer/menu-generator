import app/models/recipe
import gleam/dynamic
import gleam/list
import lustre/attribute.{class, height, src, width}
import lustre/element.{type Element, text}
import lustre/element/html.{a, div, h1, img, li, ul}

pub fn index(
  recipes: List(Result(recipe.Recipe, List(dynamic.DecodeError))),
) -> Element(t) {
  div([class("app")], [
    h1([class("app-title")], [text("Générateur de menus")]),
    a([attribute.href("import")], [text("Importer des recettes")]),
    view_recipes(recipes),
  ])
}

fn view_recipes(
  decoded_recipes: List(Result(recipe.Recipe, List(dynamic.DecodeError))),
) -> Element(t) {
  ul(
    [],
    decoded_recipes
      |> list.map(fn(recipe) { view_recipe(recipe) }),
  )
}

fn view_recipe(
  maybe_recipe: Result(recipe.Recipe, List(dynamic.DecodeError)),
) -> Element(t) {
  li([], case maybe_recipe {
    Error(_) -> {
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
