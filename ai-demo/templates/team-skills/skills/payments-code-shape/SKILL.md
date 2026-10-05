---
name: payments-code-shape
description: Payments team code conventions for TypeScript. Use when writing or changing any non-test source code in a payments service.
---

# Payments code shape

- Small, pure functions. Isolate side effects at the edges.
- Explicit, typed error classes that carry context (operation, ids). No bare `throw new Error('failed')`.
- No default exports. Named exports only.
- Dependencies are injected: pass clients (HTTP, clock, id generator) in as parameters, never import a global client.
- Explicit return types on every function.

```ts
export class RefundRejectedError extends Error {
  constructor(
    readonly paymentId: string,
    readonly reason: string,
    options?: { cause?: unknown },
  ) {
    super(`Refund rejected for ${paymentId}: ${reason}`, options);
    this.name = 'RefundRejectedError';
  }
}

export interface GatewayClient {
  post(path: string, body: unknown, headers: Record<string, string>): Promise<Response>;
}

export async function issueRefund(
  client: GatewayClient,
  request: RefundRequest,
): Promise<RefundResult> {
  // ...
}
```
