--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Views.Alert exposing (AlertType(..), viewAlert)

import Css exposing (..)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (class, css)
import Html.Styled.Events exposing (onClick)


type AlertType
    = Info
    | Secondary
    | Success
    | Error
    | Warning


{-| View alert message on the top of the page
You must provide the text to show, the type of alert and the message to return on dismiss
-}
viewAlert : String -> AlertType -> msg -> Html msg
viewAlert content alert onDismiss =
    div
        [ class "alert"
        , class (getAlertClass alert)
        , onClick onDismiss
        , css
            [ width (Css.em 25)
            , position fixed
            , zIndex (int 500)
            , top (Css.em 2)
            , marginLeft auto
            , marginRight auto
            , left (px 0)
            , right (px 0)
            , textAlign center
            ]
        ]
        [ span []
            [ text content
            , i [ class "bi", class "bi-x" ] []
            ]
        ]


{-| Get alert class based on the type of alert message

    getAlertClass Info -> "alert-info"

-}
getAlertClass : AlertType -> String
getAlertClass alert =
    case alert of
        Info ->
            "alert-info"

        Secondary ->
            "alert-secondary"

        Success ->
            "alert-success"

        Error ->
            "alert-error"

        Warning ->
            "alert-warning"
