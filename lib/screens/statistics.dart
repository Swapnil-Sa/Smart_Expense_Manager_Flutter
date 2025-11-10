// statistics.dart
// ignore_for_file: use_super_parameters, non_constant_identifier_names, sized_box_for_whitespace, sort_child_properties_last, unused_import, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_application/Widgets/chart.dart';
import 'package:flutter_application/data/model/add_date.dart';
import 'package:flutter_application/data/top.dart';
import 'package:flutter_application/data/utility.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; 

// Correctly declare ValueNotifier with type int
ValueNotifier<int> kj = ValueNotifier<int>(0);

class Statistics extends StatefulWidget {
  const Statistics({Key? key}) : super(key: key);

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  final Box userBox = Hive.box('userBox');

  // --- THEME COLORS (Consistent with other files) ---
  // Dark Theme Colors
  static const Color primaryDark = Color(0xFF0D1829); // Main Background
  static const Color cardDark = Color(0xFF1B2C42); // Card Background
  static const Color amberHighlight = Color(0xFFE5B80B); // Dark Accent/Active
  static const Color secondaryTextDark = Colors.white70;
  static const Color mainTextDark = Colors.white;

  // Light Theme Colors
  // Deep Green Background 
  static const Color primaryLight = Color.fromARGB(255, 240, 218, 187); 
  
  // ⚪️ Transaction Card Background: Set to White
  static const Color cardLight = Colors.white; 

  // 🌟 Selector Button Background (Unselected) - Almond color for separation
  static const Color selectorButtonBgLight = Color.fromARGB(255, 251, 251, 250); 
  
  // The bright green accent color used for the title and selected text
  static const Color brightAccentLight = Color.fromARGB(255, 105, 128, 60); 
  // RETAINED: Darker green for chart line
  static const Color darkAccentLight = Color(0xFF3F8C25); 
  static const Color mainTextLight = Colors.black; // Main text color
  static const Color secondaryTextLight = Colors.black54; // Secondary text color

  static const double cardRadius = 14.0;
  static const double padding = 18.0;
  // ----------------------

  List<String> day = ['Day', 'Week', 'Month', 'Year'];
  late List<List<Add_data>> f;
  List<Add_data> a = [];
  int index_color = 0;

  @override
  void initState() {
    super.initState();
    // Initialize f with data from utility functions
    f = [
      today(),
      week(),
      month(),
      year(),
    ];
    a = f[0];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: userBox.listenable(keys: ['darkMode']),
      builder: (context, box, child) {
        final bool darkMode = userBox.get('darkMode', defaultValue: false);

        // Dynamic Colors
        final Color scaffoldBg = darkMode ? primaryDark : primaryLight;
        
        // Card Background (for Transaction Cards)
        final Color cardBg = darkMode ? cardDark : cardLight; 
        
        // Selector Button Background (unselected)
        final Color selectorBg = darkMode ? cardDark : selectorButtonBgLight;
        
        final Color headerColor = darkMode ? mainTextDark : mainTextLight;
        final Color primaryTextColor = darkMode ? mainTextDark : mainTextLight;
        final Color secondaryTextColor = darkMode ? secondaryTextDark : secondaryTextLight;
        
        // Accent color (Statistics header, unselected buttons text)
        final Color accentColor = darkMode ? amberHighlight : brightAccentLight; 
        
        // Selected Button Background (white in light mode)
        final Color selectedButtonBg = darkMode ? cardDark : cardLight; 
        
        // The color for the SELECTED border/text
        final Color selectedButtonBorderColor = darkMode ? amberHighlight : brightAccentLight; 
        // The color for the chart line 
        final Color chartLineColor = darkMode ? amberHighlight : darkAccentLight;

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SafeArea(
            child: ValueListenableBuilder<int>(
              valueListenable: kj,
              builder: (BuildContext context, int value, Widget? child) {
                index_color = value;
                a = f[value];
                return custom(
                  darkMode: darkMode,
                  cardBg: cardBg,
                  selectorBg: selectorBg, 
                  headerColor: headerColor,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  accentColor: accentColor,
                  selectedButtonBg: selectedButtonBg,
                  selectedButtonBorderColor: selectedButtonBorderColor,
                  chartLineColor: chartLineColor, 
                );
              },
            ),
          ),
        );
      },
    );
  }

  CustomScrollView custom({
    required bool darkMode,
    required Color cardBg,
    required Color selectorBg, 
    required Color headerColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color accentColor,
    required Color selectedButtonBg,
    required Color selectedButtonBorderColor,
    required Color chartLineColor, 
  }) {
    a.sort((a, b) => b.datetime.compareTo(a.datetime));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: padding),
                child: Text(
                  'Statistics',
                  style: TextStyle(
                    // CORRECTED: Uses the brightAccentLight in Light Mode
                    color: darkMode ? mainTextDark : accentColor, 
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Time Period Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: padding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    4,
                    (index) {
                      bool isSelected = index_color == index;
                      return GestureDetector(
                        onTap: () {
                          kj.value = index;
                        },
                        child: Container(
                          height: 40,
                          width: 80,
                          decoration: BoxDecoration(
                            // Use the dedicated selectorBg for UNSELECTED buttons
                            color: isSelected ? selectedButtonBg : selectorBg, 
                            borderRadius: BorderRadius.circular(cardRadius * 0.75),
                            border: Border.all(
                              // The border color is Deep Green/Accent color
                              color: isSelected ? selectedButtonBorderColor : primaryTextColor.withOpacity(0.3),
                              width: isSelected ? 2 : 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(darkMode ? 0.5 : 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            day[index],
                            style: TextStyle(
                              // Text color is Deep Green for selected, Black for unselected in Light Mode
                              color: isSelected ? selectedButtonBorderColor : primaryTextColor,
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Chart Widget
              Chart(
                indexx: index_color,
                // If your Chart widget takes a line color, pass it here:
                // lineColor: chartLineColor, 
              ), 
              const SizedBox(height: 20),
              // Top Spending Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: padding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Top Transactions',
                      style: TextStyle(
                        // REMAINS: White in Dark, Black in Light (on the Deep Green background)
                        color: darkMode ? mainTextDark : primaryTextColor, 
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.swap_vert,
                      size: 25,
                      // REMAINS: Secondary text color
                      color: secondaryTextColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: padding, vertical: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg, // This is the Transaction Card (White in Light Mode)
                    borderRadius: BorderRadius.circular(cardRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(darkMode ? 0.3 : 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        color: cardBg,
                        child: Image.asset('images/${a[index].name}.png', height: 35),
                      ),
                    ),
                    title: Text(
                      a[index].name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    subtitle: Text(
                      '${a[index].datetime.year}-${a[index].datetime.month}-${a[index].datetime.day}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: secondaryTextColor,
                      ),
                    ),
                    trailing: Text(
                      '₹${NumberFormat('#,##0').format(int.tryParse(a[index].amount) ?? 0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: a[index].IN == 'Income' ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ),
              );
            },
            childCount: a.length,
          ),
        ),
      ],
    );
  }
}