--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


port module Ports exposing (chatMessageReceiver, sessionChanged, setSession, startChat)

import Json.Decode exposing (Value)



-- Ports


{-| Tells to JsRuntime to connect to remote via websockets
-}
port startChat : () -> Cmd msg


{-| Receiver for message from websockets
-}
port chatMessageReceiver : (String -> msg) -> Sub msg


{-| This port is called when the session in the storage changes
-}
port sessionChanged : (Value -> msg) -> Sub msg


{-| This port is called from Elm to set the session in the local storage
-}
port setSession : Value -> Cmd msg
