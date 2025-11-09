import 'package:flutter_test/flutter_test.dart';
import 'package:MediChat/utils/date_formatter.dart';

void main() {
  group('DateFormatter', () {
    test('should handle API DOB timestamp format correctly', () {
      // Test DOB format from API: 2005-12-15T18:30:00.000Z
      const dobFromApi = '2005-12-15T18:30:00.000Z';
      final formatted = DateFormatter.formatDateOfBirth(dobFromApi);

      // Should show December 15, 2005 regardless of timezone
      expect(formatted, contains('December 15, 2005'));
    });

    test('should handle date-only format', () {
      // Test simple date format
      const dateOnly = '2005-12-15';
      final formatted = DateFormatter.formatDateOfBirth(dateOnly);

      expect(formatted, contains('December 15, 2005'));
    });

    test('should format date for API correctly', () {
      // Test formatting a date for API submission
      final date = DateTime(2005, 12, 15);
      final apiFormat = DateFormatter.formatDateForApi(date);

      // Should be UTC midnight: 2005-12-15T00:00:00.000Z
      expect(apiFormat, equals('2005-12-15T00:00:00.000Z'));
    });

    test('should handle timestamp with timezone offset', () {
      // Test created/updated timestamp format: 2025-10-07T07:48:37.780559+00:00
      const timestamp = '2025-10-07T07:48:37.780559+00:00';
      final formatted = DateFormatter.formatDateOfBirth(timestamp);

      // Should extract the date correctly
      expect(formatted, contains('October 07, 2025'));
    });

    test('should handle malformed date gracefully', () {
      const malformed = 'invalid-date';
      final formatted = DateFormatter.formatDateOfBirth(malformed);

      // Should return original string if parsing fails
      expect(formatted, equals(malformed));
    });
  });
}
