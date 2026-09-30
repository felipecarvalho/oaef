import { describe, it, expect } from 'vitest';
import { add, multiply } from '../src/calculator.js';

describe('Calculator', () => {
  it('adds numbers correctly', () => {
    expect(add(2, 3)).toBe(5);
  });
  it('multiplies numbers correctly', () => {
    expect(multiply(3, 4)).toBe(12);
  });
});
