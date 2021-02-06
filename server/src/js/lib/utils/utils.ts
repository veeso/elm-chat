/**
 * @author Christian Visintin <christian.visintin1997@gmail.com>
 * @version 0.1.0
 * @license "The Unlicense"
 */

import { createHash } from "crypto";

/**
 * @description make a sha512 from string
 * @param {string} str
 * @returns {string}
 */

export function sha512(str: string): string {
  const hash = createHash("sha512");
  hash.update(str);
  return hash.digest("hex");
}
