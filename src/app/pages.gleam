import app/models/meal
import app/models/recipe
import app/pages/error
import app/pages/generated_meals
import app/pages/home
import app/pages/recipes
import app/pages/upload
import app/pages/upload_result
import gleam/dynamic

pub fn error(error_message) {
  error.index(error_message)
}

pub fn generated_meals(meals: List(#(meal.Meal, recipe.Recipe))) {
  generated_meals.index(meals)
}

pub fn home() {
  home.index()
}

pub fn recipes(recipes: List(Result(recipe.Recipe, List(dynamic.DecodeError)))) {
  recipes.index(recipes)
}

pub fn upload() {
  upload.index()
}

pub fn upload_result(recipes: List(recipe.Recipe)) {
  upload_result.index(recipes)
}
