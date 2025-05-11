import app/helpers/date as date_helper
import app/helpers/decoding
import app/models/meal
import gleam/dynamic/decode
import gleam/list
import lustre/attribute.{class}
import lustre/element.{type Element, text}
import lustre/element/html.{li, ul}
import tempo
import tempo/date
import tempo/datetime
import wisp

pub fn index(
  meals: List(Result(meal.Meal, List(decode.DecodeError))),
) -> Element(t) {
  ul(
    [class("unstyled")],
    meals
      |> list.reverse
      |> list.map(fn(meal) { view_meal(meal) }),
  )
}

fn view_meal(
  maybe_meal: Result(meal.Meal, List(decode.DecodeError)),
) -> Element(t) {
  li([], case maybe_meal {
    Error(errors) -> {
      let _ = {
        wisp.log_error(errors |> decoding.decoding_errors_to_string)
      }
      [text("Erreur de décodage du repas")]
    }
    Ok(valid_meal) -> [
      text(valid_meal.date |> date_helper.meal_moments),
      text(" "),
      text(
        valid_meal.date
        |> datetime.get_date
        |> date.format(tempo.CustomDate("DD/MM/YYYY")),
      ),
    ]
  })
}
