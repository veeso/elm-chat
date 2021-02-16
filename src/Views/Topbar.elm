--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Views.Topbar exposing (TopBarMessages, viewTopbar)

import Css exposing (..)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attributes exposing (class, css, href)


{-| TopBarMessages defines the possible messages returned by the topbar
Basically you provide a message for each link in the topbar
- onSignOut: sign out pressed
-}
type alias TopBarMessages =
    { onSignOut : msg
    }


{-| View topbar

    viewTopbar messages True

-}
viewTopbar : TopBarMessages -> Bool -> Html msg
viewTopbar messages isAuthed =
    nav
        [ class "navbar"
        , class "navbar-expand-lg"
        , class "navbar-light"
        , css [ backgroundColor (hex "1293d8") ]
        ]
        [ viewTitle
        ]


{-| View topbar title
-}
viewTitle : Html msg
viewTitle =
    a
        [ class "navbar-brand"
        , css [ color (hex "#ffffff") ]
        , href "#"
        ]
        [ text "Elm-chat" ]


{-| View topbar entries wrapper
-}
viewTopbarEntriesWrapper : TopBarMessages -> Bool -> Html msg
viewTopbarEntriesWrapper messages isAuthed =
    div
        [ class "collapse"
        , class "navbar-collapse"
        ]
        [ viewTopbarEntries messages isAuthed
        ]


{-| View topbar entries
-}
viewTopbarEntries : TopBarMessages -> Bool -> Html msg
viewTopbarEntries messages isAuthed =
    ul
        [ class "navbar-nav"
        , class "me-auto"
        , class "mb-2"
        , class "mb-lg-0"
        ]
        [ li [ class "nav-item" ] [ viewSignOut messages.onSignOut ]
        ]


{-| View topbar signout button
-}
viewSignOut : msg -> Html msg
viewSignOut msg =
    a
        [ class "nav-link"
        , class "active"
        , href "#"
        , css [ color (hex "#ffffff") ]
        ]
        [ i [ class "bi", class "bi-box-arrow-right" ] []
        , text " Sign out"
        ]
