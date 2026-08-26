import 'dart:async';
import 'package:flutter/services.dart';

class NfcCardService {
  static final NfcCardService _instance = NfcCardService._internal();
  static const MethodChannel _nfcChannel = MethodChannel('com.example.test/nfc');

  final StreamController<String> _cardScanStreamController =
      StreamController<String>.broadcast();

  Stream<String> get onCardScanned => _cardScanStreamController.stream;

  factory NfcCardService() => _instance;

  NfcCardService._internal() {
    _nfcChannel.setMethodCallHandler((call) async {
      if (call.method == 'onCardScanned') {
        final cardUid = call.arguments?.toString().trim() ?? '';
        if (cardUid.isNotEmpty) {
          _cardScanStreamController.add(cardUid);
        }
      }
      return null;
    });
  }

  Future<bool> isNfcAvailable() async {
    try {
      final available = await _nfcChannel.invokeMethod<bool>('isNfcAvailable');
      return available ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> startListening() async {
    try {
      await _nfcChannel.invokeMethod('startNfcListener');
    } catch (_) {}
  }

  Future<void> stopListening() async {
    try {
      await _nfcChannel.invokeMethod('stopNfcListener');
    } catch (_) {}
  }

  void dispose() {
    _cardScanStreamController.close();
  }
}
