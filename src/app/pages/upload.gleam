import lustre/attribute.{class}
import lustre/element.{type Element, text}
import lustre/element/html.{div, form, h1, h2, input}

pub fn index() -> Element(t) {
  div([class("app")], [
    h1([class("app-title")], [text("Générateur de menus")]),
    h2([], [text("Importer des recettes")]),
    upload_recipes(),
  ])
}

fn upload_recipes() -> Element(t) {
  form(
    [
      class("file-upload"),
      attribute.method("POST"),
      attribute.action("/recipes/upload"),
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
  )
}
