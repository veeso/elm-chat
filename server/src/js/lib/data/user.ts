/**
 * @author Christian Visintin <christian.visintin1997@gmail.com>
 * @version 0.1.0
 * @license "The Unlicense"
 */

export default interface User {
  username: string;
  avatar: string | null;
  lastActivity: Date;
  online: boolean;
  secret: string;
}
