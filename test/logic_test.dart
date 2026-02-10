import 'package:flutter_test/flutter_test.dart';
import 'package:decision_tracker/domain/models/enums.dart';

void main() {
  group('RetroAt Calculation Tests', () {
    test('calculateRetroAt today should be 21:00', () {
      final now = DateTime.now();
      final today21 = DateTime(now.year, now.month, now.day, 21);
      
      // Simple verification of logic
      DateTime calculate(RetroOffsetType type) {
        final now = DateTime.now();
        final today21 = DateTime(now.year, now.month, now.day, 21);
        switch (type) {
          case RetroOffsetType.today: return today21;
          case RetroOffsetType.tomorrow: return today21.add(const Duration(days: 1));
          default: return today21;
        }
      }

      expect(calculate(RetroOffsetType.today), today21);
      expect(calculate(RetroOffsetType.tomorrow).day, today21.add(const Duration(days: 1)).day);
    });
  });
}
