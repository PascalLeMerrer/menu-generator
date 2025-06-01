import app/helpers/date as date_helper
import gleam/int
import gleam/list
import gleam/option
import hx
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html.{div, fieldset, form, h2, input, label, text}
import tempo
import tempo/datetime

const default_meals = [
  "Vendredi soir", "Samedi midi", "Samedi soir", "Dimanche midi",
  "Dimanche soir", "Lundi soir", "Mardi soir", "Mercredi midi", "Mercredi soir",
  "Jeudi soir",
]

pub fn page(dates: List(tempo.DateTime)) -> Element(t) {
  div([], [
    h2([], [text("Sélectionner les repas à prévoir")]),
    form(
      [
        hx.post("/meals-generate"),
        hx.target(hx.CssSelector("closest div")),
        hx.swap(hx.OuterHTML, option.None),
      ],
      [
        fieldset(
          [],
          dates
            |> list.map(checkbox),
        ),
        input([attribute.type_("submit"), attribute.value("Générer")]),
      ],
    ),
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
