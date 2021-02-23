/**
 * @author Christian Visintin <christian.visintin1997@gmail.com>
 * @version 0.1.0
 * @license "The Unlicense"
 */

import Message from "./message";
import User from "./user";

export enum WsMessageType {
  Delivery, // A message is being delivered by a client to another
  Received, // Returned by the second client, when a message has been received
  Read, // Returned by the second client, when a message has been read
  Error, // There was an error in delivering messages
  SessionExpired, // Report to user that its session has expired
  UserJoined, // A user has just signed up
  UserOnline, // A user online state has changed
}

interface WsMessageUser {
  username: string;
  avatar: string | null;
  lastActivity: Date;
  online: boolean;
  inboxSize: number;
}

export interface WsMessage {
  type: WsMessageType; // Message type [*]
  message?: Message | undefined; // [Delivery]
  ref?: string | undefined; // [Received, Read]
  who?: string | undefined; // [Received, Read]
  error?: string | undefined; // [Error]
  user?: WsMessageUser | undefined; // [UserJoined]
  username?: string | undefined; // [UserOnline]
  online?: boolean | undefined; // [UserOnline]
  lastActivity?: Date | undefined; // [UserOnline]
}

/**
 * @description parse message received from client
 * @param {any} data
 * @returns {WsMessage}
 * @throws {Error} if unable to parse message
 */

export function parseMessage(data: any): WsMessage {
  let type = WsMessageType.Error;
  if (data["type"]) {
    switch (data["type"]) {
      case "Delivery":
        type = WsMessageType.Delivery;
        break;
      case "Received":
        type = WsMessageType.Received;
        break;
      case "Read":
        type = WsMessageType.Read;
        break;
      case "Error":
        type = WsMessageType.Error;
        break;
      case "SessionExpired":
        type = WsMessageType.SessionExpired;
        break;
      case "UserJoined":
        type = WsMessageType.UserJoined;
        break;
      case "UserOnline":
        type = WsMessageType.UserOnline;
        break;
      default:
        throw new Error("Bad message type");
    }
  } else {
    throw new Error("Could not find 'type' in payload");
  }
  // Check if has message inside
  if (data["message"] && type === WsMessageType.Delivery) {
    // Parse message
    const dataMsg = data["message"];
    if (!dataMsg["id"]) {
      throw new Error("Missing 'id' in 'message'");
    }
    if (!dataMsg["body"]) {
      throw new Error("Missing 'body' in 'message'");
    }
    if (!dataMsg["datetime"]) {
      throw new Error("Missing 'datetime' in 'message'");
    }
    if (!dataMsg["from"]) {
      throw new Error("Missing 'from' in 'message'");
    }
    if (!dataMsg["to"]) {
      throw new Error("Missing 'to' in 'message'");
    }
    const id = dataMsg["id"];
    const body = dataMsg["body"];
    const datetime = new Date(dataMsg["datetime"]);
    const from = dataMsg["from"];
    const to = dataMsg["to"];
    return {
      type,
      message: {
        id,
        body,
        datetime,
        from,
        to,
        read: false,
        recv: false,
      },
    };
  } else if (
    data["ref"] &&
    data["who"] &&
    (type === WsMessageType.Read || type === WsMessageType.Received)
  ) {
    return {
      type,
      ref: data["ref"],
      who: data["who"],
    };
  } else if (data["error"] && type === WsMessageType.Error) {
    return {
      type,
      error: data["error"],
    };
  } else if (type === WsMessageType.SessionExpired) {
    return {
      type,
    };
  } else if (data["user"] && type === WsMessageType.UserJoined) {
    // Parse message
    const dataMsg = data["user"];
    if (!dataMsg["username"]) {
      throw new Error("Missing 'username' in 'user'");
    }
    if (!dataMsg["lastActivity"]) {
      throw new Error("Missing 'lastActivity' in 'user'");
    }
    if (!dataMsg["online"]) {
      throw new Error("Missing 'online' in 'user'");
    }
    const username = dataMsg["username"];
    const avatar = dataMsg["avatar"] ? dataMsg["avatar"] : null;
    const lastActivity = new Date(dataMsg["lastActivity"]);
    const online = dataMsg["online"];
    const inboxSize = dataMsg["inboxSize"];
    return {
      type,
      user: {
        username,
        avatar,
        lastActivity,
        online,
        inboxSize,
      },
    };
  } else if (
    data["username"] &&
    data["online"] &&
    data["lastActivity"] &&
    (type === WsMessageType.Read || type === WsMessageType.Received)
  ) {
    return {
      type,
      username: data["username"],
      online: data["online"],
      lastActivity: new Date(data["lastActivity"]),
    };
  } else {
    throw new Error("Syntax error in message");
  }
}

/**
 * @description make an error message
 * @param {string} text
 * @param {string} sender
 * @param {string} recipient
 */

export function makeError(error: string): WsMessage {
  return {
    type: WsMessageType.Error,
    error,
  };
}

/**
 * @description make delivery message
 * @param {Message} message
 * @returns {WsMessage}
 */

export function makeDelivery(message: Message): WsMessage {
  return {
    type: WsMessageType.Delivery,
    message,
  };
}

/**
 * @description make received message
 * @param {Message} message
 * @returns {WsMessage}
 */

export function makeReceived(message: Message): WsMessage {
  return {
    type: WsMessageType.Received,
    ref: message.id,
    who: message.to,
  };
}

/**
 * @description make read message
 * @param {Message} message
 * @returns {WsMessage}
 */

export function makeRead(message: Message): WsMessage {
  return {
    type: WsMessageType.Read,
    ref: message.id,
    who: message.to,
  };
}

/**
 * @description make user joined message
 * @param {Message} message
 * @returns {WsMessage}
 */

export function makeUserJoined(user: User): WsMessage {
  return {
    type: WsMessageType.UserJoined,
    user: {
      username: user.username,
      avatar: user.avatar,
      lastActivity: user.lastActivity,
      online: user.online,
      inboxSize: 0,
    },
  };
}

/**
 * @description make user joined message
 * @param {Message} message
 * @returns {WsMessage}
 */

export function makeUserOnline(user: User): WsMessage {
  return {
    type: WsMessageType.UserOnline,
    username: user.username,
    lastActivity: user.lastActivity,
    online: user.online,
  };
}

/**
 * @description make a session expired message
 */

export function sessionExpired(): WsMessage {
  return {
    type: WsMessageType.SessionExpired,
  };
}

/**
 * @description serialize a message into an object
 * @param {WsMessage} message
 * @returns {string}
 */

export function serialize(message: WsMessage): string {
  let type = "";
  switch (message.type) {
    case WsMessageType.Delivery:
      type = "Delivery";
      break;
    case WsMessageType.Error:
      type = "Error";
      break;
    case WsMessageType.SessionExpired:
      type = "SessionExpired";
      break;
    case WsMessageType.Read:
      type = "Read";
      break;
    case WsMessageType.Received:
      type = "Received";
      break;
    case WsMessageType.UserJoined:
      type = "UserJoined";
      break;
    case WsMessageType.UserOnline:
      type = "UserOnline";
      break;
    default:
      throw new Error("Unknown message type: " + message.type);
  }
  return JSON.stringify({
    type: type,
    who: message.who,
    ref: message.ref,
    message: message.message,
    error: message.error,
    user: message.user,
    username: message.username,
    lastActivity: message.lastActivity,
    online: message.online,
  });
}
