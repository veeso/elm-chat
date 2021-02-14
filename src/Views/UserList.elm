--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Views.UserList exposing (Msg(..), viewAvatarColumn, viewLastActivity, viewUserList, viewUsername)

import Css exposing (..)
import Data.User exposing (User)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (alt, class, css, src)
import Html.Styled.Events exposing (onClick)
import Time exposing (Posix)
import Utils exposing (prettyDateFormatter)


{-| Events reported by this view
-}
type Msg
    = UserSelected User


{-| View user list; selected user is rendered differently

    viewUserList [user1, user2, ..., usern] user2

-}
viewUserList : List User -> String -> Html Msg
viewUserList users selected =
    ul [ class "list-group" ]
        (makeUserRows users selected)


{-| Make user rows recursively
-}
makeUserRows : List User -> String -> List (Html Msg)
makeUserRows users selected =
    case users of
        [] ->
            []

        first :: more ->
            (if first.username == selected then
                viewSelectedUserRow first

             else
                viewUserRow first
            )
                :: makeUserRows more selected


{-| View user row
-}
viewUserRow : User -> Html Msg
viewUserRow user =
    li
        [ class "list-group-item"
        , css
            [ hover
                [ backgroundColor (hex "#eeeeee")
                , cursor pointer
                ]
            , active
                [ backgroundColor (hex "#ffffff")
                ]
            ]
        ]
        [ div [ class "row align-items-center", onClick (UserSelected user) ]
            [ viewAvatarColumn user.avatar user.online
            , viewUsername user.username
            , viewLastActivity user.lastActivity
            ]
        ]


{-| View user row for selected user
-}
viewSelectedUserRow : User -> Html Msg
viewSelectedUserRow user =
    li
        [ class "list-group-item"
        , css
            [ backgroundColor (hex "#eeeeee")
            , cursor pointer
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
viewUsername : String -> Html Msg
viewUsername username =
    div [ class "col-4" ]
        [ h6 [] [ text username ]
        ]


{-| View user last activity
-}
viewLastActivity : Posix -> Html Msg
viewLastActivity lastActivity =
    div
        [ class "col align-self-end justify-content-end"
        , css [ textAlign center ]
        ]
        [ span [] [ text (prettyDateFormatter Time.utc lastActivity) ]
        ]


{-| View avatar column
-}
viewAvatarColumn : Maybe String -> Bool -> Html Msg
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
viewAvatar : Maybe String -> Html Msg
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
viewOnlineDot : Html Msg
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
