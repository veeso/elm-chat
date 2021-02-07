/**
 * @author Christian Visintin <christian.visintin1997@gmail.com>
 * @version 0.1.0
 * @license "The Unlicense"
 */

// Getopts
import getopts from "getopts";
// Process
import process from "process";

// Logger
import getLogger, { configureLogger } from "./js/lib/utils/logger";
// Express
import HttpService from "./js/services/httpService";

// Const
const version = "0.1.0";

// @! Entry point

// Get opts
const progName = process.argv[1];
const cliOptions = getopts(process.argv.slice(2), {
  alias: {
    assetsDir: "d",
    loglevel: "l",
    port: "p",
    help: "h",
  },
  default: {
    loglevel: "INFO",
    port: 3000,
  },
});

//@! Handle options
if (cliOptions.help || !cliOptions.assetsDir) {
  console.log(progName);
  console.log("Usage:");
  console.log("\t-d\t<assets_dir>\tSet directory path where dynamic assets will be stored");
  console.log(
    "\t-l\t<log level>\tSet log level (OFF, FATAL, ERROR, WARN, INFO, DEBUG)"
  );
  console.log("\t-p\t<port>\t\tSet express port");
  console.log("\t-h\t\t\tShow this page");
  process.exit(255);
}

// Setup logger
configureLogger({
  appenders: {
    stdout: { type: "console" },
    // file: { type: "file", filename: logfile },
  },
  categories: { default: { appenders: ["stdout"], level: cliOptions.loglevel } },
});

const logger = getLogger("chat-server");

logger.info("chat-server version", version);
logger.info("CLI options parsed!");
logger.debug("Express port:", cliOptions.port);
logger.debug("Assets dir", cliOptions.assetsDir);

let httpService: HttpService | null = null;

// Setup on exit

const atExit = () => {
  logger.info("Terminating chat-server...");
  // stop services
  if (httpService) {
    logger.debug("Stopping http service...");
    httpService.stop(() => {
      logger.debug("http service stopped!");
      httpService = null;
    });
  }
  logger.info("chat-server stopped!");
};

process.on("exit", atExit.bind(null));
process.on("SIGINT", atExit.bind(null));
process.on("SIGTERM", atExit.bind(null));
// Handle errors
process.on("uncaughtException", (err: Error) => {
  logger.fatal("Uncaught Exception:", err);
  process.abort();
});
process.on("unhandledRejection", (err: any) => {
  logger.fatal("Uncaught Rejection:", err);
  process.abort();
});

// Start express!
httpService = new HttpService(cliOptions.port, cliOptions.assetsDir);
logger.info("chat-server started!");
