import app/models/date as date_model
import gleeunit/should
import tempo/date
import tempo/datetime

pub fn for_potential_meals_returns_dates_for_all_week_meals_test() {
  let start = date.literal("2025-05-12")
  date_model.for_potential_meals(start)
  |> should.equal([
    datetime.literal("2025-05-12T12:00:00.000+02:00"),
    datetime.literal("2025-05-12T19:00:00.000+02:00"),
    datetime.literal("2025-05-13T12:00:00.000+02:00"),
    datetime.literal("2025-05-13T19:00:00.000+02:00"),
    datetime.literal("2025-05-14T12:00:00.000+02:00"),
    datetime.literal("2025-05-14T19:00:00.000+02:00"),
    datetime.literal("2025-05-15T12:00:00.000+02:00"),
    datetime.literal("2025-05-15T19:00:00.000+02:00"),
    datetime.literal("2025-05-16T12:00:00.000+02:00"),
    datetime.literal("2025-05-16T19:00:00.000+02:00"),
    datetime.literal("2025-05-17T12:00:00.000+02:00"),
    datetime.literal("2025-05-17T19:00:00.000+02:00"),
    datetime.literal("2025-05-18T12:00:00.000+02:00"),
    datetime.literal("2025-05-18T19:00:00.000+02:00"),
  ])
}
