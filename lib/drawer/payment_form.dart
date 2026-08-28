// ignore_for_file: avoid_print, unused_field
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:parking/auth/api_endpoints.dart';
import 'package:parking/auth/auth_service.dart';
import 'package:parking/drawer/add_member.dart';
import 'package:parking/home/screens/root_app.dart';
import 'package:parking/services/nfc_service.dart';

class PaymentValidityScreen extends StatefulWidget {
  final RegistrationData data;
  final VoidCallback onPrevious;

  const PaymentValidityScreen({
    super.key,
    required this.data,
    required this.onPrevious,
  });

  @override
  State<PaymentValidityScreen> createState() => _PaymentValidityScreenState();
}

class _PaymentValidityScreenState extends State<PaymentValidityScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _recievedByController;
  final TextEditingController _manualCardUidController =
      TextEditingController();
  StreamSubscription<NfcCardResult>? _nfcSub;
  String? _scannedCardUid;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _recievedByController = TextEditingController(text: widget.data.recievedBy);
    _scannedCardUid = widget.data.cardUid;
    if (_scannedCardUid != null) {
      _manualCardUidController.text = _scannedCardUid!;
    }

    _initNfcListener();
  }

  void _initNfcListener() {
    _nfcSub = NfcCardService().onCardScanned.listen((result) {
      if (result.cardUid.isNotEmpty && mounted) {
        setState(() {
          _scannedCardUid = result.cardUid;
          widget.data.cardUid = result.cardUid;
          _manualCardUidController.text = result.cardUid;
        });
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade800,
            content: Text('💳 Smart Card Detected: ${result.cardUid}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _nfcSub?.cancel();
    _recievedByController.dispose();
    _manualCardUidController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    widget.data.recievedBy = _recievedByController.text.trim();
    if (_manualCardUidController.text.trim().isNotEmpty) {
      widget.data.cardUid = _manualCardUidController.text.trim().toUpperCase();
    }

    final requestData = {
      'name': widget.data.name,
      'phone_number': widget.data.contactNo,
      'customer_vat': widget.data.vatRegistrationNo,
      'shop_number': widget.data.shopNo,
      'membership_type': widget.data.membershipType,
      'vehicles': widget.data.vehicles,
      'start_date': widget.data.startDate,
      'end_date': widget.data.endDate,
      'payment_method': widget.data.paymentMethod,
      'received_by': widget.data.recievedBy,
      if (widget.data.cardUid != null && widget.data.cardUid!.isNotEmpty)
        'card_uid': widget.data.cardUid,
    };

    try {
      final token = await SecureStorage.getAccessToken();
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}membership/members/register-member/'),
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
        body: json.encode(requestData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('✅ Member Registered & Smart Card Linked!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppShell()),
          (_) => false,
        );
      } else {
        if (!mounted) return;
        final errorJson = json.decode(response.body);
        String errMsg = 'Failed to register member';
        if (errorJson is Map) {
          if (errorJson.containsKey('details')) {
            errMsg = errorJson['details'].toString();
          } else if (errorJson.containsKey('error')) {
            errMsg = errorJson['error'].toString();
          } else if (errorJson.containsKey('message')) {
            errMsg = errorJson['message'].toString();
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('⚠️ $errMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCard = _scannedCardUid != null && _scannedCardUid!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment & Smart Card',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // NFC Card Assignment Widget
                _buildCardAssignmentBox(hasCard),

                const SizedBox(height: 16),
                _buildLabel('Payment Method'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: widget.data.paymentMethod ?? 'CASH',
                  decoration: _dropdownDecoration('Select Payment Mode'),
                  items: ['CASH', 'ONLINE']
                      .map(
                        (method) => DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => widget.data.paymentMethod = value),
                  validator: (value) =>
                      value == null ? 'Please select payment method' : null,
                ),

                const SizedBox(height: 16),
                _buildLabel('Received By'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _recievedByController,
                  decoration: InputDecoration(
                    hintText: 'Enter receiver name',
                    filled: true,
                    fillColor: const Color(0xFFF2F2F2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: (value) => value?.trim().isEmpty ?? true
                      ? 'Please enter receiver name'
                      : null,
                ),
                const SizedBox(height: 24),
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardAssignmentBox(bool hasCard) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasCard ? const Color(0xFFE8F5E9) : const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasCard ? Colors.green.shade600 : const Color(0xFF004DE8),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasCard ? Icons.check_circle : Icons.contactless,
                color: hasCard ? Colors.green.shade700 : const Color(0xFF004DE8),
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasCard
                          ? 'Smart Card Assigned'
                          : 'Tap Member Card on POS Back',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: hasCard
                            ? Colors.green.shade900
                            : const Color(0xFF090044),
                      ),
                    ),
                    Text(
                      hasCard
                          ? 'UID: $_scannedCardUid'
                          : 'Hold RFID / MIFARE card to scanner to link',
                      style: TextStyle(
                        fontSize: 12,
                        color: hasCard
                            ? Colors.green.shade800
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasCard)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  color: Colors.green.shade900,
                  tooltip: 'Clear & Re-tap Card',
                  onPressed: () {
                    setState(() {
                      _scannedCardUid = null;
                      widget.data.cardUid = null;
                      _manualCardUidController.clear();
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: _isSubmitting ? null : widget.onPrevious,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: const Row(
            children: [
              Icon(Icons.arrow_back, size: 16),
              SizedBox(width: 6),
              Text(
                'Previous',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF004DE8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Add Member',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _dropdownDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF5FAFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD1D1D1)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
