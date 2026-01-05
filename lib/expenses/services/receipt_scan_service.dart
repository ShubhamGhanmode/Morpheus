import 'dart:convert';
import 'dart:typed_data';

import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/expenses/models/receipt_scan_result.dart';
import 'package:morpheus/expenses/services/document_ai_receipt_client.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ReceiptScanService {
  ReceiptScanService({
    FirebaseFunctions? functions,
    DocumentAiReceiptClient? documentAiClient,
  })  : _visionClient = _VisionReceiptClient(
          functions:
              functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
        ),
        _documentAiClient = documentAiClient ??
            DocumentAiReceiptClient(
              functions:
                  functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
            );

  final _VisionReceiptClient _visionClient;
  final DocumentAiReceiptClient _documentAiClient;

  static const int _maxImageBytes = 4 * 1024 * 1024;

  Future<ReceiptScanResult> scanReceipt({
    required Uint8List bytes,
    String? mimeType,
    ReceiptOcrProvider? provider,
  }) async {
    if (!AppConfig.enableReceiptScanning) {
      throw StateError('Receipt scanning is disabled in AppConfig.');
    }
    if (bytes.isEmpty) {
      throw ArgumentError('Receipt image is empty.');
    }
    if (bytes.lengthInBytes > _maxImageBytes) {
      throw ArgumentError('Receipt image is too large. Please use a smaller image.');
    }

    final resolvedMimeType = mimeType ?? 'image/jpeg';
    final resolvedProvider =
        provider ?? AppConfig.defaultReceiptOcrProvider;
    if (resolvedProvider == ReceiptOcrProvider.documentAi) {
      return _documentAiClient.scanReceipt(
        bytes: bytes,
        mimeType: resolvedMimeType,
      );
    }
    return _visionClient.scanReceipt(
      bytes: bytes,
      mimeType: resolvedMimeType,
    );
  }
}

class _VisionReceiptClient {
  _VisionReceiptClient({required FirebaseFunctions functions})
      : _functions = functions;

  final FirebaseFunctions _functions;

  Future<ReceiptScanResult> scanReceipt({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final base64Image = base64Encode(bytes);
    final callable = _functions.httpsCallable('scanReceipt');
    final result = await callable.call(<String, dynamic>{
      'imageBase64': base64Image,
      'mimeType': mimeType,
    });

    if (result.data is! Map) {
      throw StateError('Invalid receipt scan response.');
    }

    return ReceiptScanResult.fromMap(
      Map<String, dynamic>.from(result.data as Map),
    );
  }
}
