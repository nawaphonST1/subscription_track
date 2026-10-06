import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

import { captureException } from './sentry';

/**
 * Reports failed requests to Sentry and then rethrows, unchanged.
 *
 * Why an interceptor and not a Nest exception filter: the project already
 * registers a catch-all `HttpExceptionFilter` that shapes the error response,
 * and Nest hands an exception to exactly one filter. Adding a second global
 * filter would mean one of them silently stops running. An interceptor sits
 * earlier in the chain, so it can observe the error and pass it straight
 * through to the existing filter, which keeps producing the same response body
 * it always did.
 *
 * Known gap, accepted: guards run *before* interceptors, so an exception
 * thrown by JwtAuthGuard never reaches here. That is almost entirely 401s on
 * expired tokens — ordinary traffic, not something worth a Sentry event.
 */
@Injectable()
export class SentryErrorInterceptor implements NestInterceptor {
  intercept(
    _context: ExecutionContext,
    next: CallHandler,
  ): Observable<unknown> {
    return next.handle().pipe(
      catchError((error: unknown) => {
        if (shouldReport(error)) {
          captureException(error);
        }
        return throwError(() => error);
      }),
    );
  }
}

/**
 * Only server-side faults are worth an event. A 404 or a 400 from a validation
 * pipe is the API working correctly, and on a public endpoint a scanner would
 * otherwise generate thousands of them.
 */
function shouldReport(error: unknown): boolean {
  const status = (error as { getStatus?: () => number })?.getStatus;
  if (typeof status === 'function') {
    try {
      return status.call(error) >= 500;
    } catch {
      return true;
    }
  }
  // Anything that is not an HttpException is an unhandled fault by definition.
  return true;
}
