/**
 * @author Christian Visintin <christian.visintin1997@gmail.com>
 * @version 0.1.0
 * @license "The Unlicense"
 */

// Express
import express from "express";
import bodyParser from "body-parser";
import cookieParser from "cookie-parser";
import jwt from "express-jwt";
import morgan from "morgan"; // Net logging
import helmet from "helmet"; // secure express
import multer from "multer"; // handle multipart
import http from "http";
import jsonwebtoken from "jsonwebtoken";
import { unlink, unlinkSync } from "fs";
// Misc
import { Logger } from "log4js";
// Lib
import { sha512 } from "../lib/utils/utils";
import Storage from "../lib/data/storage";
import getLogger from "../lib/utils/logger";
import MessageService from "./messageService";

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
          this.logger.debug(
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
            res.cookie("user", token);
            res.send({ jwt: token });
            // Set user online
            this.store.connectUser(username);
          } else {
            this.logger.debug(
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
              if (!avatar) {
                this.logger.debug(username, "didn't provide any avatar");
              }
              this.logger.debug("User", username, "has avatar at", avatar);
              try {
                this.store.registerUser(username, avatar, password);
                this.logger.info("Registered new user", username);
                // Sign in
                const token = jsonwebtoken.sign({ username }, this.jwtSecret, {
                  algorithm: "HS256",
                });
                res.cookie("user", token);
                res.send({ jwt: token });
                // Set user online
                this.store.connectUser(username);
              } catch (err) {
                // Remove file if set
                if (avatar) {
                  unlink(avatar, () => {
                    this.logger.debug("Removed bad avatar at", avatar);
                  });
                }
                this.logger.error("Could not register user:", err);
                res.sendStatus(500);
              }
            } else {
              this.logger.debug(
                "Tried to register already existing user:",
                username
              );
              res.sendStatus(409);
            }
          } else {
            this.logger.debug("Received sign up without credentials");
            res.sendStatus(400);
          }
        } else {
          this.logger.debug("Received sign up without 'data'");
          res.sendStatus(400);
        }
      }
    );
    this.service.all("/api/auth/signUp", (req, res) => {
      res.sendStatus(405);
    });

    // Sign out

    this.service.post("/api/auth/signOut", (req, res) => {
      // Delete coookie
      res.cookie("user", null);
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
          res.send({});
        } catch (err) {
          this.logger.debug("JWT has expired for user");
          res.cookie("user", null);
          res.sendStatus(401);
        }
      } else {
        res.sendStatus(401);
      }
    });
    this.service.all("/api/auth/authed", (req, res) => {
      res.sendStatus(405);
    });

    // Users

    this.service.get("/api/chat/users", (req, res) => {
      const users = this.store.getUsers();
      // Serialize
      const payload: Array<any> = new Array();
      for (const user of users) {
        let avatar: string | null = user.avatar;
        if (avatar) {
          // Process avatar...
          const avatarTokens = avatar.split("/");
          const filename = avatarTokens[avatarTokens.length - 1];
          avatar = "/assets/avatar/" + filename;
        }
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
        res.sendStatus(400);
      }
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
