import gleam/dynamic/decode

pub type Recipe {
  Recipe(
    image: String,
    ingredients: List(String),
    steps: List(String),
    title: String,
  )
}

pub fn recipe_decoder() -> decode.Decoder(Recipe) {
  use image <- decode.field("image", decode.string)
  use ingredients <- decode.field("ingredients", decode.list(decode.string))
  use steps <- decode.field("steps", decode.list(decode.string))
  use title <- decode.field("title", decode.string)
  decode.success(Recipe(image:, ingredients:, steps:, title:))
}
