import 'package:test/test.dart';
import '../lib/calculator.dart';

void main() {
  group('Calculator', () {
    const calc = Calculator();
    test('adds two numbers correctly', () {
      expect(calc.add(2, 3), equals(5));
    });
    test('multiplies two numbers correctly', () {
      expect(calc.multiply(3, 4), equals(12));
    });
  });
}
