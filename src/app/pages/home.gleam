import lustre/attribute.{class}
import lustre/element.{type Element, text}
import lustre/element/html.{a, div, h1}

pub fn root() -> Element(t) {
  div([class("app")], [
    h1([class("app-title")], [text("Générateur de menus")]),
    a([attribute.href("import")], [text("Importer des recettes")]),
  ])
}
