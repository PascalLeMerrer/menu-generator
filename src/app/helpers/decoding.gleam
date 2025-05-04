import gleam/dynamic
import gleam/dynamic/decode
import gleam/list
import gleam/string

// gleam_json still uses the legacy dynamic decoder
// until it moves to the new one, we need to handle it
pub fn dynamic_decoding_errors_to_string(errors: List(dynamic.DecodeError)) {
  errors
  |> list.map(fn(error) {
    "Expected:"
    <> error.expected
    <> " - Found: "
    <> error.found
    <> " - Path: "
    <> error.path |> string.concat
  })
  |> string.join("\n")
}

pub fn decoding_errors_to_string(errors: List(decode.DecodeError)) {
  errors
  |> list.map(fn(error) {
    "Expected:"
    <> error.expected
    <> " - Found: "
    <> error.found
    <> " - Path: "
    <> error.path |> string.concat
  })
  |> string.join("\n")
}
