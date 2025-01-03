import app/models/recipe
import gleam/io
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn from_xml_decodes_recipes_test() {
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
        <imageurl>https://assets.afcdn.com/recipe/20181017/82824_w420h344c1cx1684cy2246cxt0cyt0cxb3369cyb4492.jpg
        </imageurl>
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
        <title>Flan au paté</title>
        <preptime>15 min</preptime>
        <cooktime>25 min</cooktime>
        <totaltime>40 min</totaltime>
        <quantity>2</quantity>
        <ingredient>
            <li>1 flan</li>
            <li>1 paté de campagne</li>
        </ingredient>
        <recipetext>
            <li>Etape A</li>
            <li>Etape B</li>
        </recipetext>
        <url>https://www.marmiton.org/recettes/recette_bar-au-four_21505.aspx</url>
        <imageurl>https://assets.afcdn.com/recipe/20181017/82824_w420h344c1cx1684cy2246cxt0cyt0cxb3369cyb4492.jpg
        </imageurl>
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
  |> recipe.from_xml()
  |> should.equal(
    Ok([
      recipe.Recipe(["1 oignon", "1 citron"], ["Etape 1", "Etape 2"]),
      recipe.Recipe(ingredients: ["1 flan", "1 paté de campagne"], steps: [
        "Etape A", "Etape B",
      ]),
    ]),
  )
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
        <imageurl>https://assets.afcdn.com/recipe/20181017/82824_w420h344c1cx1684cy2246cxt0cyt0cxb3369cyb4492.jpg
        </imageurl>
        <rating>0</rating>
    </recipe>
    <recipe>
        <title>Bar au four</title>
        <preptime>15 min</preptime>
        <cooktime>25 min</cooktime>
        <totaltime>40 min</totaltime>
        <quantity>2</quantity>
        <ingredient>
            <li>1 flan</li>
            <li>1 paté de campagne</li>
        </ingredient>
        <recipetext>
            <li>Etape A</li>
            <li>Etape B</li>
        </recipetext>
        <imageurl>https://assets.afcdn.com/recipe/20181017/82824_w420h344c1cx1684cy2246cxt0cyt0cxb3369cyb4492.jpg
        </imageurl>
        <rating>0</rating>
    </recipe>
   </cookbook>
  "
  |> recipe.from_xml()
  |> io.debug()
  |> should.equal(
    Ok([
      recipe.Recipe(["1 oignon", "1 citron"], ["Etape 1", "Etape 2"]),
      recipe.Recipe(ingredients: ["1 flan", "1 paté de campagne"], steps: [
        "Etape A", "Etape B",
      ]),
    ]),
  )
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
        <imageurl>https://assets.afcdn.com/recipe/20181017/82824_w420h344c1cx1684cy2246cxt0cyt0cxb3369cyb4492.jpg
        </imageurl>
        <rating>0</rating>
    </recipe>
    <recipe>
        <title>Bar au four</title>
        <preptime>15 min</preptime>
        <cooktime>25 min</cooktime>
        <totaltime>40 min</totaltime>
        <quantity>2</quantity>
        <ingredient>
            <li>1 flan</li>
            <li>1 paté de campagne</li>
        </ingredient>
        <recipetext>
            <li>Etape A</li>
            <li>Etape B</li>
        </recipetext>
        <imageurl>https://assets.afcdn.com/recipe/20181017/82824_w420h344c1cx1684cy2246cxt0cyt0cxb3369cyb4492.jpg
        </imageurl>
        <rating>0</rating>
    </recipe>
   </cookbook>
  "
  |> recipe.from_xml()
  |> io.debug()
  |> should.equal(
    Ok([
      recipe.Recipe(["1 oignon", "1 citron"], ["Etape 1", "Etape 2"]),
      recipe.Recipe(ingredients: ["1 flan", "1 paté de campagne"], steps: [
        "Etape A", "Etape B",
      ]),
    ]),
  )
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
        <imageurl>https://assets.afcdn.com/recipe/20181017/82824_w420h344c1cx1684cy2246cxt0cyt0cxb3369cyb4492.jpg
        </imageurl>
        <rating>0</rating>
    </recipe>
    <recipe>
        <title>Bar au four</title>
        <preptime>15 min</preptime>
        <cooktime>25 min</cooktime>
        <totaltime>40 min</totaltime>
        <quantity>2</quantity>
        <ingredient>
            <li>1 flan</li>
            <li>1 paté de campagne</li>
        </ingredient>
        <recipetext>
            <li>Etape A</li>
            <li>Etape B</li>
        </recipetext>
        <imageurl>https://assets.afcdn.com/recipe/20181017/82824_w420h344c1cx1684cy2246cxt0cyt0cxb3369cyb4492.jpg
        </imageurl>
        <rating>0</rating>
    </recipe>
   </cookbook>
  "
  |> recipe.from_xml()
  |> io.debug()
  |> should.equal(
    Ok([
      recipe.Recipe(["1 oignon", "1 citron"], []),
      recipe.Recipe(ingredients: ["1 flan", "1 paté de campagne"], steps: [
        "Etape A", "Etape B",
      ]),
    ]),
  )
}

pub fn from_xml_decodes_cookbook_containing_one_recipe_only_test() {
  "<?xml version='1.0' encoding='UTF-8'?>
    <cookbook>
        <recipe>
            <title>Blanquette de la mer au cabillaud</title>
            <ingredient>
                <li>600 g de dos de cabillaud (en 4 pavés)</li>
                <li>400 g de petites pommes de terre</li>
            </ingredient>
            <recipetext>
                <li>Emincer le poireau</li>
                <li>Eplucher les carottes</li>
            </recipetext>
            <url>https://lacerisesurlemaillot.fr/blanquette-cabillaud/</url>
            <imageurl>https://lacerisesurlemaillot.fr/wp-content/uploads/2023/02/blanquette-cabillaud4.jpg</imageurl>
        </recipe>
    </cookbook>
  "
  |> recipe.from_xml()
  |> io.debug()
  |> should.equal(
    Ok([
      recipe.Recipe(
        [
          "600 g de dos de cabillaud (en 4 pavés)",
          "400 g de petites pommes de terre",
        ],
        ["Emincer le poireau", "Eplucher les carottes"],
      ),
    ]),
  )
}

pub fn from_xml_decodes_recipe_with_only_one_ingredient_test() {
  "<?xml version='1.0' encoding='UTF-8'?>
    <cookbook>
        <recipe>
            <title>Blanquette de la mer au cabillaud</title>
            <ingredient>
                <li>600 g de dos de cabillaud (en 4 pavés)</li>
            </ingredient>
            <recipetext>
                <li>Emincer le poireau</li>
                <li>Eplucher les carottes</li>
            </recipetext>
            <url>https://lacerisesurlemaillot.fr/blanquette-cabillaud/</url>
            <imageurl>https://lacerisesurlemaillot.fr/wp-content/uploads/2023/02/blanquette-cabillaud4.jpg</imageurl>
        </recipe>
    </cookbook>
  "
  |> recipe.from_xml()
  |> io.debug()
  |> should.equal(
    Ok([
      recipe.Recipe(["600 g de dos de cabillaud (en 4 pavés)"], [
        "Emincer le poireau", "Eplucher les carottes",
      ]),
    ]),
  )
}

pub fn from_xml_decodes_recipe_with_only_one_step_test() {
  "<?xml version='1.0' encoding='UTF-8'?>
    <cookbook>
        <recipe>
            <title>Blanquette de la mer au cabillaud</title>
            <ingredient>
                <li>600 g de dos de cabillaud (en 4 pavés)</li>
                <li>400 g de petites pommes de terre</li>
            </ingredient>
            <recipetext>
                <li>Emincer le poireau</li>
            </recipetext>
            <url>https://lacerisesurlemaillot.fr/blanquette-cabillaud/</url>
            <imageurl>https://lacerisesurlemaillot.fr/wp-content/uploads/2023/02/blanquette-cabillaud4.jpg</imageurl>
        </recipe>
    </cookbook>
  "
  |> recipe.from_xml()
  |> io.debug()
  |> should.equal(
    Ok([
      recipe.Recipe(
        [
          "600 g de dos de cabillaud (en 4 pavés)",
          "400 g de petites pommes de terre",
        ],
        ["Emincer le poireau"],
      ),
    ]),
  )
}
