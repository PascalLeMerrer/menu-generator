import app/models/recipe
import gleam/dynamic
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

const title = "My recipe"

const image = "https://image.com/1"

pub fn decodes_recipe_with_one_step_and_one_ingredient_test() {
  dynamic.from(#(image, "a unique ingredient", "a unique step", title))
  |> recipe.decode()
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

pub fn decodes_recipe_with_several_steps_and_ingredients_test() {
  dynamic.from(#(
    image,
    "a first ingredient@a second ingredient",
    "a first step@a second step",
    title,
  ))
  |> recipe.decode()
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

pub fn decodes_real_recipe_test() {
  let real_title = "Potatoes aux épices"
  let real_image =
    "https://www.cuisineactuelle.fr/imgre/fit/~1~cac~2018~09~25~b0a4a9ac-eb87-4eab-8572-6030995cad21.jpeg/400x400/quality/80/crop-from/center/potatoes-maison-aux-epices.jpeg"
  let real_steps =
    "Rincez les pommes de terre et coupez-les en quartiers sans les éplucher.@Cuire les pommes de terre 15 minutes à la vapeur@Dans un saladier, mélangez l’huile avec l’ail haché finement, le paprika, le piment, sel et poivre. Ajoutez les quartiers de pommes de terre et mélangez.@Préchauffez le four th.6 (180 °C) (position grill si possible)@Badigeonnez un lèche frite d'une fine couche d'huile. Déposez les pommes de terre dans le lèche-frite. Enfournez à 180°C pour 20 minutes. Une fois bien dorées, servez aussitôt."
  let real_ingredients =
    "1 kg Pommes de terre@3 cuil. à café de Paprika@1 pincée de Piment@3 cuil. à soupe Huile@2 gousses d'ail@Sel@Poivre"
  dynamic.from(#(real_image, real_ingredients, real_steps, real_title))
  |> recipe.decode()
  |> should.equal(
    Ok(
      recipe.Recipe(
        title: real_title,
        image: real_image,
        steps: [
          "Rincez les pommes de terre et coupez-les en quartiers sans les éplucher.",
          "Cuire les pommes de terre 15 minutes à la vapeur",
          "Dans un saladier, mélangez l’huile avec l’ail haché finement, le paprika, le piment, sel et poivre. Ajoutez les quartiers de pommes de terre et mélangez.",
          "Préchauffez le four th.6 (180 °C) (position grill si possible)",
          "Badigeonnez un lèche frite d'une fine couche d'huile. Déposez les pommes de terre dans le lèche-frite. Enfournez à 180°C pour 20 minutes. Une fois bien dorées, servez aussitôt.",
        ],
        ingredients: [
          "1 kg Pommes de terre", "3 cuil. à café de Paprika",
          "1 pincée de Piment", "3 cuil. à soupe Huile", "2 gousses d'ail",
          "Sel", "Poivre",
        ],
      ),
    ),
  )
}
