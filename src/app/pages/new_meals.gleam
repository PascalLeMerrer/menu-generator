import hx
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html.{div, form, input, text}

pub fn index() -> Element(t) {
  form([hx.post("/meals"), hx.target(hx.CssSelector("#menus"))], [
    div([], [text("TODO sélection dates")]),
    input([attribute.type_("submit"), attribute.value("Générer")]),
    div([attribute.id("menus")], []),
  ])
}
