import lustre/attribute.{class}
import lustre/element.{type Element, text}
import lustre/element/html.{div, form, h2, input}

pub fn page() -> Element(t) {
  div([], [
    h2([], [text("Importer des recettes")]),
    form(
      [
        class("file-upload"),
        attribute.method("POST"),
        attribute.action("/recipes-upload"),
        attribute.enctype("multipart/form-data"),
      ],
      [
        input([
          attribute.type_("file"),
          attribute.name("uploaded-file"),
          attribute.class(""),
          attribute.placeholder("Sélectionner un export cookmate au format XML"),
          attribute.autofocus(True),
        ]),
        input([attribute.type_("submit"), attribute.value("Importer")]),
      ],
    ),
  ])
}
