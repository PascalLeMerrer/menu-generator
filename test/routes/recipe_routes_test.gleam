import app/models/recipe
import app/routes/recipe_routes
import gleeunit/should

const oven_baked_bar = recipe.Recipe(
  image: "https://assets.afcdn.com/image1.jpg",
  ingredients: ["1 oignon", "1 citron"],
  steps: ["Etape 1", "Etape 2"],
  title: "Bar au four",
)

const flan = recipe.Recipe(
  image: "https://assets.afcdn.com/image2.jpg",
  ingredients: ["1 flan", "1 pâté de campagne"],
  steps: ["Etape A", "Etape B"],
  title: "Flan au pâté",
)

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
  |> should.equal(Ok([oven_baked_bar, flan]))
}

pub fn from_xml_decodes_recipes_with_empty_ingredients_test() {
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
  |> should.equal(Ok([oven_baked_bar, flan]))
}

pub fn from_xml_decodes_recipes_with_empty_steps_test() {
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
            <li/>
            <li>Etape 2</li>
            <li/>
        </recipetext>
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
  |> should.equal(Ok([oven_baked_bar, flan]))
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
  |> should.equal(Ok([recipe.Recipe(..oven_baked_bar, steps: []), flan]))
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
  |> should.equal(Ok([oven_baked_bar]))
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
  |> should.equal(
    Ok([recipe.Recipe(..oven_baked_bar, ingredients: ["1 oignon"])]),
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
  |> should.equal(Ok([recipe.Recipe(..oven_baked_bar, steps: ["Etape 1"])]))
}
