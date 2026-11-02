# Payments Gateway runbook

Owned by the `gateway-platform` team. The contract is in the `payments-gateway` API entity.

## Rate limits

- Each caller gets **20 requests per second**. Above that the gateway answers `429`.
- `Retry-After` is in **seconds**, not milliseconds.

## Retries

- Retry only `429` and `503`.
- Make at most **4 attempts** in total, with exponential backoff and jitter.
- Never retry other `4xx` responses.

## Required headers

- `Idempotency-Key`: a UUID v4, generated once per refund and reused on every retry.
  The gateway keeps keys for a **24 hour** idempotency window.
- `X-Gateway-Caller`: the calling service name. Payments sends `payments-service`.
  Requests without it are rejected with `400`.

## Who to ask

Ask `gateway-platform` in `#gateway-platform` on Slack, or at `gateway-platform@acme-demo.example`.
The team's contact details are on the `gateway-platform` Group in Backstage.
