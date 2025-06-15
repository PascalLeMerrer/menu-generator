import app/helpers/decoding
import app/models/recipe
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import hx
import lustre/attribute.{class, height, src, width}
import lustre/element.{type Element, text}
import lustre/element/html.{div, form, h2, img, input, label, li, ol, span, ul}
import wisp
import youid/uuid

pub fn page(
  recipes: List(Result(recipe.Recipe, List(decode.DecodeError))),
  meal_to_change: option.Option(uuid.Uuid),
) -> Element(t) {
  let meal_id = case meal_to_change {
    option.Some(meal_uuid) -> uuid.to_string(meal_uuid)
    option.None -> ""
  }
  div([], [
    h2([], [text("Mes recettes")]),
    form(
      [
        attribute.id("search-form"),
        hx.post("recipes-search"),
        hx.target(hx.CssSelector("closest div")),
        hx.swap(hx.OuterHTML, option.None),
      ],
      [
        label([attribute.for("search-input")], [
          text("Rechercher par titre ou ingrédient : "),
        ]),
        input([
          attribute.id("search-input"),
          attribute.type_("search"),
          attribute.name("searched_string"),
        ]),
        input([
          attribute.id("meal_to_modify"),
          attribute.type_("hidden"),
          attribute.name("meal_id"),
          attribute.value(meal_id),
        ]),
        input([attribute.type_("submit"), attribute.value("Rechercher")]),
      ],
    ),
    ul(
      [class("unstyled")],
      recipes
        |> list.map(fn(recipe) { view_recipe(recipe, meal_to_change) }),
    ),
  ])
}

fn view_recipe(
  maybe_recipe: Result(recipe.Recipe, List(decode.DecodeError)),
  meal_to_change: option.Option(uuid.Uuid),
) -> Element(t) {
  let meal_id = case meal_to_change {
    option.None -> ""
    option.Some(id) -> uuid.to_string(id)
  }
  li([], case maybe_recipe {
    Error(errors) -> {
      let _ = {
        wisp.log_error(errors |> decoding.decoding_errors_to_string)
      }
      [text("Erreur de décodage de la recette ")]
    }
    Ok(valid_recipe) -> {
      let image_url = case valid_recipe.image {
        "" -> "/static/placeholder-100x100.png"
        _ -> valid_recipe.image
      }
      let recipe_id = valid_recipe.uuid |> uuid.to_string

      [
        div([class("recipe")], [
          img([class("image"), src(image_url), height(100), width(100)]),
          span([class("title")], [text(valid_recipe.title)]),
          div([class("actions")], [
            case meal_to_change {
              option.Some(_) ->
                span(
                  [
                    class("action"),
                    hx.post("recipes-add-to-meal"),
                    hx.vals(
                      json.object([
                        #("recipe_id", recipe_id |> json.string),
                        #("meal_id", meal_id |> json.string),
                      ]),
                      False,
                    ),
                  ],
                  [text("Ajouter au repas")],
                )
              option.None -> span([], [])
            },
            span(
              [
                class("action"),
                hx.post("recipes-metadata"),
                hx.vals(
                  json.object([#("recipe_id", recipe_id |> json.string)]),
                  False,
                ),
                hx.target(hx.CssSelector("next .metadata")),
              ],
              [text("Détails")],
            ),
            span(
              [
                class("action"),
                hx.post("recipes-ingredients"),
                hx.vals(
                  json.object([#("recipe_id", recipe_id |> json.string)]),
                  False,
                ),
                hx.target(hx.CssSelector("next .ingredients")),
              ],
              [text("Ingrédients")],
            ),
            span(
              [
                class("action"),
                hx.post("recipes-steps"),
                hx.vals(
                  json.object([#("recipe_id", recipe_id |> json.string)]),
                  False,
                ),
                hx.target(hx.CssSelector("next .steps")),
              ],
              [text("Étapes")],
            ),
          ]),
          div([class("metadata")], []),
          div([class("ingredients")], []),
          div([class("steps")], []),
        ]),
      ]
    }
  })
}

pub fn view_ingredients(recipe: recipe.Recipe) -> Element(t) {
  div([hx.ext(["remove"]), class("horizontal-container")], [
    ul(
      [class("ingredient-list")],
      recipe.ingredients
        |> list.map(fn(ingredient) { li([], [text(ingredient)]) }),
    ),
    span([attribute.data("remove", "true"), class("close-button")], [
      text("masquer"),
    ]),
  ])
}

pub fn view_steps(recipe: recipe.Recipe) -> Element(t) {
  div([hx.ext(["remove"]), class("horizontal-container")], [
    ol(
      [class("step-list")],
      recipe.steps
        |> string.split("\n")
        |> list.map(fn(step) { li([], [text(step)]) }),
    ),
    span([attribute.data("remove", "true"), class("close-button")], [
      text("masquer"),
    ]),
  ])
}

pub fn view_metadata(recipe_to_display: recipe.Recipe) -> Element(t) {
  let preparation_duration =
    recipe_to_display.preparation_duration |> view_duration("Préparation")
  let cooking_duration =
    recipe_to_display.cooking_duration |> view_duration("Cuisson")
  let total_duration =
    recipe_to_display.total_duration |> view_duration("Total")
  let quantity = recipe_to_display.quantity |> view_quantiy()

  div([hx.ext(["remove"]), class("durations")], [
    preparation_duration,
    total_duration,
    span([attribute.data("remove", "true"), class("close-button")], [
      text("masquer"),
    ]),
    cooking_duration,
    quantity,
  ])
}

fn view_duration(value: option.Option(Int), label: String) {
  case value {
    option.Some(minutes) if minutes < 60 ->
      span([], [text(label <> " : " <> minutes |> int.to_string <> " minutes")])
    option.Some(minutes) -> {
      let remaining_minutes =
        minutes % 60 |> int.to_string |> string.pad_start(to: 2, with: "0")
      let hours = int.divide(minutes, 60) |> result.unwrap(0) |> int.to_string
      span([], [text(label <> " : " <> hours <> "h" <> remaining_minutes)])
    }
    option.None -> span([], [])
  }
}

fn view_quantiy(maybe_quantity: option.Option(Int)) {
  case maybe_quantity {
    option.None -> span([], [])
    option.Some(value) -> {
      let quantity = value |> int.to_string
      span([], [text("Quantité : " <> quantity)])
    }
  }
}
