# View Transitions in Elm

Animate DOM changes with the [View Transitions API](https://developer.mozilla.org/en-US/docs/Web/API/View_Transitions_API) in Elm.

## Setup

### Elm

```elm
import ViewTransition

-- Render the next frame with a view transition (Cmd msg)
ViewTransition.start

-- Alias to `Html.Attributes.style "view-transition-name"`
ViewTransition.name
```

### JavaScript

```js
import { ElmViewTransition } from "./ViewTransition.js"

const app = Elm.Main.init({ node: document.getElementById("app") })
ElmViewTransition.init(app, document.getElementById("app"))
```

## Usage

### Triggering a transition

Return `ViewTransition.start` as a command from `update` alongside the model change you want to animate:

```elm
update msg model =
    case msg of
        Shuffle ->
            ( { model | order = List.reverse model.order }
            , ViewTransition.start
            )
```

### Naming elements

Give elements a `view-transition-name` so the browser can animate them individually rather than crossfading the entire page:

```elm
view model =
    div [ ViewTransition.name "hero-card" ]
        [ text "Card" ]
```

Elements with matching names before and after the transition will be smoothly interpolated (position, size, etc.) by the browser.

### Full example

```elm
type Msg
    = Toggle

update msg model =
    case msg of
        Toggle ->
            ( { model | expanded = not model.expanded }
            , ViewTransition.start
            )

view model =
    div []
        [ div
            [ ViewTransition.name "card"
            , onClick Toggle
            , style "width" (if model.expanded then "400px" else "200px")
            ]
            [ text "Click me" ]
        ]
```

## How it works

The View Transitions API expects to control rendering: you provide a callback that performs DOM mutations, and the browser snapshots the old and new states to animate between them.

Elm manages DOM mutations itself, so we can't pass them as a callback directly. Instead, when `ViewTransition.start` fires:

1. The old DOM is cloned before Elm patches it
2. The real DOM is hidden and the clone is shown in its place
3. After Elm finishes patching (next animation frame), `document.startViewTransition` swaps the clone out for the updated real DOM
4. The browser animates between the two snapshots

## Demo

```
make example
```

Open `build/index.html` in your browser.
