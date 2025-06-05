import app/models/recipe
import gleam/dynamic
import gleam/option.{Some}
import gleeunit/should
import youid/uuid

const title = "My recipe"

const image = "https://image.com/1"

const uuid1: String = "1ff0d72c-8b82-46fa-a418-a3881e0cce46"

const uuid2: String = "2ff0d722-8b82-46fa-a418-a3881e0cce46"

const cooking_duration = 10

const preparation_duration = 20

const total_duration = 30

pub fn decodes_recipe_with_one_step_and_one_ingredient_test() {
  let assert Ok(meal_id) = uuid.from_string(uuid1)
  let assert Ok(recipe_id) = uuid.from_string(uuid2)

  dynamic.from(#(
    cooking_duration,
    image,
    "a unique ingredient",
    uuid1,
    preparation_duration,
    "a unique step",
    title,
    total_duration,
    uuid2,
  ))
  |> recipe.decode()
  |> should.equal(
    Ok(recipe.Recipe(
      title: title,
      cooking_duration: option.Some(10),
      preparation_duration: option.Some(20),
      total_duration: option.Some(30),
      image: image,
      meal_id: Some(meal_id),
      steps: "a unique step",
      ingredients: ["a unique ingredient"],
      uuid: recipe_id,
    )),
  )
}

pub fn decodes_recipe_with_several_steps_and_ingredients_test() {
  let assert Ok(meal_id) = uuid.from_string(uuid1)
  let assert Ok(recipe_id) = uuid.from_string(uuid2)
  dynamic.from(#(
    cooking_duration,
    image,
    "a first ingredient@a second ingredient",
    uuid1,
    preparation_duration,
    "A first step.\nA second step",
    title,
    total_duration,
    uuid2,
  ))
  |> recipe.decode()
  |> should.equal(
    Ok(recipe.Recipe(
      title: title,
      cooking_duration: option.Some(10),
      preparation_duration: option.Some(20),
      total_duration: option.Some(30),
      image: image,
      meal_id: Some(meal_id),
      steps: "A first step.\nA second step",
      ingredients: ["a first ingredient", "a second ingredient"],
      uuid: recipe_id,
    )),
  )
}

pub fn decodes_real_recipe_test() {
  let real_title = "Potatoes aux épices"
  let real_image =
    "https://www.cuisineactuelle.fr/imgre/fit/~1~cac~2018~09~25~b0a4a9ac-eb87-4eab-8572-6030995cad21.jpeg/400x400/quality/80/crop-from/center/potatoes-maison-aux-epices.jpeg"
  let real_steps =
    "Rincez les pommes de terre et coupez-les en quartiers sans les éplucher.\nCuire les pommes de terre 15 minutes à la vapeur\nDans un saladier, mélangez l’huile avec l’ail haché finement, le paprika, le piment, sel et poivre. Ajoutez les quartiers de pommes de terre et mélangez.\nPréchauffez le four th.6 (180 °C) (position grill si possible)\nBadigeonnez un lèche frite d'une fine couche d'huile. Déposez les pommes de terre dans le lèche-frite. Enfournez à 180°C pour 20 minutes. Une fois bien dorées, servez aussitôt."
  let real_ingredients =
    "1 kg Pommes de terre@3 cuil. à café de Paprika@1 pincée de Piment@3 cuil. à soupe Huile@2 gousses d'ail@Sel@Poivre"
  let assert Ok(real_meal_id) = uuid.from_string(uuid1)
  let assert Ok(real_recipe_id) = uuid.from_string(uuid2)
  dynamic.from(#(
    cooking_duration,
    real_image,
    real_ingredients,
    uuid1,
    preparation_duration,
    real_steps,
    real_title,
    total_duration,
    uuid2,
  ))
  |> recipe.decode()
  |> should.equal(
    Ok(recipe.Recipe(
      title: real_title,
      cooking_duration: option.Some(10),
      preparation_duration: option.Some(20),
      total_duration: option.Some(30),
      image: real_image,
      meal_id: Some(real_meal_id),
      steps: real_steps,
      ingredients: [
        "1 kg Pommes de terre", "3 cuil. à café de Paprika",
        "1 pincée de Piment", "3 cuil. à soupe Huile", "2 gousses d'ail", "Sel",
        "Poivre",
      ],
      uuid: real_recipe_id,
    )),
  )
}
