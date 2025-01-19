import gleam/dynamic/decode
import gleam/string

pub type Recipe {
  Recipe(
    image: String,
    ingredients: List(String),
    steps: List(String),
    title: String,
  )
}

pub const separator = "@"

// TODO rename to decoder
pub fn recipe_decoder() -> decode.Decoder(Recipe) {
  use image <- decode.field("image", decode.string)
  use ingredients <- decode.field("ingredients", decode.string)
  use steps <- decode.field("steps", decode.string)
  use title <- decode.field("title", decode.string)
  decode.success(Recipe(
    image:,
    ingredients: ingredients |> string.split(separator),
    steps: steps |> string.split(separator),
    title:,
  ))
}
