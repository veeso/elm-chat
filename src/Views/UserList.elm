--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Views.UserList exposing (Msg)

import Css exposing (..)
import Data.User exposing (User)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (alt, class, css, src)
import Time exposing (Posix)
import Utils exposing (prettyDateFormatter)


{-| Events reported by this view
-}
type Msg
    = UserSelected User


{-| View user list

    viewUserList [user1, user2, ..., usern]

-}
viewUserList : List User -> Html msg
viewUserList users =
    ul [ class "list-group" ] (List.map viewUserRow users)


{-| View user row
-}
viewUserRow : User -> Html msg
viewUserRow user =
    li
        [ class "list-group-item"
        , css
            [ hover
                [ backgroundColor (hex "#eeeeee")
                ]
            ]
        ]
        [ div [ class "row align-items-center" ]
            [ viewAvatarColumn user.avatar user.online
            , viewUsername user.username
            , viewLastActivity user.lastActivity
            ]
        ]


{-| View username column
-}
viewUsername : String -> Html msg
viewUsername username =
    div [ class "col-4" ]
        [ h6 [] [ text username ]
        ]


{-| View user last activity
-}
viewLastActivity : Posix -> Html msg
viewLastActivity lastActivity =
    div
        [ class "col align-self-end justify-content-end"
        , css [ textAlign center ]
        ]
        [ span [] [ text (prettyDateFormatter Time.utc lastActivity) ]
        ]


{-| View avatar column
-}
viewAvatarColumn : Maybe String -> Bool -> Html msg
viewAvatarColumn avatar online =
    div [ class "col-1" ]
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
            , backgroundColor (hex "#81de26")
            , borderRadius (pct 50)
            , display inlineBlock
            ]
        ]
        []
