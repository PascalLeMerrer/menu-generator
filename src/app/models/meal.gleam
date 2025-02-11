import gleam/dynamic
import gleam/list
import tempo
import tempo/datetime
import youid/uuid

pub type Meal {
  Meal(date: tempo.DateTime, menu_id: String)
}

pub fn decode(
  fields: dynamic.Dynamic,
) -> Result(Meal, List(dynamic.DecodeError)) {
  let decoded_record =
    fields
    |> dynamic.tuple2(dynamic.int, dynamic.string)()
  case decoded_record {
    Ok(#(date, menu_id)) ->
      Ok(Meal(date |> datetime.from_unix_seconds, menu_id))
    Error(decoding_errors) -> Error(decoding_errors)
  }
}

pub fn for_dates(dates: List(tempo.DateTime)) -> List(Meal) {
  let uuid = uuid.v4_string()

  dates
  |> list.map(fn(date: tempo.DateTime) { Meal(date: date, menu_id: uuid) })
}
