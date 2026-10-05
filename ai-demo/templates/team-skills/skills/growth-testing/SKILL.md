---
name: growth-testing
description: Growth team testing conventions. Use when writing or editing tests in a growth service.
---

# Growth testing

- Table-driven tests with `it.each`.
- Shared fixture objects at the top of the file; reuse them across cases.
- Exactly one assertion per case.
- Keep each case small and independent.

```ts
const validPayment = { id: 'pay_1', amountMinor: 1000, currency: 'USD' };

describe('refundable', () => {
  it.each([
    ['full amount', validPayment, 0, 1000],
    ['partially refunded', validPayment, 400, 600],
    ['fully refunded', validPayment, 1000, 0],
  ])('%s', (_name, payment, refunded, expected) => {
    expect(refundable(payment, refunded)).toBe(expected);
  });
});
```
