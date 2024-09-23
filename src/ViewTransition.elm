module ViewTransition
    exposing
        ( ViewTransition(..)
        , root
        , state
        , onFinish
        )

import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Encode
import Json.Decode

{-|

A `Default` transition represents the default View Transition behavior of the browser. As of writing, this implies a simple crossfade effect in Google Chrome.

You can also supply `Named` View Transitions. Suppose you wish to animate a thumbnail on one page to an expanded state on another page. While the images might
be different elements on the two pages, you can signal to the View Transitions API that these are conceptually the same.

You'd do something like this:

```
[ Named "preview-image-html-id" "image-transition"
, Named "expanded-image-html-id" "image-transition"
]
```

Where the first argument passed to `Named` is the DOM node id and the second argument represents the `view-transition-name`.
By default, this example would animate the difference in position between the thumbnail image and the expanded image.
-}
type ViewTransition
    = Default
    | Named String String


{-|
This function returns the "root" of all elements to potentially include in View Transitions.

You'll have to use `state` and `onFinish` in conjunction with this constructor.
-}
root : List (Html.Attribute msg) -> List (Html msg) -> Html msg
root attributes children =
    Html.node "elm-view-transition-root"
        attributes
        children


state : List ViewTransition -> Html.Attribute msg
state viewTransitions =
    Html.Attributes.attribute "state" <| Json.Encode.encode 0 <|
        case viewTransitions of
            [] ->
                Json.Encode.null

            _ ->
                Json.Encode.list
                    (\tuple ->
                        Json.Encode.object
                            [ ( "id", Json.Encode.string (Tuple.first tuple) )
                            , ( "name", Json.Encode.string (Tuple.second tuple) )
                            ]
                    )
                    (List.filterMap
                        (\vt ->
                            case vt of
                                Default ->
                                    Nothing

                                Named id name ->
                                    Just ( id, name )
                        )
                        viewTransitions
                    )


onFinish : msg -> Html.Attribute msg
onFinish onViewTransitionFinish =
    Html.Events.on "elm-view-transition-finish" (Json.Decode.succeed onViewTransitionFinish)