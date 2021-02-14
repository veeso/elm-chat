# Elm - Chat

Developed by Christian Visintin

- [Elm - Chat](#elm---chat)
  - [Introduction](#introduction)
  - [Project tree](#project-tree)
  - [Setup](#setup)
  - [Features](#features)
  - [API](#api)
    - [Premise](#premise)
    - [Protocols](#protocols)
    - [Entities](#entities)
      - [User](#user)
      - [Message](#message)
    - [Jwt](#jwt)
    - [Requests](#requests)
      - [Sign in](#sign-in)
      - [Sign up](#sign-up)
      - [Sign out](#sign-out)
      - [Auth](#auth)
      - [Get users](#get-users)
      - [Get Conversation](#get-conversation)
      - [Send message](#send-message)
      - [Mark message as read](#mark-message-as-read)
    - [WS Protocol - Message Service](#ws-protocol---message-service)
      - [Delivery message](#delivery-message)
      - [Received](#received)
      - [Read](#read)
      - [User Joined](#user-joined)
      - [User Online](#user-online)
      - [Error](#error)
      - [Session Expired](#session-expired)

---

## Introduction

Elm chat is a simple project I've made to improve my Elm knowledge. The project consists in a web application where you first access to the chat with a username (which must be unique), and then you're able to chat with anybody signed in in the chat.

The backend for this application runs on NodeJS, while the front-end is, obviously, written in Elm.

## Project tree

- `assets/`: contains project assets
  - `avatar/`: avatar directory, where user avatars will be uploaded
- `server/`: backend source directory
- `src/`: elm frontendn source directory
  - `Data/`: These modules describe common data structures, and expose ways to translate them into other data structures (e.g. json deserialization).
  - `Pages/`: These modules hold the logic for the individual pages in the app.
  - `Requests/`: These modules provides functions to interface with the chat backend.
  - `Views/`: These modules hold reusable views which multiple Page modules import.
  - `Main.elm`: application entry point
  - `Ports.elm`: tracks all ports used by the application
  - `Route.elm`: This module exposes functions to translate URLs in the browser's Location bar to logical "pages" in the application, as well as functions to effect Location bar changes.
  - `Utils.elm`: various utils functions
- `elm.json`: elm project setup
- `LICENSE`: Project license
- `README.md`: reame

## Setup

To setup this project you first need to satisfy these requirements:

- [Elm 0.19.1](https://guide.elm-lang.org/install/elm.html)
- [NodeJS](https://nodejs.org/it/)
- [Npm](https://www.npmjs.com/)

Then we need to build the project

In order to setup the backend we need to build it and then run it with node:

```sh
# Setup assets directory
mkdir -p assets/avatar/
# Build server
cd server/
npm install
npm build
# Start server
node build/index.js -l DEBUG -d ../assets/
```

while for the frontend, we'll build it using elm:

```sh
```

## Features

The elm-chat must provide these features:

- possibility to sign in with a username; the username must be unique; authentication must be provided
- possibility to start a conversation with any other connected user

## API

Here is defined the API used to communicate between the server and the client.

### Premise

A note about this project, is that we don't have any persistence and users are kinda volatile, so I won't save users to the database.
I won't handle any timeout for users which don't send any message in a certain time interval.

### Protocols

This API will use both HTTP and websockets. HTTP is used for signin in and retrieving information about current users, while websockets is used exclusively to deliver messages between users.

### Entities

Here are defined the main entities of this API.

#### User

A user identifies an individual user signed in into the chat.
A user is so composed:

- username (*string*): the username for the user; this is our "primary key", since we don't allow different users with the same username.
- avatar: (*string | null*): url to the avatar of the user
- lastActivity: (*date*): last activity for the user
- online (*bool*): describes whether the user is currently online
- secret (*string*): the password used to authenticate

#### Message

A message identifies and invididual message sent from a user to another.
A message has these attributes:

- id (*string, uuidv4*): Unique identifier of the message
- from (*string*): username
- to (*string*): username
- datetime (*date*): Datetime the message was sent
- body (*string*): message body
- received (*boolean*): message has been received once
- read (*boolean*): message has been read once

---

### Jwt

The API server uses JWT to store authentication data. The JWT must be stored as a cookie named as `user`.

### Requests

For all the requests these codes might be returned:

- **400**: for bad parameters in the request
- **401**: if not signed in
- **403**: if not allowed to perform the request
- **404**: if not found
- **405**: if method is not allowed
- **500**: in case of server error

#### Sign in

In order to sign in, you must send a **POST** to `/api/auth/signIn` with the following parameters:

```json
{
  "username": "foo",
  "secret": "mytopsecret",
}
```

the following response is returned:

```json
{
  "jwt": "jwtdata"
}
```

this request might return the following error codes:

- **401**: if credentials are wrong

#### Sign up

In order to sign up (register user), you must send a **POST** to `/api/auth/signUp` with the following parameters.

As multipart/form-data content, provide as `data`:

```json
{
  "username": "foo",
  "secret": "mysecret",
}
```

in addition, the field `avatar` may contain a file.

the following response is returned:

```json
{
  "jwt": "jwtdata"
}
```

this request might return the following error codes:

- **409**: if the user already exists

#### Sign out

In order to sign out, you must send a **POST** to `/api/auth/signOut` with the following parameters:

```json
{}
```

this request might return the following error codes:

**401**: if the user is not signed in

#### Auth

In order to check if still authenticated, you must send a **GET** to `/api/auth/authed`.

this request might return the following error codes:

**401**: if the user is not signed in

#### Get users

In order to get the user list, you must send a **GET** to `/api/chat/users`.

the following response is returned:

```json
[
  {
    "username": "foo",
    "avatar": "url",
    "lastActivity": "2021-02-06T12:40:32Z",
    "online": true
  }
]
```

The session user **WON'T** be returned!

this request might return the following error codes:

- **400**: if you try to send a message to yourself :)
- **401**: if the user is not signed in

#### Get Conversation

In order to get the history of the conversations between the signed user and another, you must send a **GET** to `/api/chat/history/{USERNAME}`

the following response is returned:

```json
[
  {
    "id": "1cdc2990-2e81-4ac5-9983-43a24ecdee19",
    "datetime": "2021-02-06T12:43:00Z",
    "body": "hello world!",
    "from": "foo",
    "to": "bar",
    "read": false,
    "recv": false
  }
]
```

this request might return the following error codes:

- **401**: if the user is not signed in
- **404**: if the provided username doesn't exist

#### Send message

In order to send a message to another user, you must sned a **POST** to `/api/chat/send/{USERNAME}`

with the following paayload:

```json
{
  "body": "Hey there! How's going on?"
}
```

the following response is returned:

```json
{
  "id": "7cde59ce-0fe0-485e-abf8-237637cc905f",
  "datetime": "2021-02-06T12:45:00Z",
  "body": "Hey there! How's going on?",
  "from": "foo",
  "to": "bar",
  "read": false,
  "recv": false
}
```

this request might return the following error codes:

- **401**: if the user is not signed in
- **404**: if the provided username doesn't exist

#### Mark message as read

In order to mark a message as read, you must send a **POST** to `/api/chat/setread/{MESSAGE_ID}`.

this request might return the following error codes:

- **401**: if the user is not signed in
- **404**: if the provided message doesn't exist

### WS Protocol - Message Service

The Ws protocol describes how the message must be built in order to communicate with the server.

The syntax of the messages is JSON, and each one of them is identified by an always-set key `type`, which defines the type of message.
There are 5 types of messages defined in the protocol:

- `Delivery`: Sent by the server to the recipient of a message when a user sends one. Requires `message`.
- `Received`: sent by the server to the sender when the message has been received
- `Read`: sent by the server to the sender when the message has been read
- `Error`: sent by the server to the client, when an error occurs
- `SessionExpired`: sent by the server to the client, when the client session has expired

The base syntax for payloads is:

```json
{
  "type": "messagetype"
}
```

#### Delivery message

The delivery message is sent by a client to the server when a new chat message has been sent. This message holds a `Message` entity. Once received by the server, the message will be dispatched through websockets to the recipient, otherwise will be just stored in the Storage and retrieved at the next reconnection of the recipient user.

The payload of the delivery message is:

```json
{
  "type": "Delivery",
  "message": {
    "id": "8abbcb5f-5afe-4ba6-ae85-56ad40583053",
    "body": "hello, how's it going?",
    "datetime": "2021-02-06T17:49:12Z",
    "from": "foo",
    "to": "bar"
  }
}
```

#### Received

The received message is sent by the server to the client, whenever a message previously sent by the same client, is received (no matter if through websockets or through REST API) by the recipient client.
The payload of the received message is:

```json
{
  "type": "Received",
  "who": "bar",
  "ref": "8abbcb5f-5afe-4ba6-ae85-56ad40583053"
}
```

- who: the recipient of the original message
- ref: the id of the message referred

#### Read

The read message is sent by the server to the client, whenever a message previously sent by the same client, has been read by the recipient client.
The payload of the read message is:

```json
{
  "type": "Read",
  "who": "bar",
  "ref": "8abbcb5f-5afe-4ba6-ae85-56ad40583053"
}
```

- who: the recipient of the original message
- ref: the id of the message referred

#### User Joined

This message is sent by the server to **all the client connected** (exception is made for the client involved), when a new user **signs up**.
The payload of this kind of message is:

```json
{
  "type": "UserJoined",
  "user": {
    "username": "foo",
    "avatar": "url",
    "lastActivity": "2021-02-06T12:40:32Z",
    "online": true
  }
}
```

#### User Online

This message is sent by the server to **all the client connected** (exception is made for the client involved), when a user **signs in or out**.
The payload of this kind of message is:

```json
{
  "type": "UserOnline",
  "username": "omar",
  "online": false,
  "lastActivity": "2021-02-06T12:40:32Z",
}
```

#### Error

The error message is returned by the server, whenever a client has generated an error after a delivery message on the server.
The server will just return a message for the error.
The payload of the error message is:

```json
{
  "type": "Error",
  "error": "Could not deliver message. Client has died"
}
```

#### Session Expired

The session expired message is returned by the server, whenever the client's session has expired.

The payload of the error message is:

```json
{
  "type": "SessionExpired"
}
```
