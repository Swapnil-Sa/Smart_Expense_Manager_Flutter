// privacy_policy.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  // --- DARK THEME COLORS (Retained/Aligned) ---
  static const Color primaryDark = Color(0xFF0F111A); // Main Background/AppBar in Dark
  static const Color mainTextDark = Colors.white;
  static const Color secondaryTextDark = Colors.white70;

  // --- LIGHT THEME COLORS (UPDATED TO CONSISTENT GREEN/WHITE PALETTE) ---
  static const Color primaryLight = Color.fromARGB(255, 240, 218, 187); 
  static const Color cardLight = Color.fromARGB(255, 105, 128, 60);
  static const Color mainTextLight = Colors.black; // Not used as much, but for generic black text
  static const Color secondaryTextLight = Colors.white70; // Faded white text on deep green
  
  // NOTE: primaryAccent is no longer needed since the AppBar color is now primaryLight

  // ⭐ ENHANCED POLICY TEXT
  static const String enhancedPolicyText = """
At MyFinance App, we are deeply committed to protecting your privacy. Our approach to data management is focused exclusively on security and local storage.

Key principles of our Privacy Policy:

1.  **Zero External Data Sharing:** We do not collect, share, sell, or disclose any personal or financial data to third-party entities, servers, or external services.

2.  **Local Data Storage:** All user data, including transaction records, category definitions, and profile information, is stored exclusively on your device using Hive local storage for maximum privacy and security.

3.  **No Server Interaction:** MyFinance operates entirely offline; your data never leaves your personal device.

By continuing to use the MyFinance application, you acknowledge and agree to this Privacy Policy and the exclusive use of local data storage as described herein.
""";


  @override
  Widget build(BuildContext context) {
    final userBox = Hive.box('userBox');
    final bool isDarkMode = userBox.get('darkMode', defaultValue: false); 

    // Determine colors based on the state
    final Color primaryBg = isDarkMode ? primaryDark : primaryLight;
    // AppBar uses primaryDark in Dark Mode, and primaryLight in Light Mode (Deep Green)
    final Color appBarBg = isDarkMode ? primaryDark : primaryLight; 
    
    // Text/Icon color for the AppBar (Deep Green in Light Mode, White in Dark Mode)
    final Color appBarContentColor = isDarkMode ? mainTextDark : cardLight; 
    
    // Text color for the body (White on the Light BG, White70 on the Dark BG)
    final Color bodyTextColor = isDarkMode ? secondaryTextDark : mainTextLight; 

    return Scaffold(
      backgroundColor: primaryBg,
      appBar: AppBar(
        title: Text(
          "Privacy Policy",
          style: TextStyle(
            color: appBarContentColor, // Deep Green in Light Mode
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: appBarBg,
        iconTheme: IconThemeData(color: appBarContentColor), // Deep Green icon in Light Mode
        elevation: 0, 
      ),
      body: SingleChildScrollView( // Changed to SingleChildScrollView for safety
        padding: const EdgeInsets.all(16.0),
        child: Text(
          enhancedPolicyText,
          style: TextStyle(
            fontSize: 16, 
            height: 1.5,
            color: bodyTextColor, // Black text on Light BG, White70 on Dark BG
          ),
        ),
      ),
    );
  }
}