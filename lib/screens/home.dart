// ignore_for_file: deprecated_member_use, use_super_parameters, sort_child_properties_last, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:flutter_application/data/model/add_date.dart';
import 'package:flutter_application/data/utility.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application/screens/chatbot_screen.dart'; // Fixed illegal character here

class Home extends StatefulWidget {
  const Home({Key? key, required onSettingsUpdated}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

// ⚠️ FIX: Added WidgetsBindingObserver to listen for screen focus changes
class _HomeState extends State<Home> with WidgetsBindingObserver {
  // --- THEME CONSTANTS ---
  static const Color primaryDark = Color(0xFF0F111A);
  static const Color cardDark = Color(0xFF1F2332);
  
  // 🟡 NEW LIGHT THEME: FDFBD4 Cream background and coordinated colors
  static const Color primaryLight = Color.fromARGB(255, 240, 218, 187); // Set to FDFBD4 (Cream)
  static const Color cardLight = Colors.white; // Card background (White for contrast)
  static const Color accentGreenLight = Color(0xFF004D40); // Dark Green for Income/Budget Text
  
  static const Color brightAccentLight = Color.fromARGB(255, 105, 128, 60); // Medium Green-Blue for Accent/Progress Bar/Buttons
  static const Color expenseCircleColor = Color(0xFFDD5C5C); // Red for Expense
  static const Color darkAccentColor = Colors.amber;
  static const double cardRadius = 16.0;
  static const double padding = 18.0;
  
  // ⭐️ UPDATED: App Name to MoneyHive
  static const String appName = 'MoneyHive';
  static const String financialQuote = 'Control your expenses, control your future.';


  // --- Data ---
  final box = Hive.box<Add_data>('data');
  late Box userBox;
  final List<String> day = [
    'Monday',
    "Tuesday",
    "Wednesday",
    "Thursday",
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    userBox = Hive.box('userBox');
    // ⚠️ FIX: Add observer to track when the screen is active
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // ⚠️ FIX: Remove observer when the widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ⚠️ FIX: Method to catch when the screen resumes (e.g., after popping Add screen)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Force a rebuild to update all data, including the budget bar
      setState(() {});
    }
  }

  // Helper function to format currency
  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(amount.abs().round());
  }
  
  // Helper to format the month key for Hive storage (e.g., '2025-11')
  String _formatMonthKey(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  // Function to calculate the monthly limit based on the current date
  int _getCurrentMonthlyLimit(Box userBox) {
    final now = DateTime.now();
    final currentMonthKey = _formatMonthKey(now);
    
    final budgetsFromHive = userBox.get('monthlyBudgets', defaultValue: {});
    Map<String, int> monthlyBudgets = {};

    if (budgetsFromHive is Map) {
      monthlyBudgets = budgetsFromHive.cast<String, int>();
    }

    return monthlyBudgets[currentMonthKey] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 LISTEN TO THE USER BOX for theme and budget limit changes
    return ValueListenableBuilder(
      valueListenable: userBox.listenable(keys: ['darkMode', 'monthlyBudgets']),
      builder: (context, userBoxListener, child) {
        final bool isDarkMode = userBox.get('darkMode', defaultValue: false);
        
        // 🔑 CORRECTLY FETCH THE MONTHLY LIMIT
        final int monthlyLimit = _getCurrentMonthlyLimit(userBox);

        // --- Theme Colors ---
        final Color primaryBg = isDarkMode ? primaryDark : primaryLight; // Light Mode is FDFBD4
        // 🟡 NEW: Header is the primary light background color
        final Color headerBg = isDarkMode ? cardDark : primaryLight;
        // 🟡 NEW: Card 1 is now White
        final Color cardBg1 = isDarkMode ? cardDark : cardLight;
        // 🟡 NEW: Card 2 is a subtle, warmer cream/beige
        final Color cardBg2 = isDarkMode
            ? const Color(0xFF2E3347)
            : const Color(0xFFF2F1E8); // Adjusted to F2F1E8
        final Color mainTextColor = isDarkMode ? Colors.white : Colors.black;
        final Color secondaryOnCardColor = isDarkMode
            ? Colors.white70
            : Colors.black87;
        // 🟡 NEW: Income Text Color uses the dark green accent
        final Color incomeTextColor = isDarkMode
            ? brightAccentLight
            : accentGreenLight;
        final Color expenseTextColor = expenseCircleColor;
        // 🟡 NEW: Dynamic Accent is the vibrant Green-Blue
        final Color dynamicAccentColor = isDarkMode
            ? darkAccentColor
            : brightAccentLight;

        return Scaffold(
          backgroundColor: primaryBg,
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatbotScreen()),
            ),
            // Floating Action Button uses the new bright accent color
            backgroundColor: dynamicAccentColor,
            child: Icon(Icons.chat_bubble_outline, color: primaryBg),
            shape: const CircleBorder(),
            heroTag: 'chatbot_button_tag',
          ),
          body: SafeArea(
            child: ValueListenableBuilder(
              valueListenable: box.listenable(), // Listening to transaction data
              builder: (context, value, child) {
                // 🔑 CRITICAL: Calculate expenses INSIDE the transaction data listener
                final double currentExpenses = expenses().toDouble();
                
                return CustomScrollView(
                  slivers: [
                    // 1. Header Section (Balance Card)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        // Fixed height for header section
                        height: 330,
                        child: _head(
                          context,
                          headerBg,
                          cardBg1,
                          secondaryOnCardColor,
                          mainTextColor,
                          incomeTextColor,
                          expenseTextColor,
                        ),
                      ),
                    ),

                    // 2. Monthly Budget Progress Bar (The ONLY Budget Widget)
                    if (monthlyLimit > 0)
                      SliverToBoxAdapter(
                        child: _buildBudgetProgressCard(
                          monthlyLimit,
                          currentExpenses,
                          cardBg1,
                          mainTextColor,
                          secondaryOnCardColor,
                          brightAccentLight, // Uses the bright accent for progress
                          expenseCircleColor
                        ),
                      ),
                    
                    // 3. Transactions Title
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: padding,
                          vertical: 15,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Transactions History',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 19,
                                color: mainTextColor,
                              ),
                            ),
                            Text(
                              'See all',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: dynamicAccentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 4. Transaction List
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final history = value.values.toList()
                          ..sort((a, b) => b.datetime.compareTo(a.datetime));
                        return _buildTransactionListItem(
                          history[index],
                          cardBg1,
                          cardBg2,
                          mainTextColor,
                          secondaryOnCardColor,
                          incomeTextColor,
                          expenseTextColor,
                        );
                      }, childCount: value.length),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------------
  // WIDGET: Combined Budget Progress Card
  // ----------------------------------------------------------------
  Widget _buildBudgetProgressCard(
    int limit,
    double currentExpense,
    Color cardBg,
    Color mainTextColor,
    Color secondaryOnCardColor,
    Color defaultProgressColor,
    Color exceedColor,
  ) {
    final double absoluteExpense = currentExpense.abs();
    final double progress = (absoluteExpense / limit).clamp(0.0, 1.0);
    final double remainingAmount = limit - absoluteExpense;

    Color progressColor = defaultProgressColor;
    String statusMessage = 'You are within your monthly budget.';
    
    if (progress >= 1.0) {
      progressColor = exceedColor;
      statusMessage = '⚠️ OVER BUDGET: Exceeded by ${_formatCurrency(remainingAmount.abs())}';
    } else if (progress >= 0.85) {
      progressColor = Colors.orange;
      statusMessage = '🚨 CAUTION: Only ${_formatCurrency(remainingAmount)} remaining!';
    }


    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: padding,
        vertical: 12,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: progressColor.withOpacity(0.4), width: progress >= 0.85 ? 1.5 : 0),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Budget Progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: mainTextColor,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 20,
                backgroundColor: secondaryOnCardColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatCurrency(currentExpense)} / ${_formatCurrency(limit.toDouble())}',
              style: TextStyle(
                fontSize: 14,
                color: secondaryOnCardColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              statusMessage,
              style: TextStyle(
                fontSize: 13,
                color: progressColor,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // WIDGET: Transaction List Item
  // ----------------------------------------------------------------
  Widget _buildTransactionListItem(
    Add_data history,
    Color cardBg1,
    Color cardBg2,
    Color mainTextColor,
    Color secondaryOnCardColor,
    Color incomeTextColor,
    Color expenseTextColor,
  ) {
    return Dismissible(
      key: UniqueKey(),
      onDismissed: (direction) => history.delete(),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: padding * 0.8,
          vertical: 8,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg1,
            borderRadius: BorderRadius.circular(cardRadius * 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: cardBg2,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(5),
              child: Image.asset('images/${history.name}.png', height: 40),
            ),
            title: Text(
              history.name,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: mainTextColor,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${day[history.datetime.weekday - 1]} ${history.datetime.day}/${history.datetime.month}/${history.datetime.year}',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: secondaryOnCardColor,
                  ),
                ),
                if (history.explain != null && history.explain.isNotEmpty)
                  Text(
                    history.explain,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: secondaryOnCardColor,
                    ),
                  ),
              ],
            ),
            trailing: Text(
              '₹ ${history.amount}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: history.IN == 'Income'
                    ? incomeTextColor
                    : expenseTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // WIDGET: Head Section (Total Balance Card)
  // ----------------------------------------------------------------
  Widget _head(
    BuildContext context,
    Color headerBg,
    Color cardBg1,
    Color secondaryOnCardColor,
    Color mainTextColor,
    Color incomeTextColor,
    Color expenseTextColor,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.85;
    // 🟡 NEW: Define icon background color (Bright Accent)
    final Color iconBackground = brightAccentLight;

    return Stack(
      children: [
        Column(
          children: [
            Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                // 🟡 NEW: Header is the FDFBD4 background color
                color: headerBg,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(cardRadius),
                  bottomRight: Radius.circular(cardRadius),
                ),
              ),
              child: Stack(
                children: [
                  // ⭐️ NOTIFICATION ICON: Moved slightly for better fit
                  Positioned(
                    top: 35,
                    // Adjusted right padding slightly to prevent overlap with text
                    right: padding * 0.7, 
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        height: 38, // Slightly reduced height
                        width: 38, // Slightly reduced width
                        color: Colors.black.withOpacity(0.15), // Use black opacity for contrast
                        child: Icon(
                          Icons.notifications_active_outlined,
                          size: 23, // Slightly reduced icon size
                          color: mainTextColor.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    // Increased right padding for the text container to avoid icon overlap
                    padding: const EdgeInsets.only(top: 35, left: padding, right: padding * 3), 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ⭐️ QUOTE
                        Text(
                          financialQuote,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            // Text color uses secondaryOnCardColor (Black87)
                            color: secondaryOnCardColor,
                          ),
                        ),
                        // ⭐️ APP NAME
                        Text(
                          appName,
                          style: TextStyle(
                            fontWeight: FontWeight.w800, // Make it very bold for the name
                            fontSize: 24, // Make it slightly larger
                            // Text color uses mainTextColor (Black)
                            color: mainTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // This is the Total Balance Card (170 height)
        Positioned(
          top: 140,
          left: (screenWidth - cardWidth) / 2,
          child: Container(
            height: 170,
            width: cardWidth,
            decoration: BoxDecoration(
              border: Border.all(
                color: secondaryOnCardColor.withOpacity(0.3),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  // Use a light shadow
                  color: Colors.black.withOpacity(0.08),
                  offset: const Offset(0, 8),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
              // Card color is cardLight (White)
              color: cardBg1,
              borderRadius: BorderRadius.circular(cardRadius),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Balance',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: secondaryOnCardColor,
                        ),
                      ),
                      Icon(Icons.more_horiz, color: secondaryOnCardColor),
                    ],
                  ),
                ),
                const SizedBox(height: 7),
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Row(
                    children: [
                      Text(
                        _formatCurrency(total().toDouble()),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                          color: mainTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 21),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Income Row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: iconBackground, // Medium Green-Blue
                            child: Icon(
                              Icons.arrow_downward,
                              // Use Cream color for icon for contrast
                              color: headerBg,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Income',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: secondaryOnCardColor,
                            ),
                          ),
                        ],
                      ),
                      // Expense Row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: expenseCircleColor,
                            child: Icon(
                              Icons.arrow_upward,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Expenses',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: secondaryOnCardColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatCurrency(income().toDouble()),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          color: incomeTextColor, // Dark Green
                        ),
                      ),
                      Text(
                        '-${_formatCurrency(expenses().toDouble())}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          color: expenseTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}