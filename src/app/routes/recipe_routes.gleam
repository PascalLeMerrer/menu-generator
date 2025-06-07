import app/models/recipe.{type Recipe, Recipe}
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None}
import gleam/regexp
import gleam/result
import gleam/string
import gleam/string_tree
import wisp
import xmljson
import youid/uuid

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

  let duration_decoder: decode.Decoder(option.Option(Int)) = {
    // decode.then builds a decoder based on the one it is given as an argument
    use duration_string <- decode.then(nested_string_decoder)
    let options = regexp.Options(case_insensitive: True, multi_line: False)
    let assert Ok(re) =
      regexp.compile(
        "(\\d+)\\s?(h)\\s?(\\d+)?|(\\d+)\\s?(minutes|min|mn|m)?",
        with: options,
      )
    let duration_and_unit =
      regexp.split(with: re, content: duration_string)
      |> list.map(string.lowercase)
      |> list.map(string.trim)

    case duration_and_unit {
      ["", "", "", "", integer, "min", ""]
      | ["", "", "", "", integer, "minutes", ""]
      | ["", "", "", "", integer, "mn", ""]
      | ["", "", "", "", integer, "m", ""]
      | ["", "", "", "", integer, "", "'"]
      | ["", "", "", "", integer, "", ""] -> {
        let duration_in_minutes = int.parse(integer) |> option.from_result
        decode.success(duration_in_minutes)
      }
      ["", integer, "h", "", "", "", ""] -> {
        let duration_in_minutes =
          int.parse(integer)
          |> result.map(fn(value) { value * 60 })
          |> option.from_result
        decode.success(duration_in_minutes)
      }
      ["", hours, "h", minutes, "", "", ""]
      | ["", hours, "h", minutes, "", "", "min"]
      | ["", hours, "h", minutes, "", "", "m"] -> {
        let assert Ok(min) = minutes |> int.parse

        let duration_in_minutes =
          hours
          |> int.parse
          |> result.map(fn(value) { value * 60 + min })
          |> option.from_result
        decode.success(duration_in_minutes)
      }
      [""] -> {
        decode.success(option.None)
      }
      a -> {
        echo a
        wisp.log_error(
          "Cannot import recipe with duration: " <> duration_string,
        )
        decode.success(option.None)
      }
    }
  }

  let recipe_decoder: decode.Decoder(Recipe) = {
    use cooking_duration <- decode.optional_field(
      "cooktime",
      option.None,
      duration_decoder,
    )
    use preparation_duration <- decode.optional_field(
      "preptime",
      option.None,
      duration_decoder,
    )
    use total_duration <- decode.optional_field(
      "totaltime",
      option.None,
      duration_decoder,
    )

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
      cooking_duration:,
      image:,
      ingredients: actual_ingredients,
      meal_id: None,
      preparation_duration:,
      steps: steps
        |> list.filter(fn(x) { x != "" })
        |> string.join(with: "\n"),
      title:,
      total_duration:,
      uuid: uuid.v4(),
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
