import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

String errorMessage(Object error, {required String action}) {
  if (error is FirebaseException) {
    return error.message ?? '$action failed. Please try again.';
  }
  if (error is PlatformException) {
    return error.message ?? '$action failed. Please try again.';
  }
  return '$action failed. Please try again.';
}
