--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Views.Conversation exposing (viewConversation)

import Css exposing (..)
import Data.Message exposing (Conversation, Message)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (class, css, src)
import Time exposing (Posix)
import Utils exposing (prettyDateFormatter)


{-| Describes the message direction
-}
type MessageDirection
    = MsgIn
    | MsgOut


{-| View for entire chat conversation
Arguments:

  - Conversation
  - Username (client name)

-}
viewConversation : Conversation -> String -> Html msg
viewConversation conversation username =
    div
        [ class "container-fluid"
        , css
            [ width (pct 100)
            , height (pct 100)
            , minHeight (pct 100)
            , minWidth (pct 100)
            , overflow auto
            , backgroundImage (url "/assets//static/upfeathers.png")
            , backgroundRepeat repeat
            ]
        ]
        (mapMessages conversation username)


{-| For each message in conversation, call view message with the correct direction

    Arguments:
        - Conversation
        - Username

-}
mapMessages : Conversation -> String -> List (Html msg)
mapMessages conversation username =
    case conversation of
        [] ->
            []

        first :: more ->
            viewMessage first
                (if first.sender == username then
                    MsgOut

                 else
                    MsgIn
                )
                :: mapMessages more username


{-| View a message

    Arguments:
        - Message
        - Direction

-}
viewMessage : Message -> MessageDirection -> Html msg
viewMessage message direction =
    div
        [ class
            (case direction of
                MsgIn ->
                    "justify-content-start"

                MsgOut ->
                    "justify-content-end"
            )
        , class "row"
        , css
            [ width (pct 100)
            , padding (Css.em 1)
            ]
        ]
        [ div
            [ class "col-3"
            ]
            [ case direction of
                MsgIn ->
                    viewMessageIn message

                MsgOut ->
                    viewMessageOut message
            ]
        ]


{-| View a message sent by the other user to us

    Arguments:
        - Message

-}
viewMessageIn : Message -> Html msg
viewMessageIn message =
    div
        [ css
            [ borderRadius (Css.em 0.3)
            , height (pct 100)
            , position relative
            , flex none
            , lineHeight (Css.em 1.2)
            , color (hex "303030")
            , backgroundColor (hex "ffffff")
            ]
        ]
        [ viewMessageArrowIn
        , viewMessageContent message.body
        , viewMessageDate message.datetime
        ]


{-| View a message sent by us to other user

    Arguments:
        - Message

-}
viewMessageOut : Message -> Html msg
viewMessageOut message =
    div
        [ css
            [ borderRadius (Css.em 0.3)
            , height (pct 100)
            , position relative
            , flex none
            , lineHeight (Css.em 1.2)
            , color (hex "303030")
            , backgroundColor (hex "c6f5f8")
            ]
        ]
        [ viewMessageArrowOut
        , viewMessageContent message.body
        , viewMessageDate message.datetime
        , viewMessageState message.recv message.read
        ]


{-| View message content

    Arguments:
        - body

-}
viewMessageContent : String -> Html msg
viewMessageContent content =
    div
        [ css
            [ padding (Css.em 0.5)
            , position relative
            , zIndex (int 200)
            ]
        ]
        [ span []
            [ text content
            ]
        ]


{-| View message date

    Arguments:
        - date

-}
viewMessageDate : Posix -> Html msg
viewMessageDate datetime =
    div
        [ css
            [ padding (Css.em 0.2)
            , fontSize (Css.em 0.8)
            , float right
            , color (hex "888888")
            ]
        ]
        [ span []
            [ text (prettyDateFormatter Time.utc datetime)
            ]
        ]


{-| View message state

    viewMessageState message.recv message.read

-}
viewMessageState : Bool -> Bool -> Html msg
viewMessageState received read =
    div
        [ css
            [ padding (Css.em 0.2)
            , fontSize (Css.em 0.8)
            , float right
            , color (hex "888888")
            ]
        ]
        [ i
            [ class "bi"
            , class
                (if read then
                    "bi-eye-fill"

                 else if received then
                    "by-inbox-fill"

                 else
                    "clock-fill"
                )
            ]
            []
        ]


{-| View little arrow on the left of the message in
-}
viewMessageArrowIn : Html msg
viewMessageArrowIn =
    span
        [ css
            [ color (hex "fffafa")
            , position absolute
            , display block
            , top (Css.em -0.3)
            , zIndex (int 100)
            , left (px -8)
            , width (px 8)
            , height (px 13)
            ]
        ]
        [ img [ src "/assets/static/arrow-in.svg" ] []
        ]


{-| View little arrow on the left of the message in
-}
viewMessageArrowOut : Html msg
viewMessageArrowOut =
    span
        [ css
            [ color (hex "c6f5f8")
            , position absolute
            , display block
            , top (Css.em -0.3)
            , zIndex (int 100)
            , right (px -8)
            , width (px 8)
            , height (px 13)
            ]
        ]
        [ img [ src "/assets/static/arrow-out.svg" ] []
        ]
