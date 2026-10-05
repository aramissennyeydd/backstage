---
name: commenting-standards
description: Organization-wide commenting rules. Use whenever writing or editing TypeScript or JavaScript source so comments, TSDoc and TODOs follow company standards.
---

# Commenting standards

1. Comments explain **why**, never **what**. If a comment restates the code, delete it.
2. Every exported symbol (function, class, type, constant) has a TSDoc comment.
3. Never leave commented-out code. Delete it; git remembers.
4. Every TODO references a ticket: `// TODO(PAY-123): ...`. No bare TODOs.

```ts
// Bad
// loop over items
for (const item of items) {}

// Good: the gateway rejects batches over 100 items, so chunk first.
const chunks = chunk(items, 100);

/** Returns the refundable amount in minor units. */
export function refundable(captured: number, refunded: number): number {
  return captured - refunded;
}
```
