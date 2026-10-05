---
name: api-error-handling
description: Platform rules for handling errors from upstream APIs. Use when writing code that calls another service and must report or wrap failures.
---

# API error handling

- Every error includes the **operation** name, the **upstream HTTP status** and the **correlation id** (from the `X-Correlation-Id` response header).
- Wrap unknown errors in a typed error and keep the original as `cause`.
- Never swallow errors: no empty `catch`, no `catch { return undefined }`.

```ts
export class UpstreamError extends Error {
  constructor(
    readonly operation: string,
    readonly status: number | undefined,
    readonly correlationId: string | undefined,
    options?: { cause?: unknown },
  ) {
    super(`${operation} failed (status=${status}, correlationId=${correlationId})`, options);
    this.name = 'UpstreamError';
  }
}

try {
  res = await fetch(url);
} catch (cause) {
  throw new UpstreamError('createRefund', undefined, undefined, { cause });
}
```
