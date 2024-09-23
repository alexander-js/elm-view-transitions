# View Transitions in Elm

This is a PoC for making the [View Transitions API](https://developer.mozilla.org/en-US/docs/Web/API/View_Transitions_API) work in Elm.
It works like this:


You retain a state in your model for the View Transitions you wish to run.

```elm
import ViewTransition exposing (ViewTransition)

type alias Model =
    { viewTransitions : List ViewTransition
    }


model : Model
model =
    -- An empty list of `ViewTransition` means you don't want to run any transitions.
    { viewTransitions = []
    }
```

If you want `view` renders to always be animated with a default View Transition (a crossfade), you can update your model like so:

```elm
model : Model
model =
    { viewTransitions = [ ViewTransition.Default ]
    }
```

Then, at the very root of your `view`, you'll need to wrap all your content in `ViewTransition.root`:

```elm
view : Model -> Html msg
view model =
    ViewTransition.root
        [ ViewTransition.state model.viewTransitions
        ]
        [ ... content goes here
        ]
```

Future DOM updates from Elm will then be wrapped in View Transitions. Seeing as we're passing `ViewTransition.Default`, any change to the DOM will be crossfaded per the default View Transition animation.

However, we probably don't want every single render caused by `view` to be animated. Therefore, we have a way of running animations for a single render pass:

```elm
type Msg
    = ViewTransitionsFinished


update : Msg -> Model -> Model
update msg model =
    case msg of
        ViewTransitionsFinished ->
            { model | viewTransitions = [] }


view : Model -> Html Msg
view model =
    ViewTransition.root
        [ ViewTransition.state model.viewTransitions
        , ViewTransition.onFinish ViewTransitionsFinished
        ]
        [ ... content goes here
        ]
```

`ViewTransitionsFinished` will be passed to `update` immediately after the animation finishes. The message is also guaranteed to be returned before any future DOM renders. This is useful if we want to run a single animation in response to some interaction. A more concrete example with an expanded image:


```elm
type alias Model =
    { viewTransitions : List ViewTransition
    , imageExpanded : Bool
    }

type Msg
    = ViewTransitionsFinished
    | ToggledExpandImage


update : Msg -> Model -> Model
update msg model =
    case msg of
        ViewTransitionsFinished ->
            { model | viewTransitions = [] }

        ToggledExpandImage ->
            { model
                | imageExpanded = not model.imageExpanded
                -- We know that this update to our `Model` will cause the DOM to be updated. As such, we signal that the next render should use a default View Transition crossfade.
                , viewTransitions = [ ViewTransition.Default ]
            }


view : Model -> Html Msg
view model =
    ViewTransition.root
        [ ViewTransition.state model.viewTransitions
        , ViewTransition.onFinish ViewTransitionsFinished
        , Html.Events.onClick ToggledExpandImage
        ]
        -- The image's change in width/height will be crossfaded
        [ if model.imageExpanded then
              Html.img
                  [ Html.Attributes.src "https://placehold.co/500x500"
                  , Html.Attributes.width "500"
                  , Html.Attributes.height "500"
                  ]
                  []

          else
              Html.img
                  [ Html.Attributes.src "https://placehold.co/500x500"
                  , Html.Attributes.width "100"
                  , Html.Attributes.height "100"
                  ]
                  []
        ]
```

## Demo

TODO - add showcase

## How does it work?

The View Transitions API assumes control over rendering. We don't have this because the Elm runtime manages DOM mutations for us (and rightly so!).

However, if we wrap our root DOM node in `view` with a Custom Element (`ViewTransition.root`), we can define our own methods and getters for DOM node access and mutation. Like `childNodes` - Elm uses this getter to traverse the DOM. If we create our own implementation of `childNodes` that recursively wraps the real nodes in [ES6 Proxies](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy), we can opaquely intercept all standard DOM methods/setters Elm intends to use.

Armed with these proxies, we can make sure that mutations are queued and deferred until a View Transition is ready to fire rather than instantaneously writing to the DOM.