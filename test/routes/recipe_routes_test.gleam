import app/models/recipe
import app/routes/recipe_routes
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleeunit/should
import simplifile
import youid/uuid

const meal_uuid: String = "1ff0d722-8b82-46fa-a418-a3881e0cce46"

const recipe_uuid: String = "18325070-aca8-49b1-9939-baf8b25ee9d1"

fn oven_baked_bar() {
  let assert Ok(meal_id) = uuid.from_string(meal_uuid)
  let assert Ok(recipe_id) = uuid.from_string(recipe_uuid)

  recipe.Recipe(
    cooking_duration: option.None,
    preparation_duration: option.None,
    total_duration: option.None,
    image: "https://assets.afcdn.com/image1.jpg",
    ingredients: ["1 oignon", "1 citron"],
    meal_id: Some(meal_id),
    steps: "Etape 1\nEtape 2",
    title: "Bar au four",
    uuid: recipe_id,
  )
}

fn flan() {
  let assert Ok(uuid) = uuid.from_string(meal_uuid)
  let assert Ok(recipe_id) = uuid.from_string(recipe_uuid)

  recipe.Recipe(
    cooking_duration: option.None,
    preparation_duration: option.None,
    total_duration: option.None,
    image: "https://assets.afcdn.com/image2.jpg",
    ingredients: ["1 flan", "1 pâté de campagne"],
    meal_id: Some(uuid),
    steps: "Etape A\nEtape B",
    title: "Flan au pâté",
    uuid: recipe_id,
  )
}

pub fn from_xml_decodes_cookbook_with_multiple_recipes_test() {
  "<?xml version='1.0' encoding='UTF-8'?>
   <cookbook>
    <recipe>
        <title>Bar au four</title>
        <preptime>15 min</preptime>
        <cooktime>25 min</cooktime>
        <totaltime>40 min</totaltime>
        <quantity>2</quantity>
        <ingredient>
            <li>1 oignon</li>
            <li>1 citron</li>
        </ingredient>
        <recipetext>
            <li>Etape 1</li>
            <li>Etape 2</li>
        </recipetext>
        <url>https://www.marmiton.org/recettes/recette_bar-au-four_21505.aspx</url>
        <imageurl>https://assets.afcdn.com/image1.jpg</imageurl>
        <comments>
            <li>Vite fait, très fin et inratable. La qualité et la fraicheur du poisson font la différence.</li>
        </comments>
        <source>
            <li>FrenchyEve</li>
        </source>
        <video/>
        <rating>0</rating>
        <lang>fr</lang>
    </recipe>
    <recipe>
        <title>Flan au pâté</title>
        <preptime>15 min</preptime>
        <cooktime>25 min</cooktime>
        <totaltime>40 min</totaltime>
        <quantity>2</quantity>
        <ingredient>
            <li>1 flan</li>
            <li>1 pâté de campagne</li>
        </ingredient>
        <recipetext>
            <li>Etape A</li>
            <li>Etape B</li>
        </recipetext>
        <url>https://www.marmiton.org/recettes/recette_bar-au-four_21505.aspx</url>
        <imageurl>https://assets.afcdn.com/image2.jpg</imageurl>
        <comments>
            <li>Vite fait, très fin et inratable. La qualité et la fraicheur du poisson font la différence.</li>
        </comments>
        <source>
            <li>FrenchyEve</li>
        </source>
        <video/>
        <rating>0</rating>
        <lang>fr</lang>
    </recipe>
   </cookbook>
  "
  |> recipe_routes.from_xml()
  |> replace_uuids
  |> should.equal(
    Ok([
      recipe.Recipe(
        ..oven_baked_bar(),
        preparation_duration: Some(15),
        cooking_duration: Some(25),
        total_duration: Some(40),
      ),
      recipe.Recipe(
        ..flan(),
        preparation_duration: Some(15),
        cooking_duration: Some(25),
        total_duration: Some(40),
      ),
    ]),
  )
}

pub fn from_xml_decodes_recipes_with_empty_ingredients_test() {
  "<?xml version='1.0' encoding='UTF-8'?>
   <cookbook>
    <recipe>
        <title>Bar au four</title>
        <quantity>2</quantity>
        <ingredient>
            <li>1 oignon</li>
            <li/>
            <li/>
            <li>1 citron</li>
        </ingredient>
        <recipetext>
            <li>Etape 1</li>
            <li>Etape 2</li>
        </recipetext>
        <imageurl>https://assets.afcdn.com/image1.jpg</imageurl>
        <rating>0</rating>
    </recipe>
    <recipe>
        <title>Flan au pâté</title>
        <quantity>2</quantity>
        <ingredient>
            <li>1 flan</li>
            <li>1 pâté de campagne</li>
        </ingredient>
        <recipetext>
            <li>Etape A</li>
            <li>Etape B</li>
        </recipetext>
        <imageurl>https://assets.afcdn.com/image2.jpg</imageurl>
        <rating>0</rating>
    </recipe>
   </cookbook>
  "
  |> recipe_routes.from_xml()
  |> replace_uuids
  |> should.equal(Ok([oven_baked_bar(), flan()]))
}

pub fn from_xml_decodes_recipes_with_empty_steps_test() {
  "<?xml version='1.0' encoding='UTF-8'?>
   <cookbook>
    <recipe>
        <title>Bar au four</title>
        <quantity>2</quantity>
        <ingredient>
            <li>1 oignon</li>
            <li>1 citron</li>
        </ingredient>
        <recipetext>
            <li>Etape 1</li>
            <li/>
            <li>Etape 2</li>
            <li/>
        </recipetext>
        <imageurl>https://assets.afcdn.com/image1.jpg</imageurl>
        <rating>0</rating>
    </recipe>
    <recipe>
        <title>Flan au pâté</title>
        <quantity>2</quantity>
        <ingredient>
            <li>1 flan</li>
            <li>1 pâté de campagne</li>
        </ingredient>
        <recipetext>
            <li>Etape A</li>
            <li>Etape B</li>
        </recipetext>
        <imageurl>https://assets.afcdn.com/image2.jpg</imageurl>
        <rating>0</rating>
    </recipe>
   </cookbook>
  "
  |> recipe_routes.from_xml()
  |> replace_uuids
  |> should.equal(Ok([oven_baked_bar(), flan()]))
}

pub fn from_xml_decodes_recipes_without_steps_test() {
  "<?xml version='1.0' encoding='UTF-8'?>
   <cookbook>
    <recipe>
        <title>Bar au four</title>
        <preptime>15 min</preptime>
        <cooktime>25 min</cooktime>
        <totaltime>40 min</totaltime>
        <quantity>2</quantity>
        <ingredient>
            <li>1 oignon</li>
            <li>1 citron</li>
        </ingredient>
        <imageurl>https://assets.afcdn.com/image1.jpg</imageurl>
        <rating>0</rating>
    </recipe>
    <recipe>
        <title>Flan au pâté</title>
        <preptime>15 min</preptime>
        <cooktime>25 min</cooktime>
        <totaltime>40 min</totaltime>
        <quantity>2</quantity>
        <ingredient>
            <li>1 flan</li>
            <li>1 pâté de campagne</li>
        </ingredient>
        <recipetext>
            <li>Etape A</li>
            <li>Etape B</li>
        </recipetext>
        <imageurl>https://assets.afcdn.com/image2.jpg</imageurl>
        <rating>0</rating>
    </recipe>
   </cookbook>
  "
  |> recipe_routes.from_xml()
  |> replace_uuids
  |> should.equal(
    Ok([
      recipe.Recipe(
        ..oven_baked_bar(),
        steps: "",
        preparation_duration: Some(15),
        cooking_duration: Some(25),
        total_duration: Some(40),
      ),
      recipe.Recipe(
        ..flan(),
        preparation_duration: Some(15),
        cooking_duration: Some(25),
        total_duration: Some(40),
      ),
    ]),
  )
}

pub fn from_xml_decodes_cookbook_containing_one_recipe_only_test() {
  "<?xml version='1.0' encoding='UTF-8'?>
    <cookbook>
        <recipe>
            <title>Bar au four</title>
            <ingredient>
                <li>1 oignon</li>
                <li>1 citron</li>
            </ingredient>
            <recipetext>
                <li>Etape 1</li>
                <li>Etape 2</li>
            </recipetext>
            <url>https://lacerisesurlemaillot.fr/blanquette-cabillaud/</url>
            <imageurl>https://assets.afcdn.com/image1.jpg</imageurl>
        </recipe>
    </cookbook>
  "
  |> recipe_routes.from_xml()
  |> replace_uuids
  |> should.equal(Ok([oven_baked_bar()]))
}

pub fn from_xml_decodes_recipe_with_only_one_ingredient_test() {
  "<?xml version='1.0' encoding='UTF-8'?>
    <cookbook>
        <recipe>
            <title>Bar au four</title>
            <ingredient>
                <li>1 oignon</li>
            </ingredient>
            <recipetext>
                <li>Etape 1</li>
                <li>Etape 2</li>
            </recipetext>
            <url>https://lacerisesurlemaillot.fr/blanquette-cabillaud/</url>
            <imageurl>https://assets.afcdn.com/image1.jpg</imageurl>
        </recipe>
    </cookbook>
  "
  |> recipe_routes.from_xml()
  |> replace_uuids
  |> should.equal(
    Ok([recipe.Recipe(..oven_baked_bar(), ingredients: ["1 oignon"])]),
  )
}

pub fn from_xml_decodes_recipe_with_only_one_step_test() {
  "<?xml version='1.0' encoding='UTF-8'?>
    <cookbook>
        <recipe>
            <title>Bar au four</title>
            <ingredient>
                <li>1 oignon</li>
                <li>1 citron</li>
            </ingredient>
            <recipetext>
                <li>Etape 1</li>
            </recipetext>
            <url>https://lacerisesurlemaillot.fr/blanquette-cabillaud/</url>
            <imageurl>https://assets.afcdn.com/image1.jpg</imageurl>
        </recipe>
    </cookbook>
  "
  |> recipe_routes.from_xml()
  |> replace_uuids
  |> should.equal(Ok([recipe.Recipe(..oven_baked_bar(), steps: "Etape 1")]))
}

pub fn from_xml_decodes_recipe_with_cooking_duration_in_min_test() {
  "<?xml version='1.0' encoding='UTF-8'?>
    <cookbook>
        <recipe>
            <title>Bar au four</title>
            <cooktime>15 min</cooktime>
            <ingredient>
                <li>1 oignon</li>
                <li>1 citron</li>
            </ingredient>
            <recipetext>
                <li>Etape 1</li>
                <li>Etape 2</li>
            </recipetext>
            <url>https://lacerisesurlemaillot.fr/blanquette-cabillaud/</url>
            <imageurl>https://assets.afcdn.com/image1.jpg</imageurl>
        </recipe>
    </cookbook>
  "
  |> recipe_routes.from_xml()
  |> replace_uuids
  |> should.equal(
    Ok([recipe.Recipe(..oven_baked_bar(), cooking_duration: Some(15))]),
  )
}

pub fn from_xml_decodes_recipe_with_cooking_duration_in_mn_test() {
  "<?xml version='1.0' encoding='UTF-8'?>
    <cookbook>
        <recipe>
            <title>Bar au four</title>
            <cooktime>30 mn</cooktime>
            <ingredient>
                <li>1 oignon</li>
                <li>1 citron</li>
            </ingredient>
            <recipetext>
                <li>Etape 1</li>
                <li>Etape 2</li>
            </recipetext>
            <url>https://lacerisesurlemaillot.fr/blanquette-cabillaud/</url>
            <imageurl>https://assets.afcdn.com/image1.jpg</imageurl>
        </recipe>
    </cookbook>
  "
  |> recipe_routes.from_xml()
  |> replace_uuids
  |> should.equal(
    Ok([recipe.Recipe(..oven_baked_bar(), cooking_duration: Some(30))]),
  )
}

pub fn from_xml_decodes_recipe_with_cooking_duration_in_hour_test() {
  "<?xml version='1.0' encoding='UTF-8'?>
    <cookbook>
        <recipe>
            <title>Bar au four</title>
            <cooktime>1 h</cooktime>
            <ingredient>
                <li>1 oignon</li>
                <li>1 citron</li>
            </ingredient>
            <recipetext>
                <li>Etape 1</li>
                <li>Etape 2</li>
            </recipetext>
            <url>https://lacerisesurlemaillot.fr/blanquette-cabillaud/</url>
            <imageurl>https://assets.afcdn.com/image1.jpg</imageurl>
        </recipe>
    </cookbook>
  "
  |> recipe_routes.from_xml()
  |> replace_uuids
  |> should.equal(
    Ok([recipe.Recipe(..oven_baked_bar(), cooking_duration: Some(60))]),
  )
}

pub fn from_xml_decodes_recipe_with_cooking_duration_in_hour_and_minutes_test() {
  "<?xml version='1.0' encoding='UTF-8'?>
    <cookbook>
        <recipe>
            <title>Bar au four</title>
            <cooktime>1h30</cooktime>
            <ingredient>
                <li>1 oignon</li>
                <li>1 citron</li>
            </ingredient>
            <recipetext>
                <li>Etape 1</li>
                <li>Etape 2</li>
            </recipetext>
            <url>https://lacerisesurlemaillot.fr/blanquette-cabillaud/</url>
            <imageurl>https://assets.afcdn.com/image1.jpg</imageurl>
        </recipe>
    </cookbook>
  "
  |> recipe_routes.from_xml()
  |> replace_uuids
  |> should.equal(
    Ok([recipe.Recipe(..oven_baked_bar(), cooking_duration: Some(90))]),
  )
}

pub fn from_xml_decodes_recipe_with_preparation_duration_test() {
  "<?xml version='1.0' encoding='UTF-8'?>
    <cookbook>
        <recipe>
            <title>Bar au four</title>
            <preptime>10 min</preptime>
            <ingredient>
                <li>1 oignon</li>
                <li>1 citron</li>
            </ingredient>
            <recipetext>
                <li>Etape 1</li>
                <li>Etape 2</li>
            </recipetext>
            <url>https://lacerisesurlemaillot.fr/blanquette-cabillaud/</url>
            <imageurl>https://assets.afcdn.com/image1.jpg</imageurl>
        </recipe>
    </cookbook>
  "
  |> recipe_routes.from_xml()
  |> replace_uuids
  |> should.equal(
    Ok([recipe.Recipe(..oven_baked_bar(), preparation_duration: Some(10))]),
  )
}

pub fn from_xml_decodes_recipe_with_total_duration_test() {
  "<?xml version='1.0' encoding='UTF-8'?>
    <cookbook>
        <recipe>
            <title>Bar au four</title>
            <totaltime>25 min</totaltime>
            <ingredient>
                <li>1 oignon</li>
                <li>1 citron</li>
            </ingredient>
            <recipetext>
                <li>Etape 1</li>
                <li>Etape 2</li>
            </recipetext>
            <url>https://lacerisesurlemaillot.fr/blanquette-cabillaud/</url>
            <imageurl>https://assets.afcdn.com/image1.jpg</imageurl>
        </recipe>
    </cookbook>
  "
  |> recipe_routes.from_xml()
  |> replace_uuids
  |> should.equal(
    Ok([recipe.Recipe(..oven_baked_bar(), total_duration: Some(25))]),
  )
}

pub fn from_xml_decodes_all_imported_recipes_test() {
  let filepath = "./test/data/mycookbookrecipes.xml"
  let assert Ok(content) = simplifile.read(from: filepath)
  content
  |> recipe_routes.from_xml()
  |> result.unwrap([])
  |> list.length
  |> should.equal(395)
}

// replace the random meal and recipe IDs with known ones so we can easily compare actual recipes with expected results
fn replace_uuids(
  maybe_recipes: Result(List(recipe.Recipe), a),
) -> Result(List(recipe.Recipe), a) {
  maybe_recipes
  |> result.try(fn(recipes) {
    recipes
    |> list.map(fn(recipe) {
      let assert Ok(valid_meal_uuid) = uuid.from_string(meal_uuid)
      let assert Ok(valid_recipe_uuid) = uuid.from_string(recipe_uuid)
      recipe.Recipe(
        ..recipe,
        meal_id: Some(valid_meal_uuid),
        uuid: valid_recipe_uuid,
      )
    })
    |> Ok
  })
}
