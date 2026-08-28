import 'package:flutter/material.dart';
import 'package:parking/drawer/member_registration.dart';
import 'package:parking/drawer/payment_form.dart';
import 'package:parking/drawer/vehicleform.dart';

class RegistrationFlow extends StatefulWidget {
  const RegistrationFlow({super.key});

  @override
  State<RegistrationFlow> createState() => _RegistrationFlowState();
}

class _RegistrationFlowState extends State<RegistrationFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final RegistrationData _registrationData = RegistrationData();

  void _nextPage() {
    if (_currentPage < 2) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF6E93B3),
      child: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
        },
        children: [
          _buildPageContent(
            MemberRegistrationScreen(
              data: _registrationData,
              onNext: _nextPage,
              onPrevious: _previousPage,
              isFirstPage: true,
            ),
          ),
          _buildPageContent(
            VehicleMembershipScreen(
              data: _registrationData,
              onNext: _nextPage,
              onPrevious: _previousPage,
            ),
          ),
          _buildPageContent(
            PaymentValidityScreen(
              data: _registrationData,
              onPrevious: _previousPage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(Widget child) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            'Member Registration',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          _buildProgressIndicator(),
          child,
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStep(1, 'Member\nRegistration', _currentPage >= 0),
          _buildProgressLine(_currentPage >= 1),
          _buildStep(2, 'Vehicle &\nMembership', _currentPage >= 1),
          _buildProgressLine(_currentPage >= 2),
          _buildStep(3, 'Payment &\nValidity', _currentPage >= 2),
        ],
      ),
    );
  }

  Widget _buildStep(int step, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF4CAF50) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? const Color(0xFF4CAF50) : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              height: 1.2,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 30, left: 4, right: 4),
      color: Colors.white,
    );
  }
}

// Data Model
class RegistrationData {
  String? name;
  String? contactNo;
  String? vatRegistrationNo;
  String? shopNo;
  String? membershipType;
  List<Map<String, String>> vehicles = [];
  String? startDate;
  String? endDate;
  String? paymentMethod;
  String? totalAmount;
  String? recievedBy;
  String? cardUid;
}
