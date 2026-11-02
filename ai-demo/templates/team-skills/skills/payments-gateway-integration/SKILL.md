---
name: payments-gateway-integration
description: How to call the internal Payments Gateway API. Use when code issues refunds or otherwise calls the Payments Gateway.
---

# Payments Gateway integration

This skill holds our conventions. The gateway's facts (base URL, rate limits, retry policy, required
headers) live in Backstage and change, so never copy them from memory.

**Before writing gateway code**, use the Backstage MCP tools:
1. Fetch `api:default/payments-gateway` (`get-catalog-entity`) for the contract: base URL, paths, headers, error codes.
2. Search Backstage TechDocs (`query`, term "payments gateway rate limit retries") for the gateway runbook: rate limits, retry policy, caller header, idempotency window.
3. Cite both sources in a code comment next to the constants.
4. If something is unclear, the owner team's contact is on the owning Group (`group:default/gateway-platform`).

Conventions:
- Generate the `Idempotency-Key` (a random UUID) **once** per logical operation, outside the retry loop, and reuse it on every retry.
- Retry only the statuses and attempt count the runbook gives, with exponential backoff plus jitter. Honor `Retry-After` using the unit the runbook states.
- Never retry other 4xx responses.
- Never log card numbers/PAN or full request bodies; log ids only.
- Map gateway error codes from the contract to typed errors, for example `REFUND_EXCEEDS_CAPTURE` -> `RefundExceedsCaptureError`, `PAYMENT_NOT_FOUND` -> `PaymentNotFoundError`.
- Amounts are integers in **minor units** only (cents), never floats.
- Put the facts in named constants so they are easy to update.

```ts
// Source: Backstage api:default/payments-gateway and the gateway runbook (TechDocs).
const BASE_URL = '<from the API entity servers[0].url>';
const MAX_ATTEMPTS = 0; // from the runbook
const RETRYABLE = new Set<number>(); // from the runbook
const CALLER_HEADER = { 'X-Gateway-Caller': '<from the contract>' };

const idempotencyKey = randomUUID(); // once, outside the retry loop
for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
  const res = await fetch(`${BASE_URL}/refunds`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Idempotency-Key': idempotencyKey,
      'Content-Type': 'application/json',
      ...CALLER_HEADER,
    },
    body: JSON.stringify({ paymentId, amountMinor, currency, reason }),
  });
  if (res.ok) return res.json();
  if (!RETRYABLE.has(res.status) || attempt === MAX_ATTEMPTS) break;
  await sleep(backoffWithJitter(attempt, res.headers.get('Retry-After')));
}
```

See also `api-error-handling` for how to shape the errors.
