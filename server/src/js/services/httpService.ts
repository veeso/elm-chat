/**
 * @author Christian Visintin <christian.visintin1997@gmail.com>
 * @version 0.1.0
 * @license "The Unlicense"
 */

// Express
import express from "express";
import bodyParser from "body-parser";
import jwt from "express-jwt";
import morgan from "morgan"; // Net logging
import helmet from "helmet"; // secure express
import multer from "multer"; // handle multipart
import http from "http";
import jsonwebtoken from "jsonwebtoken";
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
    const jwtOptions = {
      secret: this.jwtSecret,
      algorithms: ["HS256"],
      requestProperty: "user",
    };
    this.service.use(
      jwt(jwtOptions).unless({ path: ["/api/auth/signUp", "/api/auth/signIn"] })
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

    this.service.post(
      "/api/auth/signUp",
      this.avatarUploadHnd.single("avatar"),
      (req, res) => {
        // Check other parameters
        if (req.body.username && req.body.secret) {
          const username = req.body.username;
          const password = sha512(req.body.password);
          // Check if user already exists
          if (!this.store.searchUser(username)) {
            // Register new user
            const avatar = req.file ? req.file.destination : null;
            try {
              this.store.registerUser(username, avatar, password);
              this.logger.info("Registered new user", username);
              // Sign in
              const token = jsonwebtoken.sign({ username }, this.jwtSecret, {
                algorithm: "HS256",
              });
              res.send({ jwt: token });
              // Set user online
              this.store.connectUser(username);
            } catch (err) {
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
          res.sendStatus(400);
        }
      }
    );

    this.service.post("/api/auth/signOut", (req, res) => {
      this.logger.debug("User signed out");
      res.sendStatus(200);
    });

    this.service.get("/api/chat/users", (req, res) => {
      const users = this.store.getUsers();
      // Serialize
      const payload: Array<any> = new Array();
      for (const user of users) {
        payload.push({
          username: user.username,
          avatar: user.avatar,
          lastActivity: user.lastActivity.toISOString(),
          online: user.online,
        });
      }
      res.send(payload);
    });

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
          res.sendStatus(500);
        }
      } else {
        res.sendStatus(400);
      }
    });

    this.service.post("/api/chat/setread/:id", (req, res) => {
      const messageId = req.params.id;
      if (messageId) {
        try {
          this.store.markMessageAsRead(messageId);
          this.logger.debug("Marked message", messageId, "as read");
          res.sendStatus(200);
        } catch (err) {
          this.logger.error("Could not set message", messageId, "as read", err);
          res.sendStatus(500);
        }
      } else {
        res.sendStatus(400);
      }
    });

    // WebSockets Handler

    this.server.on("upgrade", (req, socket, head) => {
      // Let's access the username
      const username = req.user.username;
      this.logger.debug(username, "has started a websockets session");
      this.chat.accept(req, socket, head, username);
    });
  }
}

/*
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const tmpdir = process.cwd() + '/tmp/';
    console.log(tmpdir);
    cb(null, tmpdir);
  },
  filename: (req, file, cb) => {
    const date = new Date();
    //Build up filename
    const filename = file.fieldname + '-' + date.toISOString() + '-' + uuidv4() + '.jpg';
    cb(null, filename);
  }
});

*/
