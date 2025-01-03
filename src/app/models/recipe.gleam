import gleam/dynamic/decode
import gleam/io
import gleam/json
import gleam/list
import gleam/string_tree
import xmljson

pub type Recipe {
  Recipe(ingredients: List(String), steps: List(String))
}

pub fn from_xml(source: String) -> Result(List(Recipe), json.DecodeError) {
  let assert Ok(source_json) = xmljson.to_json(source)
  let json_string =
    source_json
    |> json.to_string_tree
    |> string_tree.to_string
    |> io.debug

  let recipe_decoder: decode.Decoder(Recipe) = {
    use ingredients <- decode.optional_field(
      "ingredient",
      [],
      decode.at(["li"], decode.list(decode_nested_string())),
    )
    use steps <- decode.optional_field(
      "recipetext",
      [],
      decode.at(["li"], decode.list(decode_nested_string())),
    )

    let actual_ingredients =
      ingredients
      |> list.filter(fn(x) { x != "" })

    let actual_steps =
      steps
      |> list.filter(fn(x) { x != "" })

    decode.success(Recipe(actual_ingredients, actual_steps))
  }

  let cookbook_decoder =
    decode.one_of(
      decode.at(["cookbook", "recipe"], decode.list(recipe_decoder)),
      or: [
        decode.at(
          ["cookbook", "recipe"],
          decode.then(recipe_decoder, fn(recipe) { decode.success([recipe]) }),
        ),
      ],
    )

  json.parse(from: json_string, using: cookbook_decoder)
}

fn decode_nested_string() -> decode.Decoder(String) {
  use str <- decode.optional_field("$", "", decode.string)
  decode.success(str)
}
