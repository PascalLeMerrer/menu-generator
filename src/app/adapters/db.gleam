import cake/adapter/sqlite
import gleam/int
import sqlight
import wisp

pub fn create_table_if_not_exists(
  db_connection: sqlight.Connection,
  schema: String,
) -> Result(Nil, sqlight.Error) {
  schema
  |> sqlite.execute_raw_sql(db_connection)
  |> display_db_error
}

pub fn display_db_error(
  result: Result(a, sqlight.Error),
) -> Result(a, sqlight.Error) {
  case result {
    Ok(_) -> result
    Error(error) -> {
      let error_code =
        error.code
        |> sqlight.error_code_to_int
        |> int.to_string

      wisp.log_error(
        "Database error: " <> error.message <> " (" <> error_code <> ")",
      )
      result
    }
  }
}
