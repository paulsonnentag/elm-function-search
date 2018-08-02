const {Main} = require('./build/worker.js')

const worker = Main.worker();

const modules = {
  "Basics" : {
    package : "elm-lang/core",
    version : "1.0.0",
    moduleName : "Basics",
    symbols : [ "toString", "==" ]
  },
  "Html" : {
    package : "elm-lang/html",
    version : "1.0.0",
    moduleName : "Html",
    symbols : [ "beginnerProgram", "div", "button", "text" ]
  },
  "Html.Events":  {
    package : "elm-lang/html",
    version : "2.0.0",
    moduleName : "Html.Events",
    symbols : [ "onClick" ]
  }
}

const source = `import Html exposing (..)
import Html.Events exposing (onClick)

main =
beginnerProgram { model = model, view = view, update = update }


-- MODEL

model = 0


-- UPDATE

type Msg = Increment | Decrement


update msg model =
case msg of
  Increment ->
    model + 1

  Decrement ->
    model - 1


-- VIEW

view model =
div []
  [ button [ onClick Decrement ] [ text "-" ]
  , div [] [ text (toString model) ]
  , button [ onClick Increment ] [ text "+" ]
  ]
`

worker.ports.inputPort.send({
  requestId: "123",
  modules,
  file: source
})


worker.ports.outputPort.subscribe((references) => {
  console.log(JSON.stringify(references, null, 2))
})


