import app/models/recipe
import gleam/int
import gleam/list
import lustre/attribute.{class}
import lustre/element.{type Element, text}
import lustre/element/html.{a, div, h1, p}

pub fn page(recipes: List(recipe.Recipe)) -> Element(t) {
  let imported_recipe_count = list.length(recipes) |> int.to_string
  div([class("app")], [
    h1([class("app-title")], [text("Importation des recettes réussie")]),
    p([], [text(imported_recipe_count <> " recettes importées")]),
    a([attribute.href("/")], [text("Revenir à l'accueil")]),
  ])
}
