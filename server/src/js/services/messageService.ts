/**
 * @author Christian Visintin <christian.visintin1997@gmail.com>
 * @version 0.1.0
 * @license "The Unlicense"
 */

// ws
import WebSocket from "ws";
import http from "http";
// lib
import { Logger } from "log4js";
import getLogger from "../lib/utils/logger";
import {
  parseMessage,
  makeDelivery,
  serialize,
  WsMessage,
  WsMessageType,
  makeRead,
  makeReceived,
  makeUserJoined,
} from "../lib/data/ws";
import Message from "../lib/data/message";
import Storage from "../lib/data/storage";
import User from "../lib/data/user";

export default class MessageService {
  private channels: Map<string, WebSocket>; // Association between username and socket
  private logger: Logger;
  private store: Storage;

  /**
   *
   * @param {OnMessageCb} onClientMsg
   * @param {GetUserCb} getUser
   */

  constructor(store: Storage) {
    this.channels = new Map();
    this.store = store;
    // add subscriptions to store
    this.store.subscribeRead((msg: Message) => {
      this.dispatchRead(msg);
    });
    this.store.subscribeReceived((msg: Message) => {
      this.dispatchReceived(msg);
    });
    this.store.subscribeOnMessage((msg: Message) => {
      this.dispatchDelivery(msg);
    });
    this.store.subscribeOnUserJoined((user: User) => {
      this.dispatchUserJoined(user);
    });
    this.store.subscribeOnUserOnline((user: User) => {
      this.dispatchUserOnline(user);
    });
    // Make logger
    this.logger = getLogger("messageService");
    this.logger.info("Message service started!");
  }

  /**
   * @description method to call to register a new websocket connection
   * @param {WebSocket} socket 
   * @param {http.IncomingMessage} _request 
   * @param {string} username 
   */

  public onConnection(socket: WebSocket, _request: http.IncomingMessage, username: string) {
    // Register socket to channels
    this.logger.info("New websockets connection from", username);
    this.channels.set(username, socket);
    // Register listener for this socket
    socket.on("message", (message: WebSocket.Data) => {
      this.dispatchMessage(username, socket, message);
    });
    // Register on close
    socket.on("close", () => {
      this.logger.info("Client", username, "has left chat!");
      // Clear socket entry
      socket.close();
      this.channels.delete(username);
    });
  }

  /**
   * @description stop message service
   * @param {Function | undefined} onStopped
   */

  public stop(onStopped: Function | undefined = undefined) {
    this.logger.info("Stopping message service...");
    // Stop sockets
    this.channels.forEach((socket: WebSocket, name: string) => {
      this.logger.debug("Closing socket for", name);
      socket.close();
    });
    // Clear entries
    this.channels.clear();
    this.logger.info("Message service stopped!");
    if (onStopped) {
      onStopped();
    }
  }

  /**
   * @description dispatch message to recipient; call also OnMessage callback
   * @param {string} client
   * @param {WebSocket} socket sender socket
   * @param {WebSocket.Data} message
   */

  private dispatchMessage(
    client: string,
    _socket: WebSocket,
    message: WebSocket.Data
  ) {
    let wsMessage: WsMessage;
    // Decode data
    try {
      const jsonData = JSON.parse(message.toString());
      // Parse message
      wsMessage = parseMessage(jsonData);
      this.logger.debug(
        "Got WS message (",
        wsMessage.type,
        ") from",
        client,
        "with type",
        wsMessage.type
      );
    } catch (err) {
      this.logger.error("Could not parse ws message:", err);
      return;
    }
    // Switch over message type
    switch (wsMessage.type) {
      case WsMessageType.Error:
        this.logger.warn("Client", client, "reports error:", wsMessage.error);
        break;
      default:
        this.logger.debug("Got nothing to do with message", wsMessage.type);
        break;
    }
  }

  /**
   * @description dispatch delivery message
   * @param {WebSocket} socket (sender socket)
   * @param {WsMessage} message
   */

  private dispatchDelivery(message: Message) {
    // Error callback
    const errCb = (err: Error | undefined) => {
      if (err) {
        this.logger.error("Could not send message:", err);
      }
    };
    // Check if `to`'s socket exists
    const socket = this.channels.get(message.to);
    if (!socket) {
      this.logger.debug(
        "No socket is available for",
        message.to,
        ", is it offline?"
      );
      return;
    }
    // Serialize read
    const wsMessage: WsMessage = makeDelivery(message);
    this.logger.debug(
      "Delivering message from",
      message.from,
      "to",
      message.to
    );
    socket.send(serialize(wsMessage), errCb);
    this.logger.info("Delivery dispatched to", message.to);
  }

  /**
   * @description dispatch a read message event to sender
   * @param {Message} message
   */

  private dispatchRead(message: Message) {
    const errCb = (err: Error | undefined) => {
      if (err) {
        this.logger.error("Could not send message:", err);
      }
    };
    // Check if `from`'s socket exists
    const socket = this.channels.get(message.from);
    if (!socket) {
      this.logger.debug(
        "No socket is available for",
        message.from,
        ", is it offline?"
      );
      return;
    }
    // Serialize read
    const wsMessage: WsMessage = makeRead(message);
    this.logger.debug(
      "Sending read notification for",
      wsMessage.ref,
      "with recipient",
      wsMessage.who,
      "to",
      message.from
    );
    socket.send(serialize(wsMessage), errCb);
    this.logger.info("Read notification dispatched to", message.from);
  }

  /**
   * @description dispatch a received message event to sender
   * @param {Message} message
   */

  private dispatchReceived(message: Message) {
    const errCb = (err: Error | undefined) => {
      if (err) {
        this.logger.error("Could not send message:", err);
      }
    };
    // Check if `from`'s socket exists
    const socket = this.channels.get(message.from);
    if (!socket) {
      this.logger.debug(
        "No socket is available for",
        message.from,
        ", is it offline?"
      );
      return;
    }
    // Serialize received
    const wsMessage: WsMessage = makeReceived(message);
    this.logger.debug(
      "Sending received notification for",
      wsMessage.ref,
      "with recipient",
      wsMessage.who,
      "to",
      message.from
    );
    socket.send(serialize(wsMessage), errCb);
    this.logger.info("Received notification dispatched to", message.from);
  }

  /**
   * @description notify to all clients (except user's one) that a new user has joined the chat
   * @param {User} user
   */

  private dispatchUserJoined(user: User) {
    this.logger.info(
      "Notifying clients that user",
      user.username,
      "has joined the chat"
    );
    const errCb = (err: Error | undefined) => {
      if (err) {
        this.logger.error("Could not send message:", err);
      }
    };
    // Serialize message
    const outMessage: WsMessage = makeUserJoined(user);
    // Iterate over channels
    Array.from(this.channels.keys()).map((username) => {
      // If username is different from user.username, send the message
      const socket = this.channels.get(username);
      if (username !== user.username && socket) {
        this.logger.debug(
          "Notifying to",
          username,
          "that",
          user.username,
          "has joined the chat!"
        );
        socket.send(serialize(outMessage), errCb);
      }
    });
  }

  /**
   * @description notify to all clients (except user's one) that a certain user is now online/offline
   * @param {User} user
   */

  private dispatchUserOnline(user: User) {
    this.logger.info(
      "Notifying clients that user",
      user.username,
      "is now",
      user.online ? "online" : "offline"
    );
    const errCb = (err: Error | undefined) => {
      if (err) {
        this.logger.error("Could not send message:", err);
      }
    };
    // Serialize message
    const outMessage: WsMessage = makeUserJoined(user);
    // Iterate over channels
    Array.from(this.channels.keys()).map((username) => {
      // If username is different from user.username, send the message
      const socket = this.channels.get(username);
      if (username !== user.username && socket) {
        this.logger.debug(
          "Notifying to",
          username,
          "that",
          user.username,
          "now it's",
          user.online ? "online" : "offline"
        );
        socket.send(serialize(outMessage), errCb);
      }
    });
  }
}
