import 'package:flutter/material.dart';
import 'package:nepali_utils/nepali_utils.dart';
import 'package:parking/member/renew/screens/renew_member.dart';
import 'package:parking/member/screens/view_member.dart';
import 'package:parking/member/update/screens/editmember.dart';

class ReportDataTable extends StatelessWidget {
  final List<dynamic> attendanceData;

  const ReportDataTable({super.key, required this.attendanceData});

  // Helper method to determine expiry status for Nepali dates
  Map<String, dynamic> getExpiryStatus(String? expiryDateStr) {
    if (expiryDateStr == null || expiryDateStr == '-') {
      return {'color': Colors.grey, 'label': 'N/A', 'icon': Icons.help_outline};
    }

    try {
      // Parse Nepali date (format: 2082/2/4 or 2082-2-4)
      final parts = expiryDateStr.replaceAll('/', '-').split('-');
      if (parts.length != 3) {
        return {
          'color': Colors.grey,
          'label': 'Invalid Date',
          'icon': Icons.error_outline,
        };
      }

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      final expiryDate = NepaliDateTime(year, month, day);
      final today = NepaliDateTime.now();

      // Calculate difference in days
      final expiryDateInDays =
          expiryDate.year * 365 + expiryDate.month * 30 + expiryDate.day;
      final todayInDays = today.year * 365 + today.month * 30 + today.day;
      final difference = expiryDateInDays - todayInDays;

      if (difference < 0) {
        return {'color': Colors.red, 'label': 'Expired', 'icon': Icons.warning};
      } else if (difference <= 7) {
        return {
          'color': Colors.orange,
          'label': 'Expiring in $difference days',
          'icon': Icons.warning,
        };
      } else {
        return {
          'color': Colors.green,
          'label': 'Active',
          'icon': Icons.check_circle,
        };
      }
    } catch (e) {
      return {
        'color': Colors.grey,
        'label': 'Invalid Date',
        'icon': Icons.error_outline,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        dataRowColor: WidgetStateProperty.all(Colors.white),
        headingRowColor: WidgetStateProperty.all(const Color(0xFFD4E8FF)),
        columnSpacing: 16,
        dataRowMinHeight: 45,
        dataRowMaxHeight: 80,
        columns: const [
          DataColumn(
            label: Text('SN', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text('Smart Card', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              'Vehicle No',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              'Expiry Date',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Action',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: List<DataRow>.generate(attendanceData.length, (index) {
          final record = attendanceData[index];
          final vehicles = record['vehicles'] as List<dynamic>? ?? [];
          final cardUid = record['card_uid']?.toString() ?? '';
          final isInside = record['is_inside'] == true;

          // Get vehicle numbers from vehicles list
          final vehicleNumbers = vehicles
              .map((v) => v['vehicle_number'] ?? '')
              .where((numm) => numm.isNotEmpty)
              .join(', ');

          // Get expiry status
          final expiryStatus = getExpiryStatus(record['expiry_date']);

          return DataRow(
            cells: [
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: expiryStatus['color'].withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            expiryStatus['icon'],
                            size: 11,
                            color: expiryStatus['color'],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            expiryStatus['label'],
                            style: TextStyle(
                              fontSize: 10,
                              color: expiryStatus['color'],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              // Smart Card UID cell
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cardUid.isNotEmpty ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: cardUid.isNotEmpty ? Colors.green.shade600 : Colors.grey.shade400,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        cardUid.isNotEmpty ? cardUid : 'No Card',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: cardUid.isNotEmpty ? Colors.green.shade900 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    if (isInside)
                      const Text(
                        '🟢 INSIDE',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                  ],
                ),
              ),

              DataCell(
                SizedBox(
                  width: 140,
                  child: Text(
                    vehicleNumbers.isNotEmpty ? vehicleNumbers : 'N/A',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              // Phone
              DataCell(Text(record['phone'] ?? '-', style: const TextStyle(fontSize: 12))),
              // Expiry Date
              DataCell(
                Text(
                  record['expiry_date'] ?? '-',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                ),
              ),
              // Action Menu
              DataCell(
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Colors.black,
                  ),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onSelected: (value) {
                    final memberId = record['member_id'].toString();

                    if (value == 'view') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MemberDetailsScreen(memberId: memberId),
                        ),
                      );
                    } else if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UpdateRegistraton(memberId: memberId),
                        ),
                      );
                    } else if (value == 'renew') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RenewMember(memberId: memberId),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      height: 32,
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 16),
                          SizedBox(width: 8),
                          Text('View & Replace Card', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      height: 32,
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Edit Member', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'renew',
                      height: 32,
                      child: Row(
                        children: [
                          Icon(Icons.refresh, size: 16),
                          SizedBox(width: 8),
                          Text('Renew Member', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
