import app/adapters/db
import app/models/recipe
import cake/adapter/sqlite
import cake/insert
import cake/select
import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/string
import youid/uuid

import gleam/option.{None, Some}
import sqlight

pub const schema = "-- recipes that could be selected for new menus
  CREATE TABLE IF NOT EXISTS recipes (
    image TEXT NOT NULL,
    ingredients TEXT NOT NULL,
    meal_id TEXT,
    steps TEXT NOT NULL,
    title TEXT NOT NULL
    );"

pub fn insert(
  db_connection: sqlight.Connection,
  recipes: List(recipe.Recipe),
) -> Result(List(dynamic.Dynamic), sqlight.Error) {
  recipes
  |> list.map(fn(recipe) {
    [
      insert.string(recipe.image),
      insert.string(recipe.ingredients |> join_lines),
      case recipe.meal_id {
        Some(id) -> insert.string(id |> uuid.to_string)
        None -> insert.null()
      },
      insert.string(recipe.steps),
      insert.string(recipe.title),
    ]
    |> insert.row
  })
  |> insert.from_values(table_name: "recipes", columns: [
    "image", "ingredients", "steps", "title",
  ])
  |> insert.to_query
  |> sqlite.run_write_query(decode.dynamic, db_connection)
  |> db.display_db_error
}

fn join_lines(lines: List(String)) -> String {
  string.join(lines, recipe.separator)
}

pub fn get_all(
  db_connection: sqlight.Connection,
) -> List(Result(recipe.Recipe, List(dynamic.DecodeError))) {
  select.new()
  |> select.from_table("recipes")
  |> select.selects([
    select.col("image"),
    select.col("ingredients"),
    select.col("meal_id"),
    select.col("steps"),
    select.col("title"),
  ])
  |> select.to_query
  |> sqlite.run_read_query(decode.dynamic, db_connection)
  |> db.display_db_error
  |> decode_recipes
}

fn decode_recipes(
  rows: Result(List(dynamic.Dynamic), sqlight.Error),
) -> List(Result(recipe.Recipe, List(dynamic.DecodeError))) {
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
