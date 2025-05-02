import app/helpers/date as date_helper
import gleam/int
import gleam/list
import hx
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html.{div, fieldset, form, input, label, text}
import tempo
import tempo/datetime
import tempo/time

const default_meals = [
  "Vendredi soir", "Samedi midi", "Samedi soir", "Dimanche midi",
  "Dimanche soir", "Lundi soir", "Mardi soir", "Mercredi midi", "Mercredi soir",
  "Jeudi soir",
]

pub fn index(dates: List(tempo.DateTime)) -> Element(t) {
  form([hx.post("/meals-generate"), hx.target(hx.CssSelector("#menus"))], [
    fieldset(
      [],
      dates
        |> list.map(checkbox),
    ),
    input([attribute.type_("submit"), attribute.value("Générer")]),
    div([attribute.id("menus")], []),
  ])
}

fn checkbox(meal_datetime: tempo.DateTime) -> Element(a) {
  let meal_label = date_helper.meal_moments(meal_datetime)
  let checked = attribute.checked(list.contains(default_meals, meal_label))

  div([], [
    input([
      attribute.type_("checkbox"),
      attribute.name("meal_date"),
      attribute.value(meal_datetime |> datetime.to_unix_milli |> int.to_string),
      checked,
    ]),
    label([], [text(meal_label)]),
  ])
}
