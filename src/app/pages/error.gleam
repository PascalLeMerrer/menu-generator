import lustre/attribute.{class}
import lustre/element.{type Element, text}
import lustre/element/html.{div, h1}

pub fn index(error: String) -> Element(t) {
  div([class("app")], [
    h1([class("app-title")], [text("Menus proposés")]),
    text(error),
  ])
}
