// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../widgets/kpi_card.dart';
import '../widgets/subscription_tile.dart';
import '../widgets/saving_simulation_card.dart';
import '../widgets/pin_verification_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // User's monthly income, editable to simulate dynamic Subscription Creep Score
  double _income = 35000.0;

  // Mock subscriptions representing the five recurring subscriptions matching the mockup
  late List<SubscriptionModel> _subscriptions;

  @override
  void initState() {
    super.initState();
    _subscriptions = [
      SubscriptionModel(
        id: '1',
        name: 'NETFLIX.COM BANGKOK',
        price: 419,
        confidence: 88,
        usageStatus: UsageStatus.moderate,
        billingPeriod: 'Monthly',
        iconData: Icons.play_circle_fill,
        iconColor: const Color(0xFF3B82F6),
      ),
      SubscriptionModel(
        id: '2',
        name: 'Spotify Premium Tokyo',
        price: 139,
        confidence: 100,
        usageStatus: UsageStatus.frequent,
        billingPeriod: 'Monthly',
        iconData: Icons.music_note,
        iconColor: const Color(0xFF10B981),
      ),
      SubscriptionModel(
        id: '3',
        name: 'ChatGPT Plus OpenAI',
        price: 750,
        confidence: 100,
        usageStatus: UsageStatus.frequent,
        billingPeriod: 'Monthly',
        iconData: Icons.chat_bubble,
        iconColor: const Color(0xFF8B5CF6),
      ),
      SubscriptionModel(
        id: '4',
        name: 'Google One Cloud',
        price: 99,
        confidence: 100,
        usageStatus: UsageStatus.frequent,
        billingPeriod: 'Monthly',
        iconData: Icons.cloud,
        iconColor: const Color(0xFFF59E0B),
      ),
      SubscriptionModel(
        id: '5',
        name: 'Adobe Creative Cloud',
        price: 1200,
        confidence: 95,
        usageStatus: UsageStatus.unused,
        billingPeriod: 'Monthly',
        iconData: Icons.palette,
        iconColor: const Color(0xFFEF4444),
      ),
    ];
  }

  // Calculated values
  double get _totalMonthlyPayout {
    return _subscriptions.fold(0.0, (sum, sub) => sum + sub.price);
  }

  double get _totalYearlyPayout => _totalMonthlyPayout * 12;

  double get _creepScore {
    if (_income <= 0) return 0.0;
    return (_totalMonthlyPayout / _income) * 100;
  }

  int get _unusedAlertCount {
    return _subscriptions.where((sub) => sub.usageStatus == UsageStatus.unused).length;
  }

  double get _simulatedMonthlySavings {
    return _subscriptions
        .where((sub) => sub.isSelected)
        .fold(0.0, (sum, sub) => sum + sub.price);
  }

  double get _simulatedYearlySavings => _simulatedMonthlySavings * 12;

  // Toggle selected for cancellation simulation
  void _toggleSubscriptionSelection(int index, bool selected) {
    setState(() {
      _subscriptions[index].isSelected = selected;
    });
  }

  // Automatically check all alerted items for cancellation (e.g. Adobe Creative Cloud)
  void _cancelAllAlertedItems() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PinVerificationDialog(),
    );

    if (confirmed == true) {
      final List<SubscriptionModel> removedSubs = [];
      final List<int> originalIndices = [];

      setState(() {
        for (int i = _subscriptions.length - 1; i >= 0; i--) {
          if (_subscriptions[i].isSelected) {
            removedSubs.add(_subscriptions[i]);
            originalIndices.add(i);
            _subscriptions.removeAt(i);
          }
        }
      });

      if (removedSubs.isNotEmpty) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF131C2E),
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF243049)),
            ),
            content: Row(
              children: [
                const Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ยกเลิกรายการแจ้งเตือน ${removedSubs.length} รายการแล้ว',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'เลิกทำ',
              textColor: const Color(0xFF3B82F6),
              onPressed: () {
                setState(() {
                  for (int i = removedSubs.length - 1; i >= 0; i--) {
                    _subscriptions.insert(originalIndices[i], removedSubs[i]);
                  }
                });
              },
            ),
          ),
        );
      }
    }
  }

  // Dismiss a subscription with undo action
  void _deleteSubscription(int index) {
    final deletedSub = _subscriptions[index];
    final originalIndex = index;

    setState(() {
      _subscriptions.removeAt(index);
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF131C2E),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF243049)),
        ),
        content: Row(
          children: [
            Icon(deletedSub.iconData, color: deletedSub.iconColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ยกเลิกรายการ ${deletedSub.name} แล้ว',
                style: const TextStyle(color: Colors.white, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'เลิกทำ',
          textColor: const Color(0xFF3B82F6),
          onPressed: () {
            setState(() {
              _subscriptions.insert(originalIndex, deletedSub);
            });
          },
        ),
      ),
    );
  }

  // Dialog to edit the income dynamically
  void _showEditIncomeDialog() {
    final controller = TextEditingController(text: _income.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131C2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF243049)),
          ),
          title: const Text(
            'แก้ไขรายได้รายเดือน',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ระบุรายได้ (฿) เพื่อประเมิน Subscription Creep Score',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixText: '฿ ',
                  prefixStyle: const TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF243049)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                final double? newIncome = double.tryParse(controller.text);
                if (newIncome != null && newIncome > 0) {
                  setState(() {
                    _income = newIncome;
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Get description text and color for creep score
  String get _creepScoreSubtitle {
    final score = _creepScore;
    if (score <= 5.0) {
      return 'ต่ำ: มีวินัยทางการเงินที่ดี';
    } else if (score <= 10.0) {
      return 'ปานกลาง: ควบคุมพฤติกรรม';
    } else {
      return 'สูง: ความเสี่ยงทางการเงิน';
    }
  }

  Color get _creepScoreColor {
    final score = _creepScore;
    if (score <= 5.0) {
      return const Color(0xFF10B981); // Green
    } else if (score <= 10.0) {
      return const Color(0xFFF59E0B); // Orange/Amber
    } else {
      return const Color(0xFFEF4444); // Red
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D), // Dark background matching the mockup
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Bar ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.security,
                          color: Color(0xFF3B82F6),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subscription Creep',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Dashboard Standalone Demo',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Spark Cluster IDLE Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131C2E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF243049)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          color: Color(0xFF10B981),
                          size: 10,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Spark Cluster: IDLE',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // --- Main Titles ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ภาพรวมระบบป้องกันค่าบริการซ้ำซ้อน',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'พบสัญญาสมาชิกแบบประจำ ${_subscriptions.length} รายการ',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Interactive Income Widget
                  InkWell(
                    onTap: _showEditIncomeDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131C2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF243049)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: Color(0xFF60A5FA),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'รายได้: ${_income.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '฿',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.edit,
                            color: Color(0xFF64748B),
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- KPI Cards Grid ---
              isWideScreen
                  ? Row(
                      children: [
                        Expanded(
                          child: KpiCard(
                            title: 'จ่ายออกรวมรายเดือน',
                            value: '฿${_totalMonthlyPayout.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                            subtitle: 'คิดเป็น ฿${_totalYearlyPayout.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} / ปี',
                            subtitleColor: const Color(0xFF60A5FA),
                            icon: Icons.credit_card,
                            iconColor: const Color(0xFF3B82F6),
                            iconBackgroundColor: const Color(0xFF1E3A8A).withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: KpiCard(
                            title: 'Subscription Creep Score',
                            value: '${_creepScore.toStringAsFixed(1)}%',
                            subtitle: _creepScoreSubtitle,
                            subtitleColor: _creepScoreColor,
                            icon: Icons.warning_amber_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            iconBackgroundColor: const Color(0xFFD97706).withOpacity(0.2),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: KpiCard(
                            title: 'แจ้งเตือนบริการที่ไม่ได้ใช้งาน',
                            value: '$_unusedAlertCount รายการ',
                            subtitle: 'แนะนำยกเลิกเพื่อประหยัดเงิน',
                            subtitleColor: const Color(0xFFEF4444),
                            icon: Icons.notifications_active,
                            iconColor: const Color(0xFFEF4444),
                            iconBackgroundColor: const Color(0xFF991B1B).withOpacity(0.3),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        KpiCard(
                          title: 'จ่ายออกรวมรายเดือน',
                          value: '฿${_totalMonthlyPayout.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                          subtitle: 'คิดเป็น ฿${_totalYearlyPayout.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} / ปี',
                          subtitleColor: const Color(0xFF60A5FA),
                          icon: Icons.credit_card,
                          iconColor: const Color(0xFF3B82F6),
                          iconBackgroundColor: const Color(0xFF1E3A8A).withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        KpiCard(
                          title: 'Subscription Creep Score',
                          value: '${_creepScore.toStringAsFixed(1)}%',
                          subtitle: _creepScoreSubtitle,
                          subtitleColor: _creepScoreColor,
                          icon: Icons.warning_amber_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          iconBackgroundColor: const Color(0xFFD97706).withOpacity(0.2),
                        ),
                        const SizedBox(height: 12),
                        KpiCard(
                          title: 'แจ้งเตือนบริการที่ไม่ได้ใช้งาน',
                          value: '$_unusedAlertCount รายการ',
                          subtitle: 'แนะนำยกเลิกเพื่อประหยัดเงิน',
                          subtitleColor: const Color(0xFFEF4444),
                          icon: Icons.notifications_active,
                          iconColor: const Color(0xFFEF4444),
                          iconBackgroundColor: const Color(0xFF991B1B).withOpacity(0.3),
                        ),
                      ],
                    ),
              const SizedBox(height: 40),

              // --- Responsive Split Section (Subscriptions List & Simulator) ---
              isWideScreen
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (60%): Subscriptions list
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'รายการตรวจพบสัญญาอัตโนมัติ (Recurring Subscriptions)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _subscriptions.length,
                                itemBuilder: (context, index) {
                                  final sub = _subscriptions[index];
                                  return SubscriptionTile(
                                    key: ValueKey(sub.id),
                                    subscription: sub,
                                    onChecked: (checked) {
                                      _toggleSubscriptionSelection(index, checked ?? false);
                                    },
                                    onDismissed: () {
                                      _deleteSubscription(index);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Right Column (40%): Saving simulation card
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'คำแนะนำและการจำลองลดค่าใช้จ่าย',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SavingSimulationCard(
                                monthlySavings: _simulatedMonthlySavings,
                                yearlySavings: _simulatedYearlySavings,
                                onCancelAllAlerted: _cancelAllAlertedItems,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subscriptions list first
                        const Text(
                          'รายการตรวจพบสัญญาอัตโนมัติ (Recurring Subscriptions)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _subscriptions.length,
                          itemBuilder: (context, index) {
                            final sub = _subscriptions[index];
                            return SubscriptionTile(
                              key: ValueKey(sub.id),
                              subscription: sub,
                              onChecked: (checked) {
                                _toggleSubscriptionSelection(index, checked ?? false);
                              },
                              onDismissed: () {
                                _deleteSubscription(index);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        // Saving simulation card second
                        const Text(
                          'คำแนะนำและการจำลองลดค่าใช้จ่าย',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SavingSimulationCard(
                          monthlySavings: _simulatedMonthlySavings,
                          yearlySavings: _simulatedYearlySavings,
                          onCancelAllAlerted: _cancelAllAlertedItems,
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
