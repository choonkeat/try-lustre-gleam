import gleam/dynamic
import gleam/int
import gleam/list
import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import lustre_http

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

pub type Model {
  Model(count: Int, cats: List(String), str: String)
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(Model(0, [], "<none>"), effect.none())
}

pub type Msg {
  Increment(Int)
  Decrement
  ApiReturnedCat(Result(String, lustre_http.HttpError))
  ReadLocalStorage(Result(String, Nil))
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    // Increment(n) -> #(Model(..model, count: model.count + n), get_cat())
    Increment(n) -> #(Model(..model, count: model.count + n), case
      model.count + n < 9
    {
      True -> read(int.to_string(model.count + n), ReadLocalStorage)
      False -> get_cat()
    })
    Decrement -> #(Model(..model, count: model.count - 1), effect.none())
    ApiReturnedCat(Ok(cat)) -> #(
      Model(..model, cats: [cat, ..model.cats]),
      effect.none(),
    )
    ApiReturnedCat(Error(_)) -> #(model, effect.none())
    ReadLocalStorage(Ok(str)) -> #(Model(..model, str: str), effect.none())
    ReadLocalStorage(Error(_nil)) -> #(
      Model(..model, str: "Error!"),
      effect.none(),
    )
  }
}

fn get_cat() -> effect.Effect(Msg) {
  let decoder = dynamic.field("_id", dynamic.string)
  let expect = lustre_http.expect_json(decoder, ApiReturnedCat)

  lustre_http.get("https://cataas.com/cat?json=true", expect)
}

pub fn view(model: Model) -> element.Element(Msg) {
  let count = int.to_string(model.count)

  html.div([], [
    html.h1([], [element.text(model.str)]),
    html.button([event.on_click(Increment(3))], [element.text("+")]),
    element.text(count),
    html.button([event.on_click(Decrement)], [element.text("-")]),
    html.div(
      [],
      list.map(model.cats, fn(cat) {
        html.li([], [
          html.img([attribute.src("https://cataas.com/cat/" <> cat)]),
        ])
      }),
    ),
  ])
}

//

fn read(
  key: String,
  to_msg: fn(Result(String, Nil)) -> msg,
) -> effect.Effect(msg) {
  // the callback function we give to `effect.from` will be given a `dispatch` function
  // and we can call it with our Msg to dispatch to our Lustre app
  // or we can discard the `dispatch` function for as "fire and forget" effect
  effect.from(fn(dispatch) {
    do_read(key)
    |> to_msg
    |> dispatch
  })
}

@external(javascript, "./ffi.mjs", "read")
fn do_read(_key: String) -> Result(String, Nil) {
  Error(Nil)
}
