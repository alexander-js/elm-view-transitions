port module ViewTransition exposing (name, start)

import Html
import Html.Attributes


{-| Declare a view transition name on an element.

    div [ ViewTransition.name "hero-card" ] [ text "Card" ]

-}
name : String -> Html.Attribute msg
name =
    Html.Attributes.style "view-transition-name"


{-| Animate the next render as a view transition. -}
start : Cmd msg
start =
    viewTransition_start ""


port viewTransition_start : String -> Cmd msg
