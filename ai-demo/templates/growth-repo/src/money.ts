export type Currency = 'USD' | 'EUR' | 'GBP';

export interface Money {
  amountMinor: number;
  currency: Currency;
}

export function add(a: Money, b: Money): Money {
  return { amountMinor: a.amountMinor + b.amountMinor, currency: a.currency };
}
