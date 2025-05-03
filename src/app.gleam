import app/adapters/db
import app/adapters/meal
import app/adapters/recipe as recipe_adapter
import app/router
import app/web.{Context}
import gleam/io
import gleam/result
import sqlight

import cake/adapter/sqlite
import dot_env
import dot_env/env
import gleam/erlang/process
import mist
import wisp
import wisp/wisp_mist

const sqlite_database_filename = "recipes.sqlite3"

fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("app")
  priv_directory <> "/static"
}

pub fn main() {
  wisp.configure_logger()

  dot_env.new()
  |> dot_env.set_path(".env")
  |> dot_env.set_debug(False)
  |> dot_env.load

  sqlite.with_connection(sqlite_database_filename, fn(db_connection) {
    let table_creation_results = [
      db_connection |> db.create_table_if_not_exists(recipe_adapter.schema),
      db_connection |> db.create_table_if_not_exists(meal.schema),
    ]
    case table_creation_results |> result.all() {
      Ok(_) -> db_connection |> start_server
      error -> {
        io.println_error("Exiting on a fatal error")
        error
      }
    }
  })
}

fn start_server(db_connection: sqlight.Connection) {
  let ctx =
    Context(static_directory: static_directory(), connection: db_connection)

  let handler = router.handle_request(_, ctx)
  let assert Ok(secret_key_base) = env.get_string("SECRET_KEY_BASE")
  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(4000)
    |> mist.start_http

  process.sleep_forever()
  Ok([Nil])
}
