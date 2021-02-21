/**
 * @author Christian Visintin <christian.visintin1997@gmail.com>
 * @version 0.1.0
 * @license "The Unlicense"
 */

// Express
import express from "express";
import bodyParser from "body-parser";
import cookieParser from "cookie-parser";
import jimp from "jimp";
import jsonwebtoken from "jsonwebtoken";
import jwt from "express-jwt";
import helmet from "helmet"; // secure express
import http from "http";
import morgan from "morgan"; // Net logging
import multer from "multer"; // handle multipart
import { unlink, unlinkSync } from "fs";
// Misc
import { Logger } from "log4js";
// Lib
import { sha512 } from "../lib/utils/utils";
import AuthObject from "../lib/data/authobject";
import Storage from "../lib/data/storage";
import getLogger from "../lib/utils/logger";
import MessageService from "./messageService";
import Message from "../lib/data/message";
import Jimp from "jimp";

export default class HttpService {
  private service: express.Express;
  private server: http.Server;
  private chat: MessageService;
  private avatarUploadHnd: ReturnType<typeof multer>;
  private logger: Logger;
  private jwtSecret: string;
  private store: Storage;

  /**
   *
   * @param {number} port
   * @param {string} assetsDir
   */
  constructor(port: number, assetsDir: string) {
    this.logger = getLogger("httpService");
    // Configure express
    this.service = express();
    this.service.use(bodyParser.json({ limit: "50mb" }));
    // Configure Morgan
    this.service.use(morgan("dev"));
    // Helmet
    this.service.use(helmet());
    // Cookie parser
    this.service.use(cookieParser());
    // Multer
    this.avatarUploadHnd = multer({ dest: assetsDir + "/avatar/" });
    // Make jwt secret
    const characters =
      "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_";
    let secret = "";
    for (let i = 0; i < 32; i++) {
      secret += characters.charAt(
        Math.floor(Math.random() * characters.length)
      );
    }
    this.jwtSecret = secret;
    // Jwt options
    const jwtOptions: jwt.Options = {
      secret: this.jwtSecret,
      algorithms: ["HS256"],
      requestProperty: "user",
      getToken: (req) => {
        if (req.cookies.user) {
          return req.cookies.user;
        } else {
          return null;
        }
      },
    };
    this.service.use(
      jwt(jwtOptions).unless({
        path: ["/api/auth/signUp", "/api/auth/signIn", "/api/auth/authed"],
      })
    );
    // Make storage
    this.store = new Storage();
    // Start listening
    this.server = this.service.listen(port, () => {
      this.logger.info("Now listening on port", port);
    });
    // Start chat
    this.chat = new MessageService(this.store);
    // Setup express
    this.setup();
  }

  /**
   * @description stop http service
   * @param {Function | undefined} onStopped
   */

  public stop(onStopped: Function | undefined = undefined) {
    this.logger.debug("Stopping message service (chat)...");
    this.chat.stop(() => {
      this.logger.debug("Message service stopped!");
      this.server.close();
      // Clean assets...
      this.logger.debug("Cleaning assets");
      for (const u of this.store.getUsers()) {
        if (u.avatar) {
          try {
            unlinkSync(u.avatar);
            this.logger.debug("Removed avatar at", u.avatar);
          } catch (err) {
            this.logger.error("Could not remove avatar at", u.avatar);
          }
        }
      }
      this.logger.info("Assets cleaned");
      this.logger.info("service stopped!");
      if (onStopped) {
        onStopped();
      }
    });
  }

  private getAvatarUri(avatar: string | null): string | null {
    if (avatar) {
      // Process avatar...
      const avatarTokens = avatar.split("/");
      const filename = avatarTokens[avatarTokens.length - 1];
      return "/assets/avatar/" + filename;
    } else {
      return null;
    }
  }

  /**
   * @description process avatar image
   * @param {string} file
   * @param {Function} onErr
   * @param {Function} onSuccess
   */
  private processAvatar(file: string, onErr: Function, onSuccess: Function) {
    Jimp.read(file, (err, image) => {
      if (err) {
        onErr(err);
      } else {
        image
          .resize(256, 256)
          .quality(60)
          .write(file, (err) => {
            if (err) {
              onErr(err);
            } else {
              onSuccess();
            }
          });
      }
    });
  }

  // API Calls

  /**
   * @description setup express
   */

  private setup() {
    // API Requests

    // Sign in

    this.service.post("/api/auth/signIn", (req, res) => {
      if ("username" in req.body && "secret" in req.body) {
        const username = req.body["username"];
        // Convert password to SHA512
        const password = sha512(req.body["secret"]);
        // Check if user exists
        const checkUser = this.store.searchUser(username);
        if (!checkUser) {
          this.logger.error(
            "Tried to authenticate with username",
            username,
            "but doesn't exist"
          );
          res.sendStatus(401);
        } else {
          // Check password
          if (password === checkUser.secret) {
            // Create JWT and return OK
            this.logger.debug("User", username, "signed in!");
            const token = jsonwebtoken.sign({ username }, this.jwtSecret, {
              algorithm: "HS256",
            });
            res.cookie("user", token, { httpOnly: true });
            const authObject: AuthObject = {
              username: checkUser.username,
              avatar: this.getAvatarUri(checkUser.avatar),
            };
            res.send(authObject);
            // Set user online
            this.store.connectUser(username);
          } else {
            this.logger.error(
              "Tried to authenticate with username",
              username,
              "but password is wrong"
            );
            res.sendStatus(401);
          }
        }
      } else {
        res.sendStatus(400);
      }
    });
    this.service.all("/api/auth/signIn", (req, res) => {
      this.logger.error("Bad method for 'signIn'; expected POST");
      res.sendStatus(405);
    });

    // Sign up

    this.service.post(
      "/api/auth/signUp",
      this.avatarUploadHnd.single("avatar"),
      (req, res) => {
        // Check other parameters
        if (req.body.data) {
          const data = JSON.parse(req.body.data);
          if (data.username && data.secret) {
            const username = data.username;
            const password = sha512(data.secret);
            // Check if user already exists
            if (!this.store.searchUser(username)) {
              this.logger.debug(
                "Ok,",
                username,
                "is not used; we can register it"
              );
              // Register new user
              const avatar = req.file
                ? req.file.destination + "/" + req.file.filename
                : null;
              // Make signup callback
              const signupCallback = () => {
                try {
                  const newUser = this.store.registerUser(
                    username,
                    avatar,
                    password
                  );
                  this.logger.info("Registered new user", username);
                  // Sign in
                  const token = jsonwebtoken.sign(
                    { username },
                    this.jwtSecret,
                    {
                      algorithm: "HS256",
                    }
                  );
                  res.cookie("user", token, { httpOnly: true });
                  const authObject: AuthObject = {
                    username: newUser.username,
                    avatar: this.getAvatarUri(newUser.avatar),
                  };
                  res.send(authObject);
                  // Set user online
                  this.store.connectUser(username);
                } catch (err) {
                  // Remove file if set
                  if (avatar) {
                    unlink(avatar, () => {
                      this.logger.info("Removed bad avatar at", avatar);
                    });
                  }
                  this.logger.error("Could not register user:", err);
                  res.sendStatus(500);
                }
              };
              if (!avatar) {
                this.logger.debug(username, "didn't provide any avatar");
                // Call callback
                signupCallback();
              } else {
                // Process image
                this.logger.debug("User", username, "has avatar at", avatar);
                this.processAvatar(
                  avatar,
                  (err: any) => {
                    this.logger.error("Could not process avatar image", err);
                    // Bad request
                    res.sendStatus(401);
                  },
                  () => {
                    // Call callback
                    signupCallback();
                  }
                );
              }
            } else {
              this.logger.error(
                "Tried to register already existing user:",
                username
              );
              res.sendStatus(409);
            }
          } else {
            this.logger.error("Received sign up without credentials");
            res.sendStatus(400);
          }
        } else {
          this.logger.error("Received sign up without 'data'");
          res.sendStatus(400);
        }
      }
    );
    this.service.all("/api/auth/signUp", (req, res) => {
      this.logger.error("Bad method for 'signUp'; expected POST");
      res.sendStatus(405);
    });

    // Sign out

    this.service.post("/api/auth/signOut", (req, res) => {
      // Delete coookie
      res.cookie("user", null, { httpOnly: true });
      // Set user online
      const username = req.user.username;
      const user = this.store.searchUser(username);
      if (user) {
        this.store.disconnectUser(username);
        // Delete cookie
        res.send({});
        this.logger.debug("User", username, "signed out");
      } else {
        res.sendStatus(404); // User not found
      }
    });
    this.service.all("/api/auth/signOut", (req, res) => {
      this.logger.error("Bad method for 'signOut'; expected POST");
      res.sendStatus(405);
    });

    // Authed

    this.service.get("/api/auth/authed", (req, res) => {
      if (req.cookies.user) {
        // verify the cookie
        try {
          jsonwebtoken.verify(req.cookies.user, this.jwtSecret, {
            algorithms: ["HS256"],
          });
          const user = jsonwebtoken.decode(req.cookies.user);
          if (typeof user === "string" || user === null) {
            // bad jwt syntax
            this.logger.error("JWT has bad syntax");
            res.cookie("user", null);
            res.sendStatus(401);
          } else {
            // Use must exist
            const checkUser = this.store.searchUser(user.username);
            if (!checkUser) {
              this.logger.error(
                "Tried to authenticate with username",
                user.username,
                "but doesn't exist"
              );
              res.sendStatus(401);
            } else {
              const authObject: AuthObject = {
                username: checkUser.username,
                avatar: this.getAvatarUri(checkUser.avatar),
              };
              res.send(authObject);
            }
          }
        } catch (err) {
          this.logger.error("JWT has expired for user");
          res.cookie("user", null);
          res.sendStatus(401);
        }
      } else {
        res.sendStatus(401);
      }
    });
    this.service.all("/api/auth/authed", (req, res) => {
      this.logger.error("Bad method for 'authed'; expected GET");
      res.sendStatus(405);
    });

    // Users

    this.service.get("/api/chat/users", (req, res) => {
      const users = this.store.getUsers();
      const username = req.user.username;
      // Serialize
      const payload: Array<any> = new Array();
      for (const user of users) {
        // Don't return current user
        if (user.username === username) {
          continue;
        }
        const avatar: string | null = this.getAvatarUri(user.avatar);
        payload.push({
          username: user.username,
          avatar: avatar,
          lastActivity: user.lastActivity.toISOString(),
          online: user.online,
        });
      }
      res.send(payload);
    });
    this.service.all("/api/chat/users", (req, res) => {
      this.logger.error("Bad method for 'users'; expected GET");
      res.sendStatus(405);
    });

    // History

    this.service.get("/api/chat/history/:username", (req, res) => {
      const client = req.user.username;
      const other = req.params.username;
      if (other) {
        // Get history for sender and recipient
        try {
          const conversation = this.store.getConversation(client, other);
          res.send(conversation);
        } catch (err) {
          this.logger.error(
            "Could not fetch history for",
            client,
            "and",
            other,
            err
          );
          res.sendStatus(404);
        }
      } else {
        this.logger.error("Missing 'username' in history request");
        res.sendStatus(400);
      }
    });
    this.service.all("/api/chat/history", (req, res) => {
      this.logger.error("Bad method for 'signIn'; expected POST");
      res.sendStatus(405);
    });

    // Send message

    this.service.post("/api/chat/send/:recipient", (req, res) => {
      const sender = req.user.username;
      const recipient = req.params.recipient;
      if (recipient) {
        // If recipient and sender are equal, return bad request
        if (recipient === sender) {
          this.logger.error(
            sender,
            "tried to send a message to himself! What a nice person :D"
          );
          res.sendStatus(400);
        } else {
          // Check body
          const text = req.body["body"];
          if (text) {
            // Push message
            try {
              const message: Message = this.store.pushMessage(
                sender,
                recipient,
                text
              );
              // Make message
              this.logger.info(
                sender,
                "sent a new message to",
                recipient + ": '" + text + "'"
              );
              res.send(message);
            } catch (err) {
              this.logger.error("Could not send message:", err);
              res.sendStatus(404);
            }
          } else {
            this.logger.error("Missing 'body' in chat send request");
            res.sendStatus(400);
          }
        }
      } else {
        this.logger.error("Missing 'recipient' in chat send request");
        res.sendStatus(400);
      }
    });
    this.service.all("/api/chat/send", (req, res) => {
      this.logger.error("Bad method for 'send'; expected POST");
      res.sendStatus(405);
    });

    // Set read

    this.service.post("/api/chat/setread/:id", (req, res) => {
      const messageId = req.params.id;
      if (messageId) {
        try {
          this.store.markMessageAsRead(messageId);
          this.logger.debug("Marked message", messageId, "as read");
          res.send({});
        } catch (err) {
          this.logger.error("Could not set message", messageId, "as read", err);
          res.sendStatus(404);
        }
      } else {
        res.sendStatus(400);
      }
    });
    this.service.all("/api/chat/setread/", (req, res) => {
      this.logger.error("Bad method for 'setRead'; expected POST");
      res.sendStatus(405);
    });

    // Error handler

    this.service.use((err: any, req: any, res: any, next: any) => {
      if (err.name === "UnauthorizedError") {
        res.sendStatus(401);
      }
    });

    // WebSockets Handler

    this.server.on("upgrade", (req, socket, head) => {
      // Let's access the username
      const username = req.user.username;
      this.logger.debug(username, "has started a websockets session");
      this.chat.accept(req, socket, head, username);
    });

    this.logger.info("HTTP Service started!");
  }
}
