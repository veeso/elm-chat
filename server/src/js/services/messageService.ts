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
} from "../lib/data/ws";
import Message from "../lib/data/message";
import Storage from "../lib/data/storage";

export default class MessageService {
  private wsServer: WebSocket.Server;
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
    // Make logger
    this.logger = getLogger("messageService");
    // Start web sockets
    this.wsServer = new WebSocket.Server({ noServer: true });
    // Add listeners
    this.wsServer.on(
      "connection",
      (socket: WebSocket, _request: http.IncomingMessage, username: string) => {
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
    );
    this.logger.info("Message service started!");
  }

  /**
   * @description stop message service
   * @param {Function | undefined} onStopped
   */

  public stop(onStopped: Function | undefined = undefined) {
    this.logger.info("Stopping message service...");
    // Stop server
    this.wsServer.close();
    // Clear entries
    this.channels.clear();
    this.logger.info("Message service stopped!");
    if (onStopped) {
      onStopped();
    }
  }

  /**
   * @description accept a new websockets connection
   * @param req
   * @param socket
   * @param head
   * @param {string} client
   */

  public accept(req: any, socket: any, head: any, client: string) {
    this.logger.debug("Handling upgrade for", client);
    this.wsServer.handleUpgrade(req, socket, head, (ws) => {
      this.wsServer.emit("connection", ws, req, client);
      this.logger.debug("Emitted connection event for", client);
    });
  }

  /**
   * @description dispatch message to recipient; call also OnMessage callback
   * @param {string} client
   * @param {WebSocket} socket sender socket
   * @param {WebSocket.Data} message
   */

  private dispatchMessage(
    client: string,
    socket: WebSocket,
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
      this.logger.error("Could not send message:", err);
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
      this.logger.error("Could not send message:", err);
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
      message.to
    );
    socket.send(serialize(wsMessage), errCb);
    this.logger.info("Read notification dispatched to", message.to);
  }

  /**
   * @description dispatch a received message event to sender
   * @param {Message} message
   */

  private dispatchReceived(message: Message) {
    const errCb = (err: Error | undefined) => {
      this.logger.error("Could not send message:", err);
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
      message.to
    );
    socket.send(serialize(wsMessage), errCb);
    this.logger.info("Received notification dispatched to", message.to);
  }
}
