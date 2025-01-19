import app/models/recipe
import app/pages/home
import app/pages/upload
import gleam/dynamic/decode

pub fn home(recipes: List(Result(recipe.Recipe, List(decode.DecodeError)))) {
  home.root(recipes)
}

pub fn upload() {
  upload.index()
}
