import gleam/list
import gleam/result
import gleam/string
import tempo
import tempo/date
import tempo/datetime
import tempo/instant

// build a list of date and hours for the lunches and dinners
// of a week starting at the given date
pub fn for_potential_meals(start: tempo.Date) -> List(tempo.DateTime) {
  let days =
    start
    |> list.repeat(7)
    |> list.index_map(fn(day, index) {
      day
      |> date.add(index)
      |> date.to_string
    })

  let lunch_datetimes = days |> to_datetime("T12:00:00+02:00")
  let dinner_datetimes = days |> to_datetime("T19:00:00+02:00")

  lunch_datetimes
  |> list.append(dinner_datetimes)
  |> list.sort(datetime.compare)
}

fn to_datetime(days: List(String), hour: String) -> List(tempo.DateTime) {
  days
  |> list.map(fn(day_) {
    day_
    |> string.append(hour)
    |> datetime.from_string
    |> result.unwrap(
      tempo.now()
      |> instant.as_local_datetime,
    )
  })
}
