--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Views.User exposing (viewAvatar, viewAvatarAndStatus, viewSelectedUserRow, viewUserRow, viewUsername)

import Css exposing (..)
import Data.User exposing (User)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (alt, class, css, src)
import Html.Styled.Events exposing (onClick)


{-| View user row
-}
viewUserRow : User -> Html ()
viewUserRow user =
    li
        [ css
            [ borderBottom3 (px 1) solid (hex "aaaaaa")
            , hover
                [ backgroundColor (hex "e1e1e1")
                , cursor pointer
                ]
            , active
                [ backgroundColor (hex "ffffff")
                ]
            ]
        ]
        [ div [ class "row align-items-center", onClick () ]
            [ viewAvatarAndStatus user.avatar user.online
            , viewUsername user.username
            , if user.inboxSize > 0 then
                viewInboxSize user.inboxSize

              else
                div [ class "col-2" ] []
            ]
        ]


{-| View user row for selected user
-}
viewSelectedUserRow : User -> Html msg
viewSelectedUserRow user =
    li
        [ css
            [ borderBottom3 (px 1) solid (hex "aaaaaa")
            , backgroundColor (hex "eeeeee")
            , cursor pointer
            ]
        ]
        [ div [ class "row align-items-center" ]
            [ viewAvatarAndStatus user.avatar user.online
            , viewUsername user.username
            , div [ class "col-2" ] []
            ]
        ]


{-| View username column
-}
viewUsername : String -> Html msg
viewUsername username =
    div [ class "col-4" ]
        [ h6 [] [ text username ]
        ]


{-| View user inbox size
-}
viewInboxSize : Int -> Html msg
viewInboxSize size =
    div
        [ class "col-2 align-self-end justify-content-center" ]
        [ div
            [ css
                [ maxWidth fitContent
                , backgroundColor (hex "1293d8")
                , color (hex "ffffff")
                , borderRadius (px 4)
                ]
            ]
            [ span [ css [ color (hex "ffffff") ] ]
                [ i [ class "bi", class "bi-bell" ] []
                , text <| String.fromInt size
                ]
            ]
        ]


{-| View avatar with status
-}
viewAvatarAndStatus : Maybe String -> Bool -> Html msg
viewAvatarAndStatus avatar online =
    div [ class "col-2" ]
        (viewAvatar avatar
            :: (if online then
                    [ viewOnlineDot ]

                else
                    []
               )
        )


{-| View avatar. If Nothing, use fallback avatar
-}
viewAvatar : Maybe String -> Html msg
viewAvatar avatar =
    img
        [ class "rounded-circle"
        , css
            [ height (px 48)
            ]
        , alt "User avatar"
        , src
            (case avatar of
                Just url ->
                    url

                Nothing ->
                    "/assets/static/fallback-avatar.png"
            )
        ]
        []


{-| Draw "online green dot" on the user avatar
-}
viewOnlineDot : Html msg
viewOnlineDot =
    div
        [ css
            [ zIndex (int 100)
            , position absolute
            , marginTop (px 32)
            , marginLeft (px -16)
            , height (px 16)
            , width (px 16)
            , backgroundColor (hex "81de26")
            , borderRadius (pct 50)
            , display inlineBlock
            ]
        ]
        []
