import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:morpheus/utils/statement_dates.dart';

DateTime dateTimeFromJson(Object? value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is double) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

Object dateTimeToJson(DateTime value) => Timestamp.fromDate(value);

DateTime? nullableDateTimeFromJson(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is double) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

Object? nullableDateTimeToJson(DateTime? value) =>
    value == null ? null : Timestamp.fromDate(value);

StatementWindow statementWindowFromJson(Object? value) {
  if (value is StatementWindow) return value;
  if (value is Map) {
    return StatementWindow(
      start: dateTimeFromJson(value['start']),
      end: dateTimeFromJson(value['end']),
      due: dateTimeFromJson(value['due']),
    );
  }
  final now = DateTime.now();
  return StatementWindow(start: now, end: now, due: now);
}

Object statementWindowToJson(StatementWindow value) => {
  'start': dateTimeToJson(value.start),
  'end': dateTimeToJson(value.end),
  'due': dateTimeToJson(value.due),
};

Color cardColorFromJson(Object? value) {
  if (value is int) return Color(value);
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return Color(parsed);
  }
  return const Color(0xFF334155);
}

Color textColorFromJson(Object? value) {
  if (value is int) return Color(value);
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return Color(parsed);
  }
  return const Color(0xFFFFFFFF);
}

Color? nullableColorFromJson(Object? value) {
  if (value == null) return null;
  if (value is int) return Color(value);
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return Color(parsed);
  }
  return null;
}

int colorToJson(Color value) => value.value;

int? nullableColorToJson(Color? value) => value?.value;

List<int> intListFromJson(Object? value) {
  if (value is List) {
    return value
        .map((e) => (e as num?)?.toInt() ?? 0)
        .where((v) => v > 0)
        .toList();
  }
  if (value is String) {
    return value
        .split(',')
        .map((e) => int.tryParse(e) ?? 0)
        .where((v) => v > 0)
        .toList();
  }
  return const [];
}

Object intListToJson(List<int> value) => value;
