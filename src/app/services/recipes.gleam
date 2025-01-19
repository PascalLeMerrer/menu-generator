import app/models/recipe
import app/services/db
import cake/adapter/sqlite
import cake/insert
import cake/select
import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import gleam/io
import gleam/list
import gleam/string

import sqlight

const separator = "@"

pub fn create_table_if_not_exists(
  db_connection: sqlight.Connection,
) -> Result(Nil, sqlight.Error) {
  "CREATE TABLE IF NOT EXISTS recipes (
    image TEXT,
    ingredients TEXT,
    steps TEXT,
    title TEXT
  );"
  |> sqlite.execute_raw_sql(db_connection)
  |> db.display_db_error
}

pub fn insert(
  db_connection: sqlight.Connection,
  recipes: List(recipe.Recipe),
) -> Result(List(dynamic.Dynamic), sqlight.Error) {
  recipes
  |> list.map(fn(recipe) {
    [
      insert.string(recipe.title),
      insert.string(recipe.steps |> join_lines),
      insert.string(recipe.ingredients |> join_lines),
      insert.string(recipe.image),
    ]
    |> insert.row
  })
  |> insert.from_values(table_name: "recipes", columns: [
    "title", "steps", "ingredients", "image",
  ])
  |> insert.to_query
  |> sqlite.run_write_query(decode.dynamic, db_connection)
  |> db.display_db_error
}

fn join_lines(lines: List(String)) -> String {
  string.join(lines, separator)
}

pub fn get_all(db_connection: sqlight.Connection) {
  select.new()
  |> select.from_table("recipes")
  |> select.selects([select.col("title"), select.col("image")])
  |> select.to_query
  |> sqlite.run_read_query(decode.dynamic, db_connection)
  |> db.display_db_error
  |> decode_recipes
  |> io.debug
}

fn decode_recipes(
  rows: Result(List(dynamic.Dynamic), sqlight.Error),
) -> List(Result(recipe.Recipe, List(decode.DecodeError))) {
  let decoder: decode.Decoder(recipe.Recipe) = recipe.recipe_decoder()

  case rows {
    Ok(records) -> {
      records
      |> list.map(fn(fields) { decode.run(fields, decoder) })
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
