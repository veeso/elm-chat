--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Views.Topbar exposing (TopBarMessages, viewTopbar)

import Css exposing (..)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (class, css)
import Html.Styled.Events exposing (onClick)


{-| TopBarMessages defines the possible messages returned by the topbar
Basically you provide a message for each link in the topbar

  - onSignOut: sign out pressed

-}
type alias TopBarMessages msg =
    { onSignOut : msg
    }


{-| View topbar

    viewTopbar messages True

-}
viewTopbar : TopBarMessages msg -> Bool -> Html msg
viewTopbar messages isAuthed =
    nav
        [ class "navbar"
        , class "navbar-expand-lg"
        , css [ backgroundColor (hex "1293d8") ]
        ]
        [ viewTitle
        , viewTopbarEntriesWrapper messages isAuthed
        ]


{-| View topbar title
-}
viewTitle : Html msg
viewTitle =
    a
        [ class "navbar-brand"
        , css
            [ color (hex "ffffff")
            , cursor pointer
            , hover
                [ color (hex "f1f1f1")
                ]
            ]
        ]
        [ text "Elm-chat" ]


{-| View topbar entries wrapper
-}
viewTopbarEntriesWrapper : TopBarMessages msg -> Bool -> Html msg
viewTopbarEntriesWrapper messages isAuthed =
    div
        [ class "collapse"
        , class "navbar-collapse"
        ]
        [ viewTopbarEntries messages isAuthed
        ]


{-| View topbar entries
-}
viewTopbarEntries : TopBarMessages msg -> Bool -> Html msg
viewTopbarEntries messages isAuthed =
    ul
        [ class "navbar-nav"
        , class "me-auto"
        , class "mb-2"
        , class "mb-lg-0"
        ]
        [ li [ class "nav-item" ]
            [ if isAuthed then
                viewSignOut messages.onSignOut

              else
                text ""
            ]
        ]


{-| View topbar signout button
-}
viewSignOut : msg -> Html msg
viewSignOut msg =
    a
        [ class "nav-link"
        , class "active"
        , css
            [ color (hex "ffffff")
            , cursor pointer
            , hover
                [ color (hex "f1f1f1")
                ]
            ]
        , onClick msg
        ]
        [ i [ class "bi", class "bi-box-arrow-right" ] []
        , text " Sign out"
        ]
