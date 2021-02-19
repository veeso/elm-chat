--  Elm-chat
--  Developed by Christian Visintin <christian.visintin1997@gmail.com>
--  Copyright (C) 2021 - Christian Visintin
--  Distribuited under "The Unlicense" license
--  for more information, please refer to <https://unlicense.org>


module Main exposing (main)

import Pages.Chat as Chat
import Pages.SignIn as SignIn
import Route exposing (Route)
import Url exposing (Url)

-- Model

type Model
  = Home Chat.Model
  | SignIn SignIn.Model
  | NotFound

