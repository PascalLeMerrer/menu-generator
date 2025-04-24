import hx
import lustre/attribute.{class, id}
import lustre/element.{type Element, text}
import lustre/element/html.{a, div, h1}

pub fn index() -> Element(t) {
  div([class("app")], [
    h1([class("app-title")], [text("Générateur de menus")]),
    div([hx.get("new-meals"), hx.target(hx.CssSelector("#main"))], [
      text("Génerer des menus"),
    ]),
    div([hx.get("recipes"), hx.target(hx.CssSelector("#main"))], [
      text("Mes recettes"),
    ]),
    div([hx.get("import"), hx.target(hx.CssSelector("#main"))], [
      text("Importer des recettes"),
    ]),
    div([id("main")], []),
  ])
}
