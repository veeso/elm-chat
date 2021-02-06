export interface JwtUser {
  username: string;
}

declare global {
  namespace Express {
    export interface Request {
      user: JwtUser;
    }
  }
}
