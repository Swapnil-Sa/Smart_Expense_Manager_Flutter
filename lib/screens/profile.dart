// ignore_for_file: use_super_parameters, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:io';
// REQUIRED FOR SYSTEMNAVIGATOR.POP()
import 'package:flutter/services.dart'; 

import '../data/model/add_date.dart';
import 'settings_screen.dart';
import 'privacy_policy.dart';

// NOTE: You will need to replace this with the actual path to your LoginScreen
// import 'package:your_app_path/login_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Box userBox;
  String? _profileImagePath;

  // --- DARK THEME COLORS (KEEP) ---
  static const Color primaryDark = Color(0xFF0F111A); // Dark mode base
  static const Color cardDark1 = Color(0xFF1F2233); // Gradient start
  static const Color cardDark2 = Color(0xFF2A2F45); // Gradient end
  static const Color mainTextDark = Colors.white; // Main text color
  static const Color secondaryTextDark = Colors.white70; // White70 text
  static const Color cardBackgroundDark = Color(0xFF1F2233); // Solid card bg
  
  // --- LIGHT THEME COLORS (KEEP) ---
  static const Color primaryLight = Color.fromARGB(255, 240, 218, 187);
  static const Color cardLight1 = Color(0xFFFFFFFF); // Pure white for card top gradient
  static const Color cardLight2 = Color.fromARGB(255, 247, 248, 249); // Soft off-white for card bottom gradient
  static const Color mainTextLight = Color.fromARGB(255, 105, 128, 60);
  static const Color secondaryTextLight = Color.fromARGB(255, 105, 128, 60);
  static const Color cardBackgroundLight = Color(0xFFFFFFFF); // Pure white for action tiles on green background

  // --- COMMON ACCENT COLORS (KEEP) ---
  static const Color accentAmber = Colors.amber; // Amber highlights (Used in Dark Mode)
  static const Color primaryAccent = Color.fromARGB(255, 105, 128, 60); // For accents in Light Mode
  
  // NEW: Dark Green for Light Mode icons on white background
  static final Color darkGreenIcon = const Color.fromARGB(255, 105, 128, 60);

  @override
  void initState() {
    super.initState();
    userBox = Hive.box('userBox');
    _loadProfileData();
  }

  void _loadProfileData() {
    setState(() {
      _profileImagePath = userBox.get('profileImagePath');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check for data box before accessing it, necessary for production Hive apps
    final Box<Add_data> box = Hive.isBoxOpen('data') ? Hive.box<Add_data>('data') : throw Exception("Data box not open");
    
    final bool isDarkMode = userBox.get('darkMode', defaultValue: false);

    // Apply colors based on theme mode
    final Color primaryBg = isDarkMode ? primaryDark : primaryLight;
    final Color mainTextColor = isDarkMode ? mainTextDark : mainTextLight;
    final Color secondaryTextColor = isDarkMode ? secondaryTextDark : secondaryTextLight;
    final Color cardBgColor = isDarkMode ? cardBackgroundDark : cardBackgroundLight;
    final List<Color> cardGradientColors = isDarkMode
        ? const [cardDark1, cardDark2]
        : const [cardLight1, cardLight2];
    final Color appBarColor = isDarkMode ? primaryDark : primaryLight;
    final Color balanceTextColor = isDarkMode ? Colors.white : Colors.black;

    // Dynamic Accent Colors (The bright green/amber)
    final Color dynamicAccentColor = isDarkMode ? accentAmber : primaryAccent;
    
    // FIX: Action tile icons (Settings, Privacy, Logout) use darkGreenIcon in Light Mode for contrast on the white card.
    final Color dynamicTileIconColor = isDarkMode ? dynamicAccentColor : darkGreenIcon;
    
    // Text color for titles and list items sitting on cards
    final Color cardContentTextColor = isDarkMode ? mainTextDark : Colors.black;

    double totalIncome = 0;
    double totalExpense = 0;
    for (var item in box.values) {
      if (item.IN == 'Income') {
        totalIncome += double.tryParse(item.amount) ?? 0;
      } else {
        totalExpense += double.tryParse(item.amount) ?? 0;
      }
    }
    double totalBalance = totalIncome - totalExpense;

    String userName = userBox.get('name', defaultValue: 'Swapnil Sanjeev');
    String email = userBox.get('email', defaultValue: 'swapnil@example.com');

    return Scaffold(
      backgroundColor: primaryBg,
      appBar: AppBar(
        title: Text(
          "Profile",
          style: TextStyle(
            // --- MODIFIED LINE: Use the bright accent color in Light Mode for the title ---
            color: isDarkMode ? mainTextColor : dynamicAccentColor,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        backgroundColor: appBarColor,
        elevation: isDarkMode ? 0 : 2,
        // The icon theme color must also be the bright accent color for light mode consistency
        iconTheme: IconThemeData(color: isDarkMode ? mainTextColor : dynamicAccentColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode ? cardGradientColors : [primaryLight, primaryLight.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.5)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                children: [
                  // --- START PROFILE AVATAR CONTAINER ---
                  Container(
                    // 🎯 MODIFIED: Increased width/height to 128 (radius 62 * 2 + border 2*2 = 128)
                    width: 128, 
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // 🎯 MODIFIED: Border width increased from 2 to 4 to cover the gap.
                      border: isDarkMode 
                          ? null // No border in dark mode
                          : Border.all(color: Colors.black, width: 4), // Black border in light mode
                      boxShadow: isDarkMode
                          ? null // No specific shadow for dark mode, relying on the outer container's shadow
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1), // Softer, less prominent shadow in light mode
                                spreadRadius: 0,
                                blurRadius: 4,
                                offset: const Offset(0, 2), // Gentle bottom shadow
                              ),
                            ],
                    ),
                    child: CircleAvatar(
                      // 🎯 MODIFIED: Radius increased from 60 to 62.
                      radius: 64,
                      // FIX: Match the outer CircleAvatar background to the main screen background color (primaryBg)
                      backgroundColor: primaryBg,
                      child: CircleAvatar(
                        // 🎯 MODIFIED: Radius increased from 55 to 58.
                        radius: 60,
                        backgroundImage: _profileImagePath != null
                            ? FileImage(File(_profileImagePath!)) as ImageProvider
                            : const AssetImage('images/Transfer.png'),
                        backgroundColor: isDarkMode ? cardDark1 : primaryLight.withOpacity(0.7),
                      ),
                    ),
                  ),
                  // --- END PROFILE AVATAR CONTAINER ---
                  const SizedBox(height: 15),
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: mainTextColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 16,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Summary Section
            _buildSummaryCard(
              totalBalance,
              totalIncome,
              totalExpense,
              isDarkMode,
              cardGradientColors,
              balanceTextColor,
              secondaryTextColor,
              dynamicAccentColor,
              cardContentTextColor
            ),

            const SizedBox(height: 20),

            // Action Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildActionTile(
                    Icons.settings,
                    "Settings",
                    () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                      _loadProfileData();
                    },
                    cardContentTextColor,
                    cardBgColor,
                    dynamicTileIconColor
                  ),
                  _buildActionTile(
                    Icons.lock,
                    "Privacy Policy",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                    cardContentTextColor,
                    cardBgColor,
                    dynamicTileIconColor
                  ),
                  // Renamed from "Logout" to "Exit" in the previous step
                  _buildActionTile(
                    Icons.logout,
                    "Exit",
                    () {
                      _showLogoutDialog(context, isDarkMode, cardBgColor);
                    },
                    cardContentTextColor,
                    cardBgColor,
                    dynamicTileIconColor
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            Text(
              "© ${DateFormat('yyyy').format(DateTime.now())} MyFinance App",
              style: TextStyle(color: secondaryTextColor.withOpacity(0.5), fontSize: 13),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double balance, double income, double expense, bool isDarkMode, List<Color> gradientColors, Color balanceTextColor, Color secondaryTextColor, Color dynamicAccentColor, Color cardContentTextColor) {
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.4)
                  : Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Account Summary",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? dynamicAccentColor : Colors.black,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _summaryTile(
                    "Balance",
                    format.format(balance),
                    balanceTextColor,
                    cardContentTextColor,
                  ),
                  _summaryTile(
                    "Income",
                    format.format(income),
                    isDarkMode ? Colors.green : Colors.green[700]!,
                    cardContentTextColor,
                  ),
                  _summaryTile(
                    "Expense",
                    format.format(expense),
                    isDarkMode ? Colors.red : Colors.redAccent,
                    cardContentTextColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryTile(String title, String value, Color valueColor, Color titleColor) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap, Color titleColor, Color tileBgColor, Color iconColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: tileBgColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 4,
        ),
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: titleColor,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: iconColor,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, bool isDarkMode, Color dialogBgColor) {
    final Color mainTextColor = isDarkMode ? mainTextDark : Colors.black;
    final Color secondaryTextColor = isDarkMode ? secondaryTextDark : Colors.black87;
    final Color accentColor = isDarkMode ? accentAmber : primaryAccent;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBgColor,
        title: Text(
          "Exit App",
          style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to close the app?",
          style: TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: accentColor)),
          ),
          TextButton(
            // FIXED LOGOUT ACTION: Closes the application.
            onPressed: () {
              Navigator.pop(ctx); // Close the dialog
              
              // Use SystemNavigator.pop() to exit the app completely.
              SystemNavigator.pop();
            },
            child: const Text(
              "Close",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}