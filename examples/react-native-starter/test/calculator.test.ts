import { add, multiply } from '../src/utils/calculator';

describe('Calculator Utilities', () => {
  it('adds two numbers correctly', () => {
    const result = add(10, 20);
    expect(result).toBe(30);
  });

  it('multiplies two numbers correctly', () => {
    const result = multiply(6, 7);
    expect(result).toBe(42);
  });
});
