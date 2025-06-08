import app/adapters/db
import app/models/meal
import cake/adapter/sqlite
import cake/delete as delete_statement
import cake/insert
import cake/select
import cake/where
import gleam/dynamic/decode
import gleam/int
import gleam/list
import tempo
import tempo/datetime
import youid/uuid

import sqlight

const table_name = "meals"

pub const schema = "
  CREATE TABLE IF NOT EXISTS "
  <> table_name
  <> "(
    date INTEGER NOT NULL,
    menu_id TEXT NOT NULL,
    uuid TEXT PRIMARY KEY
  );"

pub fn insert(
  db_connection: sqlight.Connection,
  meals: List(meal.Meal),
) -> Result(List(decode.Dynamic), sqlight.Error) {
  meals
  |> list.map(fn(meal) {
    [
      insert.int(meal.date |> datetime.to_unix_seconds),
      insert.string(meal.menu_id |> uuid.to_string),
      insert.string(meal.uuid |> uuid.to_string),
    ]
    |> insert.row
  })
  |> insert.from_values(table_name: table_name, columns: [
    "date", "menu_id", "uuid",
  ])
  |> insert.to_query
  |> sqlite.run_write_query(decode.dynamic, db_connection)
  |> db.display_db_error
}

pub fn get_all(
  db_connection: sqlight.Connection,
) -> List(Result(meal.Meal, List(decode.DecodeError))) {
  select.new()
  |> select.from_table(table_name)
  |> select.select(select.col("*"))
  |> select.to_query
  |> sqlite.run_read_query(decode.dynamic, db_connection)
  |> db.display_db_error
  |> decode_meals()
}

pub fn get_limited_to(
  db_connection: sqlight.Connection,
  limit: Int,
) -> List(Result(meal.Meal, List(decode.DecodeError))) {
  select.new()
  |> select.from_table(table_name)
  |> select.select(select.col("*"))
  |> select.limit(limit)
  |> select.order_by_desc("date")
  |> select.to_query
  |> sqlite.run_read_query(decode.dynamic, db_connection)
  |> db.display_db_error
  |> decode_meals()
}

pub fn get_after(
  db_connection: sqlight.Connection,
  date: tempo.DateTime,
) -> List(Result(meal.Meal, List(decode.DecodeError))) {
  let timestamp = date |> datetime.to_unix_seconds

  let query = {
    select.new()
    |> select.from_table(table_name)
    |> select.select(select.col("*"))
    |> select.where(where.col("date") |> where.gte(where.int(timestamp)))
    |> select.order_by_desc("date")
    |> select.to_query
  }

  // To trace the SQL query: 
  // query
  // |> sqlite.read_query_to_prepared_statement
  // |> cake.get_sql
  // |> echo

  query
  |> sqlite.run_read_query(decode.dynamic, db_connection)
  |> db.display_db_error
  |> decode_meals()
}

pub fn get(
  db_connection: sqlight.Connection,
  meal_id: uuid.Uuid,
) -> Result(meal.Meal, String) {
  let meal = find_by_id(meal_id, db_connection)

  case meal {
    [Ok(valid_meal)] -> Ok(valid_meal)
    _ -> Error("Erreur lors de la lecture du repas")
  }
}

fn find_by_id(
  meal_id: uuid.Uuid,
  db_connection: sqlight.Connection,
) -> List(Result(meal.Meal, List(decode.DecodeError))) {
  let uuid = meal_id |> uuid.to_string
  let query = {
    select.new()
    |> select.from_table(table_name)
    |> select.select(select.col("*"))
    |> select.where(where.col("uuid") |> where.eq(where.string(uuid)))
    |> select.to_query
  }

  // query
  // |> sqlite.read_query_to_prepared_statement
  // |> cake.get_sql
  // |> echo

  query
  |> sqlite.run_read_query(decode.dynamic, db_connection)
  |> db.display_db_error
  |> decode_meals()
}

pub fn delete(
  uuid: uuid.Uuid,
  db_connection: sqlight.Connection,
) -> Result(List(decode.Dynamic), sqlight.Error) {
  let uuid = uuid |> uuid.to_string
  echo "step 2"

  let query = {
    delete_statement.new()
    |> delete_statement.table(table_name)
    |> delete_statement.where(where.col("uuid") |> where.eq(where.string(uuid)))
    |> delete_statement.to_query
  }

  // query
  // |> sqlite.write_query_to_prepared_statement
  // |> cake.get_sql
  // |> echo

  query
  |> sqlite.run_write_query(decode.dynamic, db_connection)
  |> db.display_db_error
}

fn decode_meals(
  rows: Result(List(decode.Dynamic), sqlight.Error),
) -> List(Result(meal.Meal, List(decode.DecodeError))) {
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
          decode.DecodeError(
            expected: "",
            found: "Database error: " <> message <> " (" <> error_code <> ")",
            path: [""],
          ),
        ]),
      ]
    }
  }
}
