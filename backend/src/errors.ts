// Standardized API error. Serialized by the global error handler as
// { error: { code, message } } with the given HTTP status.
export class ApiError extends Error {
  statusCode: number;
  code: string;

  constructor(statusCode: number, code: string, message: string) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
  }
}

export const Errors = {
  unauthorized: (msg = 'Missing or invalid token') =>
    new ApiError(401, 'UNAUTHORIZED', msg),
  invalidCredentials: (msg = 'Invalid email or password') =>
    new ApiError(401, 'INVALID_CREDENTIALS', msg),
  emailTaken: (msg = 'Email already registered') =>
    new ApiError(409, 'EMAIL_TAKEN', msg),
  notFound: (msg = 'Resource not found') => new ApiError(404, 'NOT_FOUND', msg),
  validation: (msg: string) => new ApiError(400, 'VALIDATION_ERROR', msg),
  quotaExceeded: (msg = 'Scan quota exceeded') =>
    new ApiError(402, 'QUOTA_EXCEEDED', msg),
  badRequest: (msg: string) => new ApiError(400, 'BAD_REQUEST', msg),
};
