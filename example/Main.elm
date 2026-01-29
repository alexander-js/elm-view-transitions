module Main exposing (main)

import Browser
import Html exposing (Html, button, div, h1, h2, input, label, node, span, text)
import Html.Attributes exposing (style, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Keyed
import ViewTransition


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }



-- MODEL


type alias Item =
    { label : String
    , color : String
    }


items : List Item
items =
    [ { label = "A", color = "#3498db" }
    , { label = "B", color = "#2ecc71" }
    , { label = "C", color = "#e74c3c" }
    , { label = "D", color = "#f39c12" }
    , { label = "E", color = "#9b59b6" }
    , { label = "F", color = "#1abc9c" }
    ]


type Layout
    = Grid
    | List
    | Scattered


type alias Model =
    { order : List Int
    , layout : Layout
    , selected : Maybe Int
    , speed : Int
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { order = List.range 0 (List.length items - 1)
      , layout = Grid
      , selected = Nothing
      , speed = 400
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = Shuffle
    | Reverse
    | SetLayout Layout
    | Select Int
    | Deselect
    | SetSpeed String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Shuffle ->
            ( { model | order = rotate 2 model.order }
            , ViewTransition.start
            )

        Reverse ->
            ( { model | order = List.reverse model.order }
            , ViewTransition.start
            )

        SetLayout layout ->
            ( { model | layout = layout, selected = Nothing }
            , ViewTransition.start
            )

        Select idx ->
            ( { model | selected = Just idx }
            , ViewTransition.start
            )

        Deselect ->
            ( { model | selected = Nothing }
            , ViewTransition.start
            )

        SetSpeed val ->
            ( { model | speed = String.toInt val |> Maybe.withDefault 400 }
            , Cmd.none
            )


rotate : Int -> List a -> List a
rotate n list =
    List.drop n list ++ List.take n list



-- VIEW


view : Model -> Html Msg
view model =
    div [ style "max-width" "600px" ]
        [ node "style" [] [ text (":root { --vt-duration: " ++ String.fromInt model.speed ++ "ms; }") ]
        , h1 [] [ text "View Transitions" ]
        , label [ style "display" "flex", style "align-items" "center", style "gap" "0.5rem", style "margin-bottom" "1rem" ]
            [ text "Speed"
            , input [ type_ "range", Html.Attributes.min "50", Html.Attributes.max "1500", value (String.fromInt model.speed), onInput SetSpeed ] []
            , span [] [ text (String.fromInt model.speed ++ "ms") ]
            ]
        , div [ style "display" "flex", style "gap" "0.5rem", style "margin-bottom" "1rem", style "flex-wrap" "wrap" ]
            [ btn "Shuffle" Shuffle
            , btn "Reverse" Reverse
            , btn "Grid" (SetLayout Grid)
            , btn "List" (SetLayout List)
            , btn "Scatter" (SetLayout Scattered)
            ]
        , case model.selected of
            Just idx ->
                viewDetail idx

            Nothing ->
                viewItems model.layout model.order
        ]


btn : String -> Msg -> Html Msg
btn label msg =
    button
        [ onClick msg
        , style "padding" "0.4rem 0.8rem"
        , style "border" "1px solid #ccc"
        , style "border-radius" "6px"
        , style "background" "white"
        , style "cursor" "pointer"
        ]
        [ text label ]


viewItems : Layout -> List Int -> Html Msg
viewItems layout order =
    let
        ( containerStyle, itemStyle ) =
            case layout of
                Grid ->
                    ( [ style "display" "grid"
                      , style "grid-template-columns" "repeat(3, 1fr)"
                      , style "gap" "12px"
                      ]
                    , \_ ->
                        [ style "height" "100px"
                        ]
                    )

                List ->
                    ( [ style "display" "flex"
                      , style "flex-direction" "column"
                      , style "gap" "8px"
                      ]
                    , \_ ->
                        [ style "height" "48px"
                        ]
                    )

                Scattered ->
                    ( [ style "position" "relative"
                      , style "height" "350px"
                      ]
                    , \i ->
                        let
                            x =
                                modBy 3 i * 180 + modBy 2 i * 30

                            y =
                                i // 3 * 140 + modBy 3 i * 20
                        in
                        [ style "position" "absolute"
                        , style "left" (String.fromInt x ++ "px")
                        , style "top" (String.fromInt y ++ "px")
                        , style "width" "120px"
                        , style "height" "80px"
                        ]
                    )
    in
    Html.Keyed.node "div"
        containerStyle
        (List.filterMap
            (\i ->
                getItem i
                    |> Maybe.map
                        (\item ->
                            ( item.label
                            , div
                                ([ ViewTransition.name ("item-" ++ item.label)
                                 , onClick (Select i)
                                 , style "background" item.color
                                 , style "border-radius" "10px"
                                 , style "display" "flex"
                                 , style "align-items" "center"
                                 , style "justify-content" "center"
                                 , style "color" "white"
                                 , style "font-size" "1.5rem"
                                 , style "font-weight" "bold"
                                 , style "cursor" "pointer"
                                 ]
                                    ++ itemStyle i
                                )
                                [ text item.label ]
                            )
                        )
            )
            order
        )


viewDetail : Int -> Html Msg
viewDetail idx =
    case getItem idx of
        Just item ->
            div
                [ ViewTransition.name ("item-" ++ item.label)
                , onClick Deselect
                , style "background" item.color
                , style "border-radius" "16px"
                , style "padding" "2rem"
                , style "color" "white"
                , style "cursor" "pointer"
                , style "min-height" "200px"
                ]
                [ h2 [ style "margin-top" "0" ] [ text ("Item " ++ item.label) ]
                , text "Click to go back"
                ]

        Nothing ->
            text ""


getItem : Int -> Maybe Item
getItem i =
    List.drop i items |> List.head
