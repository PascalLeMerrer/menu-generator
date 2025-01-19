import app/models/recipe
import gleam/dict
import gleam/dynamic
import gleam/dynamic/decode
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

const title = "My recipe"

const image = "https://image.com/1"

pub fn decode_recipe_with_one_step_and_one_ingredient_test() {
  dynamic.from(
    dict.from_list([
      #("title", title),
      #("image", image),
      #("steps", "a unique step"),
      #("ingredients", "a unique ingredient"),
    ]),
  )
  |> decode.run(recipe.recipe_decoder())
  |> should.equal(
    Ok(
      recipe.Recipe(
        title: title,
        image: image,
        steps: ["a unique step"],
        ingredients: ["a unique ingredient"],
      ),
    ),
  )
}

pub fn decode_recipe_with_several_steps_and_ingredients_test() {
  dynamic.from(
    dict.from_list([
      #("title", title),
      #("image", image),
      #("steps", "a first step@a second step"),
      #("ingredients", "a first ingredient@a second ingredient"),
    ]),
  )
  |> decode.run(recipe.recipe_decoder())
  |> should.equal(
    Ok(
      recipe.Recipe(
        title: title,
        image: image,
        steps: ["a first step", "a second step"],
        ingredients: ["a first ingredient", "a second ingredient"],
      ),
    ),
  )
}
