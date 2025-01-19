import gleam/int
import gleam/io
import sqlight

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

      io.print_error(
        "Database error: " <> error.message <> " (" <> error_code <> ")",
      )
      result
    }
  }
}
