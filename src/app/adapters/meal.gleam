import app/adapters/db
import app/models/meal
import cake/adapter/sqlite
import cake/insert
import cake/select
import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import gleam/io
import gleam/list
import tempo/datetime
import youid/uuid

import sqlight

pub const schema = "
  CREATE TABLE IF NOT EXISTS meals (
    date INTEGER NOT NULL,
    menu_id TEXT NOT NULL,
    uuid TEXT PRIMARY KEY
  );"

pub fn insert(
  db_connection: sqlight.Connection,
  meals: List(meal.Meal),
) -> Result(List(dynamic.Dynamic), sqlight.Error) {
  meals
  |> list.map(fn(meal) {
    [
      insert.int(meal.date |> datetime.to_unix_seconds),
      insert.string(meal.menu_id |> uuid.to_string),
      insert.string(meal.uuid |> uuid.to_string),
    ]
    |> insert.row
  })
  |> insert.from_values(table_name: "meals", columns: [
    "date", "menu_id", "uuid",
  ])
  |> insert.to_query
  |> sqlite.run_write_query(decode.dynamic, db_connection)
  |> io.debug
  |> db.display_db_error
}

pub fn get_all(
  db_connection: sqlight.Connection,
) -> List(Result(meal.Meal, List(dynamic.DecodeError))) {
  select.new()
  |> select.from_table("meals")
  |> select.selects([
    select.col("date"),
    select.col("menu_id"),
    select.col("uuid"),
  ])
  |> select.to_query
  |> sqlite.run_read_query(decode.dynamic, db_connection)
  |> db.display_db_error
  |> decode_meals
}

fn decode_meals(
  rows: Result(List(dynamic.Dynamic), sqlight.Error),
) -> List(Result(meal.Meal, List(dynamic.DecodeError))) {
  case rows {
    Ok(records) -> {
      records
      |> list.map(meal.decode)
    }

    Error(sqlight.SqlightError(code, message, _)) -> {
      let error_code =
        code
        |> sqlight.error_code_to_int
        |> int.to_string
      [
        Error([
          dynamic.DecodeError(
            expected: "",
            found: "Database error: " <> message <> " (" <> error_code <> ")",
            path: [""],
          ),
        ]),
      ]
    }
  }
}
