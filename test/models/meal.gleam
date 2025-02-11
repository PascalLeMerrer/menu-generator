import app/models/meal
import gleam/list
import gleeunit/should
import tempo/datetime

pub fn for_dates_creates_meals_for_every_given_date_test() {
  dates()
  |> meal.for_dates
  |> list.map(fn(meal) { meal.date })
  |> should.equal(dates())
}

pub fn for_dates_creates_meals_with_the_same_menu_id_test() {
  dates()
  |> meal.for_dates
  |> list.map(fn(meal) { meal.menu_id })
  |> list.unique
  |> list.length
  |> should.equal(1)
}

pub fn multiple_call_to_for_dates_creates_meals_with_different_menu_id_test() {
  let menu_ids_1 =
    dates()
    |> meal.for_dates
    |> list.map(fn(meal) { meal.menu_id })
    |> list.unique
  let menu_ids_2 =
    dates()
    |> meal.for_dates
    |> list.map(fn(meal) { meal.menu_id })
    |> list.unique

  menu_ids_1
  |> should.not_equal(menu_ids_2)
}

fn dates() {
  let date1 = datetime.literal("2025-02-06T12:00:00.000+02:00")
  let date2 = datetime.literal("2025-02-07T12:00:00.000+02:00")
  let date3 = datetime.literal("2025-02-08T12:00:00.000+02:00")
  [date1, date2, date3]
}
