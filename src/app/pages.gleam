import app/models/recipe
import app/pages/home
import app/pages/recipes
import app/pages/upload
import app/pages/upload_result
import gleam/dynamic

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
