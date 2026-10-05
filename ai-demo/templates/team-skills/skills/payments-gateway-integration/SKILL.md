---
name: payments-gateway-integration
description: How to call the internal Payments Gateway API. Use when code issues refunds or otherwise calls https://payments-gateway.internal/v2.
---

# Payments Gateway integration

Base URL: `https://payments-gateway.internal/v2`

**Refund:** `POST /refunds` with body `{ paymentId, amountMinor, currency, reason }`.

Required headers:
- `Authorization: Bearer <service token>`
- `Idempotency-Key: <uuid v4>` generated once per logical operation and **reused on every retry**.

Rules:
- Retry only 429 and 503, with exponential backoff plus jitter, max 3 attempts total. Honor `Retry-After` when present.
- Never retry other 4xx responses.
- Never log card numbers/PAN or full request bodies; log ids only.
- Map gateway error codes to typed errors: `REFUND_EXCEEDS_CAPTURE` -> `RefundExceedsCaptureError`, `PAYMENT_NOT_FOUND` -> `PaymentNotFoundError`.
- Amounts are integers in **minor units** only (cents), never floats.

```ts
const idempotencyKey = randomUUID(); // once, outside the retry loop
for (let attempt = 1; attempt <= 3; attempt++) {
  const res = await fetch(`${BASE}/refunds`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Idempotency-Key': idempotencyKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ paymentId, amountMinor, currency, reason }),
  });
  if (res.ok) return res.json();
  if (![429, 503].includes(res.status) || attempt === 3) break;
  await sleep(backoffWithJitter(attempt, res.headers.get('Retry-After')));
}
```

See also `api-error-handling` for how to shape the errors.
