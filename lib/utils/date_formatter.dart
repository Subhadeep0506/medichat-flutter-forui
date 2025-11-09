class DateFormatter {
  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _monthNamesShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Format date as "Oct 08, 2025"
  static String formatShortDate(DateTime dateTime) {
    return '${_monthNamesShort[dateTime.month - 1]} ${dateTime.day.toString().padLeft(2, '0')}, ${dateTime.year}';
  }

  /// Format date as "October 08, 2025"
  static String formatLongDate(DateTime dateTime) {
    return '${_monthNames[dateTime.month - 1]} ${dateTime.day.toString().padLeft(2, '0')}, ${dateTime.year}';
  }

  /// Format date with time as "Oct 08, 2025 14:30"
  static String formatDateTime(DateTime dateTime) {
    return '${formatShortDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Format date relative to now (e.g., "2 days ago", "Today", "Yesterday")
  static String formatRelativeDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      final difference = today.difference(dateOnly).inDays;
      if (difference > 0 && difference < 7) {
        return '$difference days ago';
      } else if (difference > 0 && difference < 30) {
        final weeks = (difference / 7).floor();
        return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
      } else {
        return formatShortDate(dateTime);
      }
    }
  }

  /// Format date of birth properly
  static String formatDateOfBirth(String dob) {
    try {
      final date = _parseToLocalDate(dob);
      return formatLongDate(date);
    } catch (e) {
      return dob; // Return original if parsing fails
    }
  }

  /// Parse incoming dob strings in multiple common formats and return local DateTime
  /// Handles both date-only (yyyy-MM-dd) and ISO timestamps (2005-12-15T18:30:00.000Z)
  static DateTime _parseToLocalDate(String dob) {
    // Handle date-only format yyyy-MM-dd
    final dateOnlyRegex = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    final m = dateOnlyRegex.firstMatch(dob);
    if (m != null) {
      final y = int.parse(m.group(1)!);
      final mo = int.parse(m.group(2)!);
      final d = int.parse(m.group(3)!);
      return DateTime(y, mo, d);
    }

    // Handle ISO timestamps - parse and extract date components to avoid timezone shifts
    // Examples: 2005-12-15T18:30:00.000Z, 2025-10-07T07:48:37.780559+00:00
    try {
      final parsed = DateTime.parse(dob).toLocal();
      // Return date-only components to avoid timezone affecting the calendar date
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (e) {
      // Fallback: return current date if parsing completely fails
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
  }

  /// Convert a DateTime to DOB format expected by API (ISO string at midnight UTC)
  /// This ensures the date is preserved regardless of client timezone
  static String formatDateForApi(DateTime date) {
    // Create UTC midnight for the selected date to avoid timezone shifts
    final utcMidnight = DateTime.utc(date.year, date.month, date.day);
    return utcMidnight.toIso8601String();
  }
}
