import app/adapters/db
import app/models/meal_recipe
import cake/adapter/sqlite
import cake/insert
import cake/select
import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/string

import sqlight

pub const schema = "
  -- the recipes included in a meal
  CREATE TABLE IF NOT EXISTS menu_recipes (
    image TEXT,
    ingredients TEXT,
    meal_id INTEGER,
    steps TEXT,
    title TEXT,
    FOREIGN KEY(meal_id) REFERENCES meals(rowid)    
  );"

pub fn insert(
  db_connection: sqlight.Connection,
  recipes: List(meal_recipe.MealRecipe),
) -> Result(List(dynamic.Dynamic), sqlight.Error) {
  recipes
  |> list.map(fn(recipe) {
    [
      insert.string(recipe.image),
      insert.string(recipe.ingredients |> join_lines),
      insert.int(recipe.meal_id),
      insert.string(recipe.steps |> join_lines),
      insert.string(recipe.title),
    ]
    |> insert.row
  })
  |> insert.from_values(table_name: "meal_recipes", columns: [
    "image", "ingredients", "meal_id", "steps", "title",
  ])
  |> insert.to_query
  |> sqlite.run_write_query(decode.dynamic, db_connection)
  |> db.display_db_error
}

fn join_lines(lines: List(String)) -> String {
  string.join(lines, meal_recipe.separator)
}

pub fn get_all(
  db_connection: sqlight.Connection,
) -> List(Result(meal_recipe.MealRecipe, List(dynamic.DecodeError))) {
  select.new()
  |> select.from_table("meal_recipes")
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
  |> decode_meal_recipes
}

fn decode_meal_recipes(
  rows: Result(List(dynamic.Dynamic), sqlight.Error),
) -> List(Result(meal_recipe.MealRecipe, List(dynamic.DecodeError))) {
  case rows {
    Ok(records) -> {
      records
      |> list.map(meal_recipe.decode)
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
