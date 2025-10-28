import { HttpException, InternalServerErrorException } from '@nestjs/common';
import { AxiosError, AxiosResponse, isAxiosError } from 'axios';
import { firstValueFrom, Observable } from 'rxjs';
import { catchError } from 'rxjs/operators'; // Import catchError from rxjs/operators

/**
 * Handles errors from an external HTTP request Observable, translating
 * Axios errors into NestJS HttpExceptions with the correct status code.
 *
 * @param request The Observable representing the HTTP request (e.g., from HttpService).
 * @returns A Promise resolving with the response data, or throwing an HttpException on error.
 */
export async function handleExternalHttpRequest<T = unknown>(
  request: Observable<AxiosResponse<T>>
): Promise<AxiosResponse<T>> {
  try {
    const response = await firstValueFrom(
      request.pipe(
        catchError((error: AxiosError | unknown) => {
          if (isAxiosError(error) && error.response) {
            console.error(
              `External API request failed [${error.response.status}] to ${error.config?.method?.toUpperCase()} ${error.config?.url}:`,
              error.response.data
            );

            // Throw a NestJS HttpException using the external status code and data.
            throw new HttpException(
              error.response.data || `External service error with status ${error.response.status}`,
              error.response.status
            );
          } else {
            console.error(
              'An unexpected error occurred during external API call',
              error instanceof Error ? error.message : error
            );

            // Throw a generic InternalServerErrorException for other errors.
            throw new InternalServerErrorException(
              'An unexpected error occurred while communicating with an external service'
            );
          }
        })
      )
    );

    return response;
  } catch (error) {
    // If the error is already an HttpException re-throw it so NestJS's global exception filter can handle it.
    if (error instanceof HttpException) {
      throw error;
    }

    // This part should ideally not be reached if catchError handles all potential errors but added as a fallback:
    console.error('An unhandled error propagated to the final catch block:', error);
    throw new InternalServerErrorException('An unexpected error occurred during external service interaction');
  }
}
