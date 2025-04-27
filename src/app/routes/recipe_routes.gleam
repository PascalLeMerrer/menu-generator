import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{None}
import gleam/string
import gleam/string_tree
import xmljson

import app/models/recipe.{type Recipe, Recipe}

pub fn from_xml(source: String) -> Result(List(Recipe), json.DecodeError) {
  let assert Ok(source_json) = xmljson.to_json(source)
  let json_string =
    source_json
    |> json.to_string_tree
    |> string_tree.to_string

  let nested_string_decoder: decode.Decoder(String) = {
    use str <- decode.optional_field("$", "", decode.string)
    decode.success(str)
  }
  let string_or_list_of_strings_decoder: decode.Decoder(List(String)) = {
    decode.one_of(decode.at(["li"], decode.list(nested_string_decoder)), or: [
      decode.at(
        ["li"],
        decode.then(nested_string_decoder, fn(decoded_string) {
          decode.success([decoded_string])
        }),
      ),
    ])
  }

  let recipe_decoder: decode.Decoder(Recipe) = {
    use image <- decode.field("imageurl", nested_string_decoder)

    use ingredients <- decode.optional_field(
      "ingredient",
      [],
      string_or_list_of_strings_decoder,
    )
    let actual_ingredients =
      ingredients
      |> list.filter(fn(x) { x != "" })
    use steps <- decode.optional_field(
      "recipetext",
      [],
      string_or_list_of_strings_decoder,
    )

    use title <- decode.field("title", nested_string_decoder)
    decode.success(Recipe(
      image:,
      ingredients: actual_ingredients,
      meal_id: None,
      steps: steps
        |> list.filter(fn(x) { x != "" })
        |> string.join(with: "\n"),
      title:,
      uuid: None,
    ))
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
