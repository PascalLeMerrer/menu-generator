import gleam/dynamic
import gleam/list
import tempo
import tempo/datetime
import youid/uuid

pub type Meal {
  Meal(date: tempo.DateTime, menu_id: uuid.Uuid, uuid: uuid.Uuid)
}

pub fn decode(
  fields: dynamic.Dynamic,
) -> Result(Meal, List(dynamic.DecodeError)) {
  let decoded_record =
    fields
    |> dynamic.tuple3(dynamic.int, dynamic.string, dynamic.string)()
  case decoded_record {
    Ok(#(date, menu_id, meal_uuid)) -> {
      let maybe_uuid = meal_uuid |> uuid.from_string
      let maybe_menu_id = menu_id |> uuid.from_string
      case maybe_uuid, maybe_menu_id {
        Ok(valid_uuid), Ok(valid_menu_id) ->
          Ok(Meal(date |> datetime.from_unix_seconds, valid_menu_id, valid_uuid))
        Error(_), _ ->
          Error([
            dynamic.DecodeError(
              expected: "Valid uuid V4",
              found: meal_uuid,
              path: ["meal", "meal_uuid"],
            ),
          ])
        Ok(_), Error(_) ->
          Error([
            dynamic.DecodeError(
              expected: "Valid uuid V4",
              found: menu_id,
              path: ["meal", "menu_id"],
            ),
          ])
      }
    }
    Error(decoding_errors) -> Error(decoding_errors)
  }
}

pub fn for_dates(dates: List(tempo.DateTime)) -> List(Meal) {
  let menu_uuid = uuid.v4()

  dates
  |> list.map(fn(date: tempo.DateTime) {
    Meal(date: date, menu_id: menu_uuid, uuid: uuid.v4())
  })
}
