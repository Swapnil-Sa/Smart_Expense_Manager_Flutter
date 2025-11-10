// wallet.dart
// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_controls, unused_local_variable, deprecated_member_use, unused_field, unnecessary_this

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application/data/model/add_date.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // CORRECT: This box holds the Add_data objects (transactions)
  final Box<Add_data> box = Hive.box<Add_data>('data');
  // CORRECT: This box holds user preferences like 'darkMode'
  final Box userBox = Hive.box('userBox');

  // --- THEME COLORS (Standardized from SettingsScreen) ---

  // Dark Theme Colors (Navy/Charcoal - as per your earlier update)
  static const Color primaryDark = Color(0xFF0D1829); // Main Background
  static const Color cardDark = Color(0xFF1B2C42); // Card/Tile Background
  static const Color mainTextDark = Colors.white;
  static const Color secondaryTextDark = Colors.white70;
  static const Color amberHighlight = Color(0xFFE5B80B); // Muted Gold/Amber Accent

  // Light Theme Colors (Dark Green - matching your profile/settings page)
  // Almond color for background based on image_365cc5.png
  static const Color primaryLight = Color.fromARGB(255, 240, 218, 187); 
  static const Color cardLight = Color(0xFFFFFFFF); // Pure white for cards on green background
  static const Color mainTextLight = Colors.black; // Dark text on white card
  static const Color secondaryTextLight = Colors.black54; // Secondary text color on light BG
  // Dark Green Accent (from your other files, used for titles/buttons/net text)
  static const Color primaryAccent = Color.fromARGB(255, 105, 128, 60); 

  @override
  Widget build(BuildContext context) {
    // 1. Use ValueListenableBuilder to rebuild the screen when 'darkMode' changes
    return ValueListenableBuilder(
      // The listenable watches the userBox for changes to 'darkMode'
      valueListenable: userBox.listenable(keys: ['darkMode']),
      builder: (context, userBoxListener, child) {
        // Read the darkMode value directly from the userBox
        final bool darkMode = userBox.get('darkMode', defaultValue: false);

        // Dynamic Color Selection
        final Color primaryBg = darkMode ? primaryDark : primaryLight;
        final Color cardBg = darkMode ? cardDark : cardLight;
        final Color headerTextColor = darkMode ? mainTextDark : primaryAccent; // Changed to accent in Light Mode for consistency
        final Color headerSecondaryTextColor = darkMode ? secondaryTextDark : secondaryTextLight;
        final Color cardContentTextColor = darkMode ? mainTextDark : mainTextLight;
        final Color dynamicAccentColor = darkMode ? amberHighlight : primaryAccent;

        // ⭐ NEW COLOR FOR NET TEXT IN CATEGORY CARDS
        // This color is visible on the dark green/red gradient of the category cards.
        final Color cardNetColor = darkMode ? Colors.white : Colors.yellow.shade50; 

        // Dynamic Income/Expense Colors (Dark colors for better contrast in both themes)
        final Color incomeColor = Colors.green.shade600;
        final Color expenseColor = Colors.red.shade600;

        // --- DATA PROCESSING LOGIC ---
        Map<String, Map<String, int>> dailySummary = {};
        int totalIncome = 0;
        int totalExpense = 0;

        for (var item in this.box.values.cast<Add_data>()) {
          String key = DateFormat('yyyy-MM-dd').format(item.datetime);
          if (!dailySummary.containsKey(key)) {
            dailySummary[key] = {'income': 0, 'expense': 0};
          }
          int amt = int.tryParse(item.amount) ?? 0;
          if (item.IN == 'Income') {
            dailySummary[key]!['income'] = dailySummary[key]!['income']! + amt;
            totalIncome += amt;
          } else {
            dailySummary[key]!['expense'] = dailySummary[key]!['expense']! + amt;
            totalExpense += amt;
          }
        }

        List<Map<String, dynamic>> dailyList = dailySummary.entries.map((e) {
          return {
            'date': DateTime.parse(e.key),
            'income': e.value['income'],
            'expense': e.value['expense'],
          };
        }).toList();
        dailyList.sort((a, b) => b['date'].compareTo(a['date']));

        Map<String, Map<String, int>> categorySummary = {};
        for (var item in this.box.values.cast<Add_data>()) {
          String cat = item.name;
          if (!categorySummary.containsKey(cat)) {
            categorySummary[cat] = {'income': 0, 'expense': 0};
          }
          int amt = int.tryParse(item.amount) ?? 0;
          if (item.IN == 'Income') {
            categorySummary[cat]!['income'] =
                categorySummary[cat]!['income']! + amt;
          } else {
            categorySummary[cat]!['expense'] =
                categorySummary[cat]!['expense']! + amt;
          }
        }

        int totalNet = totalIncome - totalExpense;

        DateTime now = DateTime.now();
        DateTime weekStart = now.subtract(const Duration(days: 6));
        int weeklyIncome = 0;
        int weeklyExpense = 0;
        for (var item in this.box.values.cast<Add_data>()) {
          if (item.datetime.isAfter(weekStart)) {
            int amt = int.tryParse(item.amount) ?? 0;
            if (item.IN == 'Income') {
              weeklyIncome += amt;
            } else {
              weeklyExpense += amt;
            }
          }
        }

        return Scaffold(
          // Set the background color dynamically
          backgroundColor: primaryBg,
          body: Column(
            children: [
              // Header section
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  color: primaryBg, // Ensure it fills the header space
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wallet Summary',
                            style: TextStyle(
                              color: dynamicAccentColor,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Overview of your finances',
                            style: TextStyle(
                              color: headerSecondaryTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: dynamicAccentColor,
                        size: 34,
                      ),
                    ],
                  ),
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  // Padding adjusted to account for the fixed height bottom cards
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 150),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weekly Summary
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        // Use the card background color
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              // Softer shadow for light theme, darker for dark theme
                              color: Colors.black.withOpacity(darkMode ? 0.4 : 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          '📅 Last 7 Days → Income: ₹$weeklyIncome | Expense: ₹$weeklyExpense',
                          style: TextStyle(
                            color: cardContentTextColor.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      // Daily List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dailyList.length,
                        itemBuilder: (context, index) {
                          final day = dailyList[index];
                          final net = day['income'] - day['expense'];

                          return Dismissible(
                            key: UniqueKey(),
                            background: _dismissibleBg(
                              Icons.edit,
                              Colors.blue.shade700,
                              Alignment.centerLeft,
                            ),
                            secondaryBackground: _dismissibleBg(
                              Icons.delete,
                              Colors.red.shade700,
                              Alignment.centerRight,
                            ),
                            onDismissed: (direction) async {
                              final dayStr = DateFormat(
                                'yyyy-MM-dd',
                              ).format(day['date']);
                              final transactionsOfDay = this.box.values.cast<Add_data>()
                                  .where(
                                    (element) =>
                                        DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(element.datetime) ==
                                        dayStr,
                                  )
                                  .toList();

                              if (direction == DismissDirection.endToStart) {
                                for (var item in transactionsOfDay) {
                                  await item.delete();
                                }
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Deleted all transactions of ${DateFormat('EEE, dd MMM').format(day['date'])}',
                                    ),
                                  ),
                                );
                              } else {
                                _showEditDialog(transactionsOfDay, darkMode);
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(darkMode ? 0.35 : 0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat(
                                      'EEEE, dd MMM yyyy',
                                    ).format(day['date']),
                                    style: TextStyle(
                                      color: cardContentTextColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Income: ₹${day['income']}',
                                        style: TextStyle(
                                          color: incomeColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        'Expense: ₹${day['expense']}',
                                        style: TextStyle(
                                          color: expenseColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      // ⭐ FIX APPLIED: Set Net color to dynamicAccentColor always.
                                      Text(
                                        'Net: ₹$net',
                                        style: TextStyle(
                                          color: dynamicAccentColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Category Cards
              Container(
                // ⭐ FIX APPLIED: Decreased height from 155 to 140
                height: 140, 
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 10,
                  top: 6,
                ),
                color: primaryBg,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categorySummary.keys.length,
                  itemBuilder: (context, index) {
                    final cat = categorySummary.keys.elementAt(index);
                    final income = categorySummary[cat]!['income']!;
                    final expense = categorySummary[cat]!['expense']!;
                    final net = income - expense;

                    return Container(
                      width: 145,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          // Lighter gradient in Light Theme, Darker in Dark Theme
                          colors: net >= 0
                              ? (darkMode ? [Colors.green.shade700, Colors.green.shade900] : [Colors.green.shade400, Colors.green.shade600])
                              : (darkMode ? [Colors.red.shade700, Colors.red.shade900] : [Colors.red.shade400, Colors.red.shade600]),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(darkMode ? 0.45 : 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      // ⭐ FIX APPLIED: Reduced vertical padding from 8 to 5
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), 
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            cat,
                            softWrap: true, 
                            maxLines: 2,
                            overflow: TextOverflow.clip,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4), 
                          Text(
                            'Income: ₹$income',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Expense: ₹$expense',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          // ⭐ FIX APPLIED: Use cardNetColor for Net
                          Text(
                            'Net: ₹$net',
                            style: TextStyle(
                              color: cardNetColor, // Using the new, highly visible color
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dismissibleBg(IconData icon, Color color, Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.edit, color: Colors.white),
    );
  }

  // Pass darkMode flag to the dialog builder
  void _showEditDialog(List<Add_data> transactions, bool darkMode) {
    // Dynamic Color Selection for the Dialog
    final Color dialogBg = darkMode ? cardDark : cardLight;
    final Color mainTextColor = darkMode ? mainTextDark : mainTextLight;
    final Color secondaryTextColor = darkMode ? secondaryTextDark : Colors.black54;
    final Color dynamicAccentColor = darkMode ? amberHighlight : primaryAccent;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text(
          'Edit Transactions',
          style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: transactions.length,
            itemBuilder: (context, i) {
              final tx = transactions[i];
              TextEditingController amountController = TextEditingController(
                text: tx.amount,
              );
              TextEditingController explainController = TextEditingController(
                text: tx.explain,
              );
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tx.name} (${tx.IN})',
                      style: TextStyle(color: mainTextColor),
                    ),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: mainTextColor),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        labelStyle: TextStyle(color: secondaryTextColor),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: dynamicAccentColor),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: secondaryTextColor.withOpacity(0.5)),
                        ),
                      ),
                    ),
                    TextField(
                      controller: explainController,
                      style: TextStyle(color: mainTextColor),
                      decoration: InputDecoration(
                        labelText: 'Explain',
                        labelStyle: TextStyle(color: secondaryTextColor),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: dynamicAccentColor),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: secondaryTextColor.withOpacity(0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dynamicAccentColor, // Use the accent color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        tx.amount = amountController.text;
                        tx.explain = explainController.text;
                        await tx.save();
                        // Call setState on the parent screen to refresh the list
                        if (mounted) {
                          setState(() {});
                        }
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.black, // Dark text on accent
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Divider(color: secondaryTextColor.withOpacity(0.5)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}