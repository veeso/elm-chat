--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Pages.NotFound exposing (view)

import Css exposing (..)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (class, href)



-- View


view : Html msg
view =
    div [ class "container-fluid" ]
        [ div [ class "row" ]
            [ div [ class "col-12", class "align-content-center", class "justify-content-center" ]
                [ h1 [] [ text "The page you were looking for, doesn't exist!" ]
                , a [ href "/" ] [ text "Go back to home" ]
                ]
            ]
        ]
