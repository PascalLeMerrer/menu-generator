import lustre/attribute.{class}
import lustre/element.{type Element, text}
import lustre/element/html.{a, div, h1}

pub fn index() -> Element(t) {
  div([class("app")], [
    h1([class("app-title")], [text("Générateur de menus")]),
    div([], [a([attribute.href("new-meals")], [text("Génerer des menus")])]),
    div([], [a([attribute.href("recipes")], [text("Mes recettes")])]),
    div([], [a([attribute.href("import")], [text("Importer des recettes")])]),
  ])
}
