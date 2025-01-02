import app/models/item.{type Item}
import lustre/attribute.{class}
import lustre/element.{type Element, text}
import lustre/element/html.{div, form, h1, input}

pub fn root(items: List(Item)) -> Element(t) {
  div([class("app")], [
    h1([class("app-title")], [text("Todo App")]),
    upload_recipes(),
  ])
}

fn upload_recipes() -> Element(t) {
  form(
    [
      class("file-upload"),
      attribute.method("POST"),
      attribute.action("/upload"),
      attribute.enctype("multipart/form-data"),
    ],
    [
      input([
        attribute.type_("file"),
        attribute.name("uploaded-file"),
        attribute.class(""),
        attribute.placeholder("Uploader une liste de recettes"),
        attribute.autofocus(True),
      ]),
      input([attribute.type_("submit"), attribute.value("Téléverser")]),
    ],
  )
}
