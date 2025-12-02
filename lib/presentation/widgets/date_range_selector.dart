import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DateRangeType {
  thisMonth,
  lastMonth,
  last3Months,
  thisYear,
  custom,
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});

  bool contains(DateTime date) {
    return date.isAfter(start.subtract(const Duration(days: 1))) &&
           date.isBefore(end.add(const Duration(days: 1)));
  }
}

class DateRangeSelector extends StatelessWidget {
  final DateRangeType selectedType;
  final DateRange? customRange;
  final Function(DateRangeType, DateRange?) onChanged;

  const DateRangeSelector({
    super.key,
    required this.selectedType,
    this.customRange,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<DateRangeType>(
      segments: const [
        ButtonSegment(value: DateRangeType.thisMonth, label: Text('This Month')),
        ButtonSegment(value: DateRangeType.lastMonth, label: Text('Last Month')),
        ButtonSegment(value: DateRangeType.last3Months, label: Text('3 Months')),
        ButtonSegment(value: DateRangeType.thisYear, label: Text('This Year')),
      ],
      selected: {selectedType},
      onSelectionChanged: (Set<DateRangeType> newSelection) {
        final type = newSelection.first;
        if (type == DateRangeType.custom) {
          _showCustomDatePicker(context);
        } else {
          onChanged(type, null);
        }
      },
    );
  }

  void _showCustomDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, 1, 1);
    final lastDate = now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: customRange != null
          ? DateTimeRange(start: customRange!.start, end: customRange!.end)
          : DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: now,
            ),
    );

    if (picked != null) {
      onChanged(
        DateRangeType.custom,
        DateRange(start: picked.start, end: picked.end),
      );
    }
  }

  static DateRange getRangeForType(DateRangeType type, {DateRange? customRange}) {
    final now = DateTime.now();
    
    switch (type) {
      case DateRangeType.thisMonth:
        return DateRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case DateRangeType.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1);
        return DateRange(
          start: DateTime(lastMonth.year, lastMonth.month, 1),
          end: DateTime(now.year, now.month, 0),
        );
      case DateRangeType.last3Months:
        final threeMonthsAgo = DateTime(now.year, now.month - 3);
        return DateRange(
          start: DateTime(threeMonthsAgo.year, threeMonthsAgo.month, 1),
          end: now,
        );
      case DateRangeType.thisYear:
        return DateRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        );
      case DateRangeType.custom:
        return customRange ?? DateRange(start: now, end: now);
    }
  }
}





