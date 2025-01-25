import bseal/time
import bseal/uuid48
import gleam/dynamic
import gleam/list
import tempo
import tempo/datetime

pub type Meal {
  Meal(date: tempo.DateTime, menu_id: Int)
}

pub fn decode(
  fields: dynamic.Dynamic,
) -> Result(Meal, List(dynamic.DecodeError)) {
  let decoded_record =
    fields
    |> dynamic.tuple2(dynamic.int, dynamic.int)()
  case decoded_record {
    Ok(#(date, menu_id)) ->
      Ok(Meal(date |> datetime.from_unix_seconds, menu_id))
    Error(decoding_errors) -> Error(decoding_errors)
  }
}

pub fn for_dates(dates: List(tempo.DateTime)) -> List(Meal) {
  dates
  |> list.map(fn(date: tempo.DateTime) {
    let assert Ok(uuid) = uuid48.start(nodeid: 1, epoch: time.now())
    Meal(date: date, menu_id: uuid |> uuid48.int())
  })
}
