--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Data.User exposing (..)
-- Dependencies
import Date
import Json.Decode exposing (Decoder, field, string)

type alias User =
    { username : String
    , avatar : Maybe String
    , lastActivity : Date.Date
    , online : Bool
    }

-- Deserialization
decoder : Decoder User
decoder =
  