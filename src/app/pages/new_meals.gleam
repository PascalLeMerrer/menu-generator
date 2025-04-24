import lustre/attribute
import lustre/element.{type Element, text}
import lustre/element/html.{a, form, input}

pub fn index() -> Element(t) {
  form([attribute.method("POST"), attribute.action("/meals")], [
    input([attribute.type_("submit"), attribute.value("Générer")]),
    a([attribute.href("/")], [text("Revenir à l'accueil")]),
  ])
}
