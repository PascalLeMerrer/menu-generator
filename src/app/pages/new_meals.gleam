import lustre/attribute.{class}
import lustre/element.{type Element, text}
import lustre/element/html.{a, div, form, h1, input}

pub fn index() -> Element(t) {
  div([class("app")], [
    h1([class("app-title")], [text("Génerer des menus")]),
    form([attribute.method("POST"), attribute.action("/meals")], [
      input([attribute.type_("submit"), attribute.value("Générer")]),
      a([attribute.href("/")], [text("Revenir à l'accueil")]),
    ]),
  ])
}
