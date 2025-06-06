import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn layout(elements: List(Element(t))) -> Element(t) {
  html.html([], [
    html.head([], [
      html.title([], "Générateur de menus"),
      html.meta([
        attribute.name("viewport"),
        attribute.attribute("content", "width=device-width, initial-scale=1"),
      ]),
      html.link([attribute.rel("stylesheet"), attribute.href("/static/app.css")]),
      html.script([attribute.src("/static/htmx.min.js")], ""),
      html.script([attribute.src("/static/htmx-remove.js")], ""),
    ]),
    html.body([], elements),
  ])
}
