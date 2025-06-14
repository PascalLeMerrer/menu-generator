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
    cooking_duration INTEGER, -- in minutes
    image TEXT NOT NULL,
    ingredients TEXT NOT NULL,
    meal_id TEXT,
    preparation_duration INTEGER, -- in minutes
    quantity INTEGER,
    steps TEXT NOT NULL,
    title TEXT NOT NULL,
    total_duration INTEGER, -- in minutes
    uuid TEXT NOT NULL,
    CONSTRAINT fk_meal
      FOREIGN KEY(meal_id)
      REFERENCES meal(uuid)
      ON DELETE CASCADE
    );"

const columns = [
  "cooking_duration", "image", "ingredients", "meal_id", "preparation_duration",
  "quantity", "steps", "title", "total_duration", "uuid",
]

pub fn bulk_insert(
  recipes: List(recipe.Recipe),
  db_connection: sqlight.Connection,
) -> List(Result(recipe.Recipe, List(decode.DecodeError))) {
  recipes
  |> list.map(fn(recipe_to_insert) {
    [
      insert_maybe_int(recipe_to_insert.cooking_duration),
      insert.string(recipe_to_insert.image),
      insert.string(recipe_to_insert.ingredients |> join_lines),
      // imported recipes are not linked to any meal
      case recipe_to_insert.meal_id {
        Some(id) -> insert.string(id |> uuid.to_string)
        None -> insert.null()
      },
      insert_maybe_int(recipe_to_insert.preparation_duration),
      insert_maybe_int(recipe_to_insert.quantity),
      insert.string(recipe_to_insert.steps),
      insert.string(recipe_to_insert.title),
      insert_maybe_int(recipe_to_insert.total_duration),
      insert.string(recipe_to_insert.uuid |> uuid.to_string),
    ]
    |> insert.row
  })
  |> insert.from_values(table_name: table_name, columns: columns)
  |> insert.returning(columns)
  |> insert.to_query
  |> sqlite.run_write_query(decode.dynamic, db_connection)
  |> db.display_db_error
  |> decode_recipes
}

fn insert_maybe_int(value: option.Option(Int)) {
  case value {
    Some(integer) -> insert.int(integer)
    None -> insert.null()
  }
}

fn join_lines(lines: List(String)) -> String {
  string.join(lines, recipe.separator)
}

pub fn get_all(
  db_connection: sqlight.Connection,
) -> List(Result(recipe.Recipe, List(decode.DecodeError))) {
  select.new()
  |> select.from_table(table_name)
  |> select.selects(all_columns())
  |> select.to_query
  |> sqlite.run_read_query(decode.dynamic, db_connection)
  |> db.display_db_error
  |> decode_recipes
}

pub fn find_by_meal_id(
  meal_id: uuid.Uuid,
  db_connection: sqlight.Connection,
) -> List(Result(recipe.Recipe, List(decode.DecodeError))) {
  let uuid = meal_id |> uuid.to_string
  select.new()
  |> select.from_table(table_name)
  |> select.selects(all_columns())
  |> select.where(where.col("meal_id") |> where.eq(where.string(uuid)))
  |> select.to_query
  |> sqlite.run_read_query(decode.dynamic, db_connection)
  |> db.display_db_error
  |> decode_recipes
}

pub fn get(
  recipe_id: uuid.Uuid,
  db_connection: sqlight.Connection,
) -> Result(recipe.Recipe, String) {
  let recipe = find_by_id(recipe_id, db_connection)

  case recipe {
    [Ok(valid_recipe)] -> Ok(valid_recipe)
    _ -> Error("Erreur lors de la lecture de la recette")
  }
}

pub fn find_by_id(
  recipe_id: uuid.Uuid,
  db_connection: sqlight.Connection,
) -> List(Result(recipe.Recipe, List(decode.DecodeError))) {
  let uuid = recipe_id |> uuid.to_string
  select.new()
  |> select.from_table(table_name)
  |> select.selects(all_columns())
  |> select.where(where.col("uuid") |> where.eq(where.string(uuid)))
  |> select.to_query
  |> sqlite.run_read_query(decode.dynamic, db_connection)
  |> db.display_db_error
  |> decode_recipes
}

pub fn find_by_content(content: String, db_connection: sqlight.Connection) {
  let filter = "%" <> content <> "%"
  let query = {
    select.new()
    |> select.from_table(table_name)
    |> select.selects(all_columns())
    |> select.where(where.col("ingredients") |> where.like(filter))
    |> select.or_where(where.col("title") |> where.like(filter))
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
  |> decode_recipes
}

pub fn get_random(
  // 0 will return all recipes
  count: Int,
  excluding recipe_uuids: List(uuid.Uuid),
  db_connection db_connection: sqlight.Connection,
) -> List(Result(recipe.Recipe, List(decode.DecodeError))) {
  let recipes_to_exclude =
    recipe_uuids
    |> list.map(fn(id) { id |> uuid.to_string |> where.string })

  select.new()
  |> select.from_table(table_name)
  |> select.selects(all_columns())
  |> select.where(where.col("meal_id") |> where.is_null)
  |> select.where(
    where.col("uuid")
    |> where.in(recipes_to_exclude)
    |> where.not,
  )
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

// Delete all recipes that are not attached to a meal
// i.e. the imported recipes 
pub fn delete_unlinked(
  db_connection: sqlight.Connection,
) -> Result(List(decode.Dynamic), sqlight.Error) {
  delete_statement.new()
  |> delete_statement.table(table_name)
  |> delete_statement.where(where.col("meal_id") |> where.is_null)
  |> delete_statement.to_query
  |> sqlite.run_write_query(decode.dynamic, db_connection)
  |> db.display_db_error
}

fn all_columns() {
  [select.col("*")]
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
