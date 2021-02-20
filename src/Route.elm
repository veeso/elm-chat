--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Route exposing (Route(..), href, replaceUrl, routeFromUrl)

import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import Url exposing (Url)
import Url.Parser exposing ((</>), Parser, map, oneOf, s)



-- Routing


type Route
    = Chat
    | SignIn


{-| get href attribute from route
-}
href : Route -> Attribute msg
href targetRoute =
    Attr.href (routeToString targetRoute)


{-| Change url without reloading page
-}
replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    Nav.replaceUrl key <| routeToString route


{-| Get route from url
-}
routeFromUrl : Url -> Maybe Route
routeFromUrl url =
    -- The RealWorld spec treats the fragment like a path.
    -- This makes it *literally* the path, so we can proceed
    -- with parsing as if it had been a normal path all along.
    { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing }
        |> Url.Parser.parse routeParser


{-| Parse route and show a particular content
-}
routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map Chat (s "")
        , map SignIn (s "signIn")
        ]


{-| Convert Route to string representation

routeToString SignIn -> "signIn"

-}
routeToString : Route -> String
routeToString page =
    let
        pieces =
            case page of
                Chat ->
                    []

                SignIn ->
                    [ "signIn" ]
    in
    "#/" ++ String.join "/" pieces
