--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Request.User exposing (getUsers)

import Data.User exposing (User, usersDecoder)
import Http


{-| Send a GET request to get the available users to chat with
-}
getUsers : (Result Http.Error (List User) -> msg) -> Cmd msg
getUsers msg =
    Http.get
        { url = ":3000/api/chat/users"
        , expect = Http.expectJson msg usersDecoder
        }
