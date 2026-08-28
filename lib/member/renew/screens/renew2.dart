// ignore_for_file: avoid_print, unused_field
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:parking/auth/api_endpoints.dart';
import 'package:parking/auth/auth_service.dart';
import 'package:parking/member/renew/screens/renew_member.dart';
import 'package:parking/services/nfc_service.dart';

class RenewScreen2 extends StatefulWidget {
  final String memberId;
  final RenewRegistrationData data;
  final VoidCallback onPrevious;
  final VoidCallback onSubmit;

  const RenewScreen2({
    super.key,
    required this.data,
    required this.onSubmit,
    required this.memberId,
    required this.onPrevious,
  });

  @override
  State<RenewScreen2> createState() => _RenewScreen2State();
}

class _RenewScreen2State extends State<RenewScreen2> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _recievedByController;
  StreamSubscription<NfcCardResult>? _nfcSub;
  String? _cardUid;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _recievedByController = TextEditingController(text: widget.data.recievedBy);
    _cardUid = widget.data.cardUid;

    _nfcSub = NfcCardService().onCardScanned.listen((result) {
      if (result.cardUid.isNotEmpty && mounted) {
        setState(() {
          _cardUid = result.cardUid;
          widget.data.cardUid = result.cardUid;
        });
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade800,
            content: Text('💳 Card Linked for Renewal: ${result.cardUid}'),
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
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    widget.data.recievedBy = _recievedByController.text.trim();
    final processedVehicles = widget.data.vehicles.map((vehicle) {
      if (vehicle.containsKey('vehicle_id') && vehicle['vehicle_id'] != null) {
        return {
          'id': int.parse(vehicle['vehicle_id']!),
          'vehicle_type': vehicle['vehicle_type'],
          'vehicle_number': vehicle['vehicle_number'],
          'total_amount': vehicle['total_amount'],
        };
      } else {
        return {
          'vehicle_type': vehicle['vehicle_type'],
          'vehicle_number': vehicle['vehicle_number'],
          'total_amount': vehicle['total_amount'],
        };
      }
    }).toList();

    final requestData = {
      'vehicles': processedVehicles,
      'start_date': widget.data.startDate,
      'end_date': widget.data.endDate,
      'payment_method': widget.data.paymentMethod,
      'received_by': widget.data.recievedBy,
      if (widget.data.cardUid != null && widget.data.cardUid!.isNotEmpty)
        'card_uid': widget.data.cardUid,
    };

    try {
      final token = await SecureStorage.getAccessToken();
      final response = await http.patch(
        Uri.parse(
          '${ApiEndpoints.baseUrl}membership/members/${widget.memberId}/renew/',
        ),
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
        body: json.encode(requestData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('✅ Membership renewed successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          widget.onSubmit();
        }
      } else {
        if (!mounted) return;
        final err = json.decode(response.body);
        final msg = err['error'] ?? err['message'] ?? 'Renewal failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('⚠️ $msg'),
            backgroundColor: Colors.red,
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
    final hasCard = _cardUid != null && _cardUid!.isNotEmpty;

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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Renewal Payment & Smart Card',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Card status / tap widget
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasCard
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFF0F4F8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: hasCard ? Colors.green : const Color(0xFF004DE8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasCard ? Icons.check_circle : Icons.contactless,
                              color: hasCard ? Colors.green.shade800 : const Color(0xFF004DE8),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hasCard ? 'Card Linked: $_cardUid' : 'Tap Card to Assign/Update',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: hasCard ? Colors.green.shade900 : const Color(0xFF090044),
                                    ),
                                  ),
                                  Text(
                                    hasCard ? 'Active RFID / MIFARE Smart Card' : 'Hold card to POS back to link',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

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
                        validator: (value) => value == null
                            ? 'Please select payment method'
                            : null,
                      ),

                      const SizedBox(height: 16),
                      _buildLabel('Received By'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _recievedByController,
                        decoration: InputDecoration(
                          hintText: 'Enter receiver name',
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFD1D1D1),
                            ),
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
          ],
        ),
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
              Icon(Icons.arrow_back, size: 14),
              SizedBox(width: 8),
              Text(
                'Previous',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'Renew Member',
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
