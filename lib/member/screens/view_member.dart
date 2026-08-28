// ignore_for_file: avoid_print, unused_field
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:parking/auth/api_endpoints.dart';
import 'package:parking/auth/auth_service.dart';
import 'package:parking/member/service/member_api.dart';
import 'package:parking/services/nfc_service.dart';

// Model classes
class Member {
  final int id;
  final String name;
  final String phoneNumber;
  final String? cardUid;
  final bool isInside;
  final String? lastGateActivity;
  final String membershipType;
  final String shopNumber;
  final String customerVat;
  final String createdAt;
  final String receivedBy;
  final List<Vehicle> vehicles;
  final String paymentMethod;
  final String startDate;
  final String endDate;

  Member({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.cardUid,
    this.isInside = false,
    this.lastGateActivity,
    required this.membershipType,
    required this.shopNumber,
    required this.customerVat,
    required this.createdAt,
    required this.receivedBy,
    required this.vehicles,
    required this.paymentMethod,
    required this.startDate,
    required this.endDate,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      cardUid: json['card_uid'] as String?,
      isInside: json['is_inside'] == true,
      lastGateActivity: json['last_gate_activity'] as String?,
      membershipType: json['membership_type'] as String? ?? '',
      shopNumber: json['shop_number'] as String? ?? '',
      customerVat: json['customer_vat'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      receivedBy: json['received_by'] as String? ?? '',
      vehicles: ((json['vehicles'] as List?) ?? [])
          .map((v) => Vehicle.fromJson(v))
          .toList(),
      paymentMethod: json['payment_method'] as String? ?? 'CASH',
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
    );
  }
}

class Vehicle {
  final int id;
  final String vehicleNumber;
  final String vehicleType;
  final double totalAmount;

  Vehicle({
    required this.id,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.totalAmount,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as int? ?? 0,
      vehicleNumber: json['vehicle_number'] as String? ?? '',
      vehicleType: json['vehicle_type'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MemberService {
  static Future<Member> fetchMemberDetails(String memberId) async {
    final token = await SecureStorage.getAccessToken();
    final response = await http.get(
      Uri.parse('${ApiEndpoints.baseUrl}membership/members/$memberId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return Member.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load member details');
    }
  }
}

class MemberDetailsScreen extends StatefulWidget {
  final String memberId;

  const MemberDetailsScreen({super.key, required this.memberId});

  @override
  State<MemberDetailsScreen> createState() => _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends State<MemberDetailsScreen> {
  late Future<Member> _memberFuture;

  @override
  void initState() {
    super.initState();
    _loadMember();
  }

  void _loadMember() {
    setState(() {
      _memberFuture = MemberService.fetchMemberDetails(widget.memberId);
    });
  }

  void _showReplaceCardDialog(Member member) {
    StreamSubscription<NfcCardResult>? nfcSub;
    String? detectedUid;
    final feeController = TextEditingController(text: '200');
    String paymentMethod = 'CASH';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            nfcSub ??= NfcCardService().onCardScanned.listen((result) {
              if (result.cardUid.isNotEmpty && !isSaving) {
                setModalState(() {
                  detectedUid = result.cardUid;
                });
                HapticFeedback.mediumImpact();
              }
            });

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.contactless, size: 36, color: Color(0xFF004DE8)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Replace Lost / Damaged Card',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Member: ${member.name}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card Tap Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: detectedUid != null ? const Color(0xFFE8F5E9) : const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: detectedUid != null ? Colors.green.shade700 : const Color(0xFF004DE8),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            detectedUid != null ? Icons.check_circle : Icons.sensors,
                            color: detectedUid != null ? Colors.green.shade800 : const Color(0xFF004DE8),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  detectedUid != null
                                      ? 'New Card UID: $detectedUid'
                                      : 'Tap New RFID Smart Card on POS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: detectedUid != null ? Colors.green.shade900 : const Color(0xFF090044),
                                  ),
                                ),
                                Text(
                                  detectedUid != null
                                      ? 'Ready to link to member'
                                      : 'Hold the replacement card to the scanner back',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          if (detectedUid != null)
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 20),
                              onPressed: () {
                                setModalState(() {
                                  detectedUid = null;
                                });
                              },
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // Card Fee
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Card Fee (Rs.)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: feeController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '200',
                                  prefixText: 'Rs. ',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Payment Method
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Method',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: paymentMethod,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                items: ['CASH', 'ONLINE']
                                    .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() => paymentMethod = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF004DE8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: (detectedUid == null || isSaving)
                                ? null
                                : () async {
                                    setModalState(() => isSaving = true);
                                    final double fee = double.tryParse(feeController.text.trim()) ?? 0.0;
                                    final user = await SecureStorage.getFullName() ?? '';

                                    final res = await ReportService.replaceCard(
                                      memberId: member.id,
                                      newCardUid: detectedUid!,
                                      fee: fee,
                                      paymentMethod: paymentMethod,
                                      receivedBy: user,
                                    );

                                    if (!sheetContext.mounted) return;
                                    Navigator.pop(sheetContext);

                                    ScaffoldMessenger.of(context).clearSnackBars();
                                    if (res['success'] == true) {
                                      HapticFeedback.heavyImpact();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: Colors.green.shade800,
                                          content: Text('✅ New Card Linked! Collected Rs. ${fee.toStringAsFixed(0)} ($paymentMethod)'),
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                      _loadMember();
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: Colors.red.shade800,
                                          content: Text('⚠️ ${res['message']}'),
                                        ),
                                      );
                                    }
                                  },
                            child: isSaving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Issue & Collect Fee', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      nfcSub?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6E93B3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Member Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<Member>(
        future: _memberFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(
              child: Text('No data found', style: TextStyle(color: Colors.white)),
            );
          }

          final member = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadMember(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMemberInfoCard(member),
                  const SizedBox(height: 16),
                  _buildRegisteredVehicles(member.vehicles),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMemberInfoCard(Member member) {
    final hasCard = member.cardUid != null && member.cardUid!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Ribbon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF090044),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        member.phoneNumber,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: member.isInside ? Colors.green.shade600 : Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    member.isInside ? "🟢 INSIDE" : "⚪ OUTSIDE",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Smart Card Assignment Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasCard ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasCard ? Colors.green : Colors.orange,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasCard ? Icons.credit_card : Icons.warning_amber_rounded,
                        color: hasCard ? Colors.green.shade800 : Colors.orange.shade900,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasCard ? 'Card UID: ${member.cardUid}' : 'No Card Assigned',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: hasCard
                                    ? Colors.green.shade900
                                    : Colors.orange.shade900,
                              ),
                            ),
                            Text(
                              hasCard
                                  ? 'Active for boom barrier access'
                                  : 'Tap replace to link physical card',
                              style: TextStyle(
                                fontSize: 11,
                                color: hasCard
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004DE8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () => _showReplaceCardDialog(member),
                        child: Text(
                          hasCard ? 'Replace' : 'Assign',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                _buildInfoRow('Membership Type', member.membershipType),
                _buildInfoRow('Start Date', member.startDate),
                _buildInfoRow('Expiry Date', member.endDate),
                if (member.shopNumber.isNotEmpty)
                  _buildInfoRow('Shop Number', member.shopNumber),
                if (member.customerVat.isNotEmpty)
                  _buildInfoRow('Customer VAT', member.customerVat),
                _buildInfoRow('Payment Method', member.paymentMethod),
                _buildInfoRow('Received By', member.receivedBy),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisteredVehicles(List<Vehicle> vehicles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Registered Vehicles (1 Active Slot)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            final vehicle = vehicles[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF090044),
                  child: Icon(
                    vehicle.vehicleType.toLowerCase().contains('two') ||
                            vehicle.vehicleType.toLowerCase().contains('bike')
                        ? Icons.two_wheeler
                        : Icons.directions_car,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  vehicle.vehicleNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(vehicle.vehicleType),
                trailing: Text(
                  'Rs. ${vehicle.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
