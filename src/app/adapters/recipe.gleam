import app/adapters/db
import app/models/recipe
import cake/adapter/sqlite
import cake/delete as delete_statement
import cake/insert
import cake/select
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import youid/uuid

import cake/where
import sqlight

pub const table_name = "recipes"

pub const schema = "-- recipes that could be selected for new menus
  CREATE TABLE IF NOT EXISTS "
  <> table_name
  <> " (
    image TEXT NOT NULL,
    ingredients TEXT NOT NULL,
    meal_id TEXT,
    steps TEXT NOT NULL,
    title TEXT NOT NULL,
    uuid TEXT NOT NULL,
    CONSTRAINT fk_meal
      FOREIGN KEY(meal_id)
      REFERENCES meal(uuid)
      ON DELETE CASCADE
    );"

pub fn bulk_insert(
  recipes: List(recipe.Recipe),
  db_connection: sqlight.Connection,
) -> List(Result(recipe.Recipe, List(decode.DecodeError))) {
  recipes
  |> list.map(fn(recipe) {
    [
      insert.string(recipe.image),
      insert.string(recipe.ingredients |> join_lines),
      // imported recipes are not linked to any meal
      case recipe.meal_id {
        Some(id) -> insert.string(id |> uuid.to_string)
        None -> insert.null()
      },
      insert.string(recipe.steps),
      insert.string(recipe.title),
      insert.string(recipe.uuid |> uuid.to_string),
    ]
    |> insert.row
  })
  |> insert.from_values(table_name: table_name, columns: [
    "image", "ingredients", "meal_id", "steps", "title", "uuid",
  ])
  |> insert.returning([
    "image", "ingredients", "meal_id", "steps", "title", "uuid",
  ])
  |> insert.to_query
  |> sqlite.run_write_query(decode.dynamic, db_connection)
  |> db.display_db_error
  |> decode_recipes
}

fn join_lines(lines: List(String)) -> String {
  string.join(lines, recipe.separator)
}

pub fn get_all(
  db_connection: sqlight.Connection,
) -> List(Result(recipe.Recipe, List(decode.DecodeError))) {
  select.new()
  |> select.from_table(table_name)
  |> select.selects([
    select.col("image"),
    select.col("ingredients"),
    select.col("meal_id"),
    select.col("steps"),
    select.col("title"),
    select.col("uuid"),
  ])
  |> select.to_query
  |> sqlite.run_read_query(decode.dynamic, db_connection)
  |> db.display_db_error
  |> decode_recipes
}

pub fn find_by_meal_id(
  db_connection: sqlight.Connection,
  meal_id: uuid.Uuid,
) -> List(Result(recipe.Recipe, List(decode.DecodeError))) {
  let uuid = meal_id |> uuid.to_string
  select.new()
  |> select.from_table(table_name)
  |> select.selects([
    select.col("image"),
    select.col("ingredients"),
    select.col("meal_id"),
    select.col("steps"),
    select.col("title"),
    select.col("uuid"),
  ])
  |> select.where(where.col("meal_id") |> where.eq(where.string(uuid)))
  |> select.to_query
  |> sqlite.run_read_query(decode.dynamic, db_connection)
  |> db.display_db_error
  |> decode_recipes
}

pub fn find_by_id(
  db_connection: sqlight.Connection,
  recipe_id: uuid.Uuid,
) -> List(Result(recipe.Recipe, List(decode.DecodeError))) {
  let uuid = recipe_id |> uuid.to_string
  select.new()
  |> select.from_table(table_name)
  |> select.selects([
    select.col("image"),
    select.col("ingredients"),
    select.col("meal_id"),
    select.col("steps"),
    select.col("title"),
    select.col("uuid"),
  ])
  |> select.where(where.col("uuid") |> where.eq(where.string(uuid)))
  |> select.to_query
  |> sqlite.run_read_query(decode.dynamic, db_connection)
  |> db.display_db_error
  |> decode_recipes
}

pub fn get_random(
  db_connection: sqlight.Connection,
  count: Int,
  // 0 will return all recipes
) -> List(Result(recipe.Recipe, List(decode.DecodeError))) {
  select.new()
  |> select.from_table(table_name)
  |> select.selects([
    select.col("image"),
    select.col("ingredients"),
    select.col("meal_id"),
    select.col("steps"),
    select.col("title"),
    select.col("uuid"),
  ])
  |> select.order_by(by: "RANDOM()", direction: select.Asc)
  |> select.limit(count)
  |> select.to_query
  |> sqlite.run_read_query(decode.dynamic, db_connection)
  |> db.display_db_error
  |> decode_recipes
}

pub fn delete(
  uuid: uuid.Uuid,
  db_connection: sqlight.Connection,
) -> Result(List(decode.Dynamic), sqlight.Error) {
  let uuid = uuid |> uuid.to_string
  delete_statement.new()
  |> delete_statement.table(table_name)
  |> delete_statement.where(where.col("uuid") |> where.eq(where.string(uuid)))
  |> delete_statement.to_query
  |> sqlite.run_write_query(decode.dynamic, db_connection)
  |> db.display_db_error
}

fn decode_recipes(
  rows: Result(List(decode.Dynamic), sqlight.Error),
) -> List(Result(recipe.Recipe, List(decode.DecodeError))) {
  case rows {
    Ok(records) -> {
      records
      |> list.map(recipe.decode)
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
