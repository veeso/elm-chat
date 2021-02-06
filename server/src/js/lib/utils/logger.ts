/**
 * @author Christian Visintin <christian.visintin1997@gmail.com>
 * @version 0.1.0
 * @license "The Unlicense"
 */

//Logger
import log4js, { Configuration, Logger } from "log4js";

/**
 * @description configure log4js
 * @param {Configuration} configuration 
 */

export function configureLogger(configuration: Configuration) {
  log4js.configure(configuration);
}

/**
 * @description get logger with global configuration
 * @param {string} name 
 * @returns {Logger}
 */

export default function getLogger(name: string): Logger {
  return log4js.getLogger(name);
}
