/**
 * @author Christian Visintin <christian.visintin1997@gmail.com>
 * @version 0.1.0
 * @license "The Unlicense"
 */

export default interface Message {
  id: string;
  from: string;
  to: string;
  datetime: Date;
  body: string;
  recv: boolean;
  read: boolean;
}
