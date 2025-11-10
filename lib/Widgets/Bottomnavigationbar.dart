// lib/Widgets/Bottomnavigationbar.dart

// ignore_for_file: non_constant_identifier_names, use_super_parameters, sort_child_properties_last, file_names, unused_field, deprecated_member_use, unused_import

import 'package:flutter/material.dart';

// Import essential/unique screens normally
import 'package:flutter_application/Screens/add.dart';
import 'package:flutter_application/Screens/statistics.dart';
import 'package:flutter_application/Screens/home.dart';

// Use aliased imports for Profile and Wallet to prevent naming/casing conflicts
import 'package:flutter_application/screens/profile.dart' as profile;
import 'package:flutter_application/screens/wallet.dart' as wallet;

import 'package:hive_flutter/hive_flutter.dart';

class Bottom extends StatefulWidget {
  final VoidCallback onSettingsUpdated; // ✅ Added properly

  const Bottom({Key? key, required this.onSettingsUpdated}) : super(key: key);

  @override
  State<Bottom> createState() => _BottomState();
}

class _BottomState extends State<Bottom> {
  final Box userBox = Hive.box('userBox');

  // --- THEME COLORS ---

  // Dark Theme Colors
  static const Color primaryDark = Color(0xFF0D1829);
  static const Color cardDark = Color(0xFF1B2C42);
  static const Color amberHighlight = Color(0xFFE5B80B);
  static const Color secondaryTextDark = Colors.white70;

  // Light Theme Colors
  static const Color primaryLight = Color.fromARGB(255, 105, 128, 60);
  static const Color cardLight = Colors.white;
  static const Color primaryAccent = Color.fromARGB(255, 240, 218, 187);

  // Inactive icons must be light color on a dark green background
  static const Color activeIconLight = primaryAccent; // Bright Green for active
  static const Color inactiveIconLight = cardLight; // White for inactive

  int index_color = 0;

  @override
  Widget build(BuildContext context) {
    // ✅ Move screens inside build() to use widget.onSettingsUpdated
    final List<Widget> screens = [
      Home(onSettingsUpdated: widget.onSettingsUpdated), // ✅ fixed
      const Statistics(),
      const wallet.WalletScreen(),
      const profile.ProfileScreen(),
    ];

    return ValueListenableBuilder(
      valueListenable: userBox.listenable(keys: ['darkMode']),
      builder: (context, box, child) {
        final bool darkMode = userBox.get('darkMode', defaultValue: false);

        // Dynamic Color Selection based on Theme
        final Color bottomAppBarBg = darkMode ? cardDark : primaryLight;
        final Color activeIconColor =
            darkMode ? amberHighlight : activeIconLight;
        final Color inactiveIconColor =
            darkMode ? secondaryTextDark : inactiveIconLight;
        final Color fabAccentColor = darkMode ? amberHighlight : primaryAccent;
        final Color fabIconColor = darkMode ? primaryDark : Colors.black;

        return Scaffold(
          body: screens[index_color],

          // FLOATING ACTION BUTTON (FAB)
          floatingActionButton: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: fabAccentColor.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              gradient: LinearGradient(
                colors: [fabAccentColor.withOpacity(0.8), fabAccentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const Add_Screen()),
                );
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              shape: const CircleBorder(),
              child: Icon(
                Icons.add,
                color: fabIconColor,
                size: 30,
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,

          // BOTTOM NAVIGATION BAR
          bottomNavigationBar: BottomAppBar(
            color: bottomAppBarBg,
            shape: const CircularNotchedRectangle(),
            notchMargin: 6.0,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                      Icons.home, 0, activeIconColor, inactiveIconColor),
                  _buildNavItem(Icons.bar_chart_outlined, 1, activeIconColor,
                      inactiveIconColor),
                  const SizedBox(width: 20),
                  _buildNavItem(Icons.account_balance_wallet_outlined, 2,
                      activeIconColor, inactiveIconColor),
                  _buildNavItem(Icons.person_outlined, 3, activeIconColor,
                      inactiveIconColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method
  Widget _buildNavItem(
    IconData icon,
    int index,
    Color selectedColor,
    Color unselectedColor,
  ) {
    bool isSelected = index_color == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          index_color = index;
        });
      },
      child: Icon(
        icon,
        size: 28,
        color: isSelected ? selectedColor : unselectedColor,
      ),
    );
  }
}
