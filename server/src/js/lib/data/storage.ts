/**
 * @author Christian Visintin <christian.visintin1997@gmail.com>
 * @version 0.1.0
 * @license "The Unlicense"
 */

import Message from "./message";
import User from "./user";

// Subscription callbacks
export declare type OnMessageReceived = (message: Message) => void;
export declare type OnMessageRead = (message: Message) => void;

export default class Storage {
  private users: Array<User>;
  private messages: Array<Message>;
  // Subscriptions
  private recvSubscriptions: Array<OnMessageReceived>;
  private readSubscriptions: Array<OnMessageRead>;

  constructor() {
    // data structs
    this.users = new Array();
    this.messages = new Array();
    // subscriptions
    this.recvSubscriptions = new Array();
    this.readSubscriptions = new Array();
  }

  /**
   * @description subscribe to received event
   * @param {OnMessageReceived} cb
   */

  public subscribeReceived(cb: OnMessageReceived) {
    this.recvSubscriptions.push(cb);
  }

  /**
   * @description subscribe to read event
   * @param {OnMessageRead} cb
   */

  public subscribeRead(cb: OnMessageRead) {
    this.readSubscriptions.push(cb);
  }

  // User related methods

  /**
   * @description returns all users in storage
   * @param {boolean | undefined} online; if set return only online or offline users
   * @returns {Array<User>}
   */
  public getUsers(online: boolean | undefined = undefined): Array<User> {
    let users = this.users;
    // Filter
    if (online !== undefined) {
      // Check if online or not
      users = users.filter((u) => u.online === online);
    }
    return users;
  }

  /**
   * @description search for a user in the storage
   * @param {string} username
   * @returns {User | null}
   */
  public searchUser(username: string): User | null {
    for (const user of this.users) {
      if (user.username === username) {
        return user;
      }
    }
    return null;
  }

  /**
   * @description register a new user
   * @param {string} username
   * @param {string | null} avatar
   * @param {string} secret
   * @throws {Error} if user already exists
   */
  public registerUser(username: string, avatar: string | null, secret: string) {
    if (this.searchUser(username) !== null) {
      throw new Error("User already exists");
    }
    this.users.push({
      username: username,
      avatar: avatar,
      lastActivity: new Date(),
      online: true,
      secret: secret,
    });
  }

  /**
   * @description mark user as online
   * @param {string} username
   * @throws {Error} if username doesn't exist
   */
  public connectUser(username: string) {
    const user = this.searchUser(username);
    if (!user) {
      throw new Error("User doesn't exist");
    }
    user.online = true;
    // Update last activity
    user.lastActivity = new Date();
  }

  /**
   * @description mark user as offline
   * @param {string} username
   * @throws {Error} if username doesn't exist
   */
  public disconnectUser(username: string) {
    const user = this.searchUser(username);
    if (!user) {
      throw new Error("User doesn't exist");
    }
    user.online = false;
    // Update last activity
    user.lastActivity = new Date();
  }

  // Message API

  /**
   * @description create a new message
   * @param {string} id
   * @param {string} body
   * @param {string} from
   * @param {string} to
   * @param {Date} datetime
   */

  public pushMessage(message: Message) {
    const sender: User | null = this.searchUser(message.from);
    const recipient: User | null = this.searchUser(message.to);
    if (!sender) {
      throw new Error("User '" + message.from + "' doesn't exist");
    }
    if (!recipient) {
      throw new Error("User '" + message.to + "' doesn't exist");
    }
    this.messages.push(message);
    // Update last activity
    sender.lastActivity = new Date();
  }

  /**
   * @description returns all the messages exchanged between `username` and `other`
   * @param {string} username
   * @param {string} other
   * @returns {Array<Message>}
   * @throws {Error}
   */
  public getConversation(username: string, other: string): Array<Message> {
    // Search for inolved users
    const user1 = this.searchUser(username);
    if (!user1) {
      throw new Error(username + " doesn't exist");
    }
    const user2 = this.searchUser(other);
    if (!user2) {
      throw new Error(other + " doesn't exist");
    }
    // Iterate messages
    let conversation = [];
    for (const message of this.messages) {
      // Check if both users are involved
      if (
        message.from === user1.username ||
        message.to === user2.username ||
        (message.from === user2.username && message.to === user1.username)
      ) {
        // Also mark the message as received
        const recv: boolean = message.recv;
        if (!recv) {
          message.recv = true;
          // Notify
          this.notifyRecvSubscriber(message);
        }
        conversation.push(message);
      }
    }
    // Sort conversation by date
    conversation.sort((a, b) => b.datetime.getTime() - a.datetime.getTime());
    return conversation;
  }

  /**
   * @description mark a message as read
   * @param {string} id
   * @throws {Exception}
   */
  public markMessageAsRead(id: string) {
    for (const message of this.messages) {
      if (message.id === id) {
        const read: boolean = message.read;
        if (!read) {
          message.read = true;
          // Notify
          this.notifyReadSubscriber(message);
        }
        return;
      }
    }
    throw new Error("Could not find message");
  }

  /**
   * @description mark a message as received
   * @param {string} id
   * @throws {Exception}
   */
  public markMessageAsReceived(id: string) {
    for (const message of this.messages) {
      if (message.id === id) {
        const recv: boolean = message.recv;
        if (!recv) {
          message.recv = true;
          // Notify
          this.notifyRecvSubscriber(message);
        }
        return;
      }
    }
    throw new Error("Could not find message");
  }

  // Subscriptions

  /**
   * @description notify all read event subscriber
   * @param {Message} msg
   */
  private notifyReadSubscriber(msg: Message) {
    for (const cb of this.readSubscriptions) {
      cb(msg);
    }
  }

  /**
   * @description notify all received event subscriber
   * @param {Message} msg
   */
  private notifyRecvSubscriber(msg: Message) {
    for (const cb of this.recvSubscriptions) {
      cb(msg);
    }
  }
}
