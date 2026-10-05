---
name: payments-testing
description: Payments team testing conventions. Use when writing or editing tests in a payments service.
---

# Payments testing

- Fewer, thorough tests with multiple assertions beats many tiny tests.
- Build test data with fluent builders: `aRefundRequest().withAmount(500).build()`. Put builders in `src/testing/`.
- Mock HTTP only at the boundary (a fake `GatewayClient` / fetch). Never mock your own modules.
- No snapshot tests.
- Test names describe behavior: `retries a 503 with the same idempotency key and then succeeds`.

```ts
describe('issueRefund', () => {
  it('retries a 503 with the same idempotency key and then succeeds', async () => {
    const client = fakeGateway([503, 200]);
    const result = await issueRefund(client, aRefundRequest().withAmount(500).build());

    expect(client.calls).toHaveLength(2);
    expect(client.calls[0].headers['Idempotency-Key']).toBe(
      client.calls[1].headers['Idempotency-Key'],
    );
    expect(result.status).toBe('succeeded');
  });
});
```
