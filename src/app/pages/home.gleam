import hx
import lustre/attribute.{class, id}
import lustre/element.{type Element, text}
import lustre/element/html.{div, h1, nav}

pub fn page() -> Element(t) {
  div([class("app")], [
    h1([class("app-title")], [text("Générateur de menus")]),
    nav([], [
      div([hx.get("date-select"), hx.target(hx.CssSelector("#main"))], [
        text("Génerer des menus"),
      ]),
      div([hx.get("meals-list"), hx.target(hx.CssSelector("#main"))], [
        text("Mes repas"),
      ]),
      div([hx.get("recipes-list"), hx.target(hx.CssSelector("#main"))], [
        text("Mes recettes"),
      ]),
      div([hx.get("recipes-import"), hx.target(hx.CssSelector("#main"))], [
        text("Importer des recettes"),
      ]),
    ]),
    div([id("main")], []),
  ])
}
