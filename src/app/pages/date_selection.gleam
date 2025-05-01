import app/helpers/date as date_helper
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import hx
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html.{div, fieldset, form, input, label, text}
import tempo
import tempo/date
import tempo/datetime
import tempo/instant

pub fn index() -> Element(t) {
  form([hx.post("/meals-generate"), hx.target(hx.CssSelector("#menus"))], [
    fieldset(
      [],
      dates()
        |> list.map(fn(meal_datetime) {
          let day =
            meal_datetime
            |> date_helper.localized_date
          div([], [
            input([
              attribute.type_("checkbox"),
              attribute.name("meal_date"),
              attribute.value(
                meal_datetime |> datetime.to_unix_milli |> int.to_string,
              ),
            ]),
            label([], [text(day)]),
          ])
        }),
    ),
    input([attribute.type_("submit"), attribute.value("Générer")]),
    div([attribute.id("menus")], []),
  ])
}

fn dates() -> List(tempo.DateTime) {
  let today = date.current_local()
  today
  |> list.repeat(7)
  |> list.index_map(fn(day, index) {
    day
    |> date.add(index)
    |> date.to_string
    |> string.append("T12:00:00+02:00")
    |> datetime.from_string
    |> result.unwrap(
      tempo.now()
      |> instant.as_local_datetime,
    )
  })
}
