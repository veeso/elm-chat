--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Utils exposing (dateDecoder)

import Date
import Json.Decode exposing (Decoder, fail, succeed)


{-| Custom decoder for Date.Date
-}
dateDecoder : String -> Decoder Date.Date
dateDecoder isodate =
    case Date.fromIsoString isodate of
        Ok dt ->
            succeed dt

        Err err ->
            fail ("Could not parse 'lastActivity': " ++ err)
