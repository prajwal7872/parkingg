// ignore_for_file: unused_field
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:parking/auth/api_endpoints.dart';
import 'package:parking/auth/auth_service.dart';
import 'package:parking/member/renew/screens/renew1.dart';
import 'package:parking/member/renew/screens/renew2.dart';

class RenewMember extends StatefulWidget {
  final String memberId;
  const RenewMember({super.key, required this.memberId});

  @override
  State<RenewMember> createState() => _RenewMemberState();
}

class _RenewMemberState extends State<RenewMember> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final RenewRegistrationData _registrationData = RenewRegistrationData();
  bool _isLoading = true;

  void _nextPage() {
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> fetchupdate() async {
    final token = await SecureStorage.getAccessToken();

    final response = await http.get(
      Uri.parse(
        '${ApiEndpoints.baseUrl}membership/members/${widget.memberId}/',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        _registrationData.vehicles = List<Map<String, String>>.from(
          data['vehicles'].map(
            (v) => {
              'vehicle_id': v['id'].toString(),
              'vehicle_type': v['vehicle_type'].toString(),
              'vehicle_number': v['vehicle_number'].toString(),
              'total_amount': v['total_amount'].toString(),
            },
          ),
        );
        _registrationData.cardUid = data['card_uid'];

        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Failed to load member');
    }
  }

  @override
  void initState() {
    fetchupdate();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF668DAF),
      body: SafeArea(
        child: Column(
          children: [
            Text(
              'Renew Membership',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_buildProgressIndicator()],
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  RenewScreen1(
                    data: _registrationData,
                    onNext: _nextPage,
                    onPrevious: _previousPage,
                  ),

                  RenewScreen2(
                    memberId: widget.memberId,
                    data: _registrationData,
                    onPrevious: _previousPage,
                    onSubmit: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: _buildStep(_currentPage + 1),
    );
  }

  Widget _buildStep(int step) {
    return Text(
      'Step $step of 2',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// Data Model
class RenewRegistrationData {
  List<Map<String, String>> vehicles = [];
  String? startDate;
  String? endDate;
  String? paymentMethod;
  String? totalAmount;
  String? recievedBy;
  String? cardUid;
}
