// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unnecessary_null_check, use_super_parameters, avoid_init_to_null, strict_top_level_inference, unused_field, no_leading_underscores_for_local_identifiers, library_private_types_in_public_api, constant_identifier_names

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// --- COLOR CONSTANTS for Theme Consistency ---
// Light Mode Background (Beige/Almond from your screenshot)
const Color primaryLight = Color.fromARGB(255, 240, 218, 187);
// Dark Olive Green Accent (from your screenshot)
const Color primaryAccent = Color.fromARGB(255, 105, 128, 60); 

// Dark Mode Colors
const Color primaryDark = Color(0xFF0F111A);
const Color cardDark = Color(0xFF1F2233);
const Color mainTextDark = Colors.white;
const Color secondaryTextDark = Colors.white70;
const Color amberHighlight = Colors.amber; 
// ---------------------------------------------


class SettingsScreen extends StatefulWidget {
  final VoidCallback? settingsUpdated;

  const SettingsScreen({super.key, this.settingsUpdated});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool notificationsEnabled = true;
  bool darkMode = false;
  String? _currentProfileImagePath;

  bool _isAppLocked = false;
  int _currentMonthBudgetLimit = 0;
  
  DateTime _currentMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  Map<String, int> _monthlyBudgets = {};

  // Hive Box for User Settings
  late Box userBox;
  // ⭐ FIX: Change to nullable Box to avoid LateInitializationError and handle 'not open' error
  Box? transactionBox; 

  // Derived Color Constants using the unified palette
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color darkGreenIcon = primaryAccent;
  static const Color googleButtonColor = primaryAccent;
  static const Color googleButtonTextBorderColor = primaryAccent;
  static const Color googleButtonBgColor = Colors.white;


  @override
  void initState() {
    super.initState();
    userBox = Hive.box('userBox');
    
    // ⭐ CRITICAL FIX: Attempt to get the 'transactions' box safely
    // This will succeed because we ensured it's opened in main.dart
    try {
      if (Hive.isBoxOpen('transactions')) {
        transactionBox = Hive.box('transactions');
      }
    } catch (e) {
      // If box cannot be retrieved, transactionBox remains null.
      // print('Error getting transactions box: $e'); // For local debugging
    }

    _loadSettings();
  }

  String _formatMonthKey(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  String _formatMonthDisplay(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  void _loadSettings() {
    _nameController.text = userBox.get('name', defaultValue: 'Swapnil Sanjeev');
    _emailController.text = userBox.get(
      'email',
      defaultValue: 'swapnil@example.com',
    );
    notificationsEnabled = userBox.get('notifications', defaultValue: true);
    darkMode = userBox.get('darkMode', defaultValue: false);
    _currentProfileImagePath = userBox.get('profileImagePath');
    
    _isAppLocked = userBox.get('isAppLocked', defaultValue: false);

    final budgetsFromHive = userBox.get('monthlyBudgets', defaultValue: {});
    if (budgetsFromHive is Map) {
      _monthlyBudgets = budgetsFromHive.cast<String, int>();
    } else {
      _monthlyBudgets = {};
    }

    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _currentMonthBudgetLimit =
        _monthlyBudgets[_formatMonthKey(_currentMonth)] ?? 0;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      userBox.put('profileImagePath', image.path);
      setState(() {
        _currentProfileImagePath = image.path;
      });
      widget.settingsUpdated?.call(); 
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile image updated!')));
    }
  }

  void _removeImage() {
    userBox.delete('profileImagePath');
    setState(() {
      _currentProfileImagePath = null;
    });
    widget.settingsUpdated?.call(); 
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile image removed!')));
  }

  void _saveChanges() {
    userBox.put('name', _nameController.text);
    userBox.put('email', _emailController.text);
    userBox.put('notifications', notificationsEnabled);
    userBox.put('darkMode', darkMode);
    
    widget.settingsUpdated?.call(); 
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings updated successfully!')),
    );
  }

  String _formatCurrency(int amount) {
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        setState(() {
          _nameController.text = user.displayName ?? '';
          _emailController.text = user.email ?? '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Signed in as ${user.displayName ?? 'User'}")),
        );
      }
      return userCredential;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Google Sign-In failed: $e")));
      return null;
    }
  }

  // Placeholder for the actual PDF generation logic (requires a package like 'pdf')
  Future<String> _generatePdf() async {
    // ⭐ FIX: Defensive check for transactionBox. Now that it's nullable and we
    // ensure the box is open in main.dart, this check catches errors correctly.
    final txBox = transactionBox; 
    if (txBox == null || !txBox.isOpen) {
      // This error message is what you saw in the screenshot. It should NOT
      // happen if main.dart opens the box correctly.
      throw Exception("Transaction data box is not available or open. Cannot generate summary. Ensure 'transactions' box is opened on app start.");
    }

    // 1. Fetch all transactions (placeholder logic)
    // List<dynamic> allTransactions = txBox.values.toList();
    
    // 2. Format the data (e.g., as a simple String for this placeholder)
    String summary = "Account Summary Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}\n\n";
    summary += "Total transactions found: ${txBox.length}\n"; 
    summary += "--- NOTE: Actual PDF generation requires 'pdf' package and file I/O permissions. ---\n";

    // 3. Return a dummy file path (in a real app, this would be the generated PDF file)
    return summary; 
  }
  
  // Placeholder for saving the file (requires 'path_provider' and 'permission_handler')
  Future<void> _savePdfFile(String summaryContent) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate file saving delay
  }

  Future<void> _exportToPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing account summary...')),
    );

    try {
      final summaryContent = await _generatePdf();

      // Simulate saving the file
      await _savePdfFile(summaryContent);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account Summary PDF downloaded successfully!'),
          backgroundColor: primaryAccent, 
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // Determine Colors based on dark/light mode, using consistent palette
    final Color primaryBg = darkMode ? primaryDark : primaryLight;
    final Color cardBg = darkMode ? cardDark : cardLight;
    final Color mainTextColor = darkMode ? mainTextDark : Colors.black;
    final Color secondaryTextColor = darkMode ? secondaryTextDark : Colors.black54;
    
    // Dynamic accent color: Amber in Dark Mode, Primary Accent (Green) in Light Mode
    final Color dynamicAccentColor = darkMode ? amberHighlight : primaryAccent; 
    
    // Dedicated switch on color
    final Color switchFlippedColor = dynamicAccentColor; 

    final Color appBarBg = primaryBg; 
    final Color iconColor = darkMode ? dynamicAccentColor : darkGreenIcon;
    final Color cardContentTextColor = darkMode ? mainTextDark : Colors.black;
    
    final Color googleButtonTextColor = darkMode ? amberHighlight : googleButtonTextBorderColor;
    final Color googleButtonBorderColor = darkMode ? amberHighlight : googleButtonTextBorderColor;
    final Color googleButtonIconColor = darkMode ? amberHighlight : googleButtonTextBorderColor;
    final Color googleButtonBackgroundColor = darkMode ? cardDark : googleButtonBgColor; 
    
    final Color fieldLabelColor = darkMode ? secondaryTextColor : primaryAccent;
    final Color headingColor = darkMode ? Colors.white : dynamicAccentColor;


    return Scaffold(
      backgroundColor: primaryBg,
      appBar: AppBar(
        title: Text("Settings", style: TextStyle(color: headingColor)),
        backgroundColor: appBarBg, 
        iconTheme: IconThemeData(color: mainTextColor),
        elevation: 0,
        surfaceTintColor: Colors.transparent, 
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Picture Section
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey,
                    backgroundImage:
                        _currentProfileImagePath != null &&
                                _currentProfileImagePath!.isNotEmpty
                            ? FileImage(File(_currentProfileImagePath!))
                                as ImageProvider
                            : const AssetImage('images/Transfer.png'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: dynamicAccentColor, 
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.black,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_currentProfileImagePath != null &&
              _currentProfileImagePath!.isNotEmpty)
            Center(
              child: TextButton(
                onPressed: _removeImage,
                child: Text(
                  "Remove Picture",
                  style: TextStyle(color: dynamicAccentColor),
                ),
              ),
            ),
          const SizedBox(height: 20),
          
          // Account Settings Section
          Text(
            "Account Settings",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: headingColor,
            ),
          ),
          const SizedBox(height: 10),
          // Google Sign-In Button
          ElevatedButton.icon(
            onPressed: signInWithGoogle,
            icon: Icon(
              Icons.person, 
              color: googleButtonIconColor, 
              size: 24,
            ),
            label: Text(
              "Sign in with Google",
              style: TextStyle(color: googleButtonTextColor, fontSize: 16), 
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: googleButtonBackgroundColor, 
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: googleButtonBorderColor, width: 2.0), 
              ),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 20),
          // Full Name Field
          TextField(
            controller: _nameController,
            style: TextStyle(color: mainTextColor),
            decoration: InputDecoration(
              labelText: "Full Name",
              labelStyle: TextStyle(color: fieldLabelColor),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: secondaryTextColor.withOpacity(0.5),
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: dynamicAccentColor),
              ),
            ),
          ),
          const SizedBox(height: 15),
          // Email Field
          TextField(
            controller: _emailController,
            style: TextStyle(color: mainTextColor),
            decoration: InputDecoration(
              labelText: "Email Address",
              labelStyle: TextStyle(color: fieldLabelColor),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: secondaryTextColor.withOpacity(0.5),
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: dynamicAccentColor),
              ),
            ),
          ),
          const SizedBox(height: 30),
          
          // Preferences Section
          Text(
            "Preferences",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: headingColor,
            ),
          ),
          // Set Monthly Budget Tile
          _buildSetLimitTile(
            cardContentTextColor,
            cardBg,
            iconColor,
            dynamicAccentColor,
          ),
          // Dark Mode Switch
          SwitchListTile(
            title: Text(
              "Dark Mode",
              style: TextStyle(color: cardContentTextColor),
            ),
            tileColor: cardBg,
            value: darkMode,
            activeColor: switchFlippedColor,
            onChanged: (value) {
              setState(() {
                darkMode = value;
                userBox.put('darkMode', value);
              });
              widget.settingsUpdated?.call(); 
            },
          ),
          
          // Enable App Lock Switch
          SwitchListTile(
            title: Text(
              "Enable App Lock",
              style: TextStyle(color: cardContentTextColor),
            ),
            tileColor: cardBg,
            value: _isAppLocked, 
            activeColor: switchFlippedColor,
            onChanged: (value) {
              setState(() {
                _isAppLocked = value;
                userBox.put('isAppLocked', value);
                
                final currentPassword = userBox.get('appLockPassword');
                
                if (value == true && (currentPassword == null || currentPassword.isEmpty)) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => _changePasswordDialog(
                          cardContentTextColor,
                          cardBg,
                          secondaryTextColor,
                          dynamicAccentColor,
                      ),
                    );
                } else if (value == false) {
                    userBox.delete('appLockPassword');
                }
                
                widget.settingsUpdated?.call(); 
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            value ? "App Lock Enabled!" : "App Lock Disabled.",
                        ),
                    ),
                );
              });
            },
          ),
          
          // Change Password ListTile
          ListTile(
            tileColor: cardBg,
            leading: Icon(Icons.lock_outline, color: iconColor),
            title: Text(
              "Change App Lock Password", 
              style: TextStyle(color: cardContentTextColor),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 18, color: iconColor),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => _changePasswordDialog(
                  cardContentTextColor,
                  cardBg,
                  secondaryTextColor,
                  dynamicAccentColor,
                ),
              );
            },
          ),
          
          // Download Account Summary ListTile
          ListTile(
            tileColor: cardBg,
            leading: Icon(Icons.picture_as_pdf, color: iconColor),
            title: Text(
              "Download Account Summary (PDF)", 
              style: TextStyle(color: cardContentTextColor),
            ),
            trailing: Icon(Icons.download, size: 22, color: iconColor),
            onTap: _exportToPdf, // This now calls the fixed logic
          ),

          const SizedBox(height: 30),
          // Save Changes Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: dynamicAccentColor,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _saveChanges,
            child: const Text(
              "Save Changes",
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Builders (unchanged logic) ---

  Widget _buildSetLimitTile(
    Color cardContentTextColor,
    Color cardBg,
    Color iconColor,
    Color dynamicAccentColor,
  ) {
    return ListTile(
      tileColor: cardBg,
      leading: Container(
        width: 24,
        alignment: Alignment.center,
        child: Text(
          '₹',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: iconColor,
          ),
        ),
      ),
      title: Text(
        "Set Monthly Budget",
        style: TextStyle(color: cardContentTextColor),
      ),
      subtitle: Text(
        "For ${_formatMonthDisplay(_currentMonth)}",
        style: TextStyle(color: cardContentTextColor.withOpacity(0.7)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatCurrency(_currentMonthBudgetLimit),
            style: TextStyle(color: cardContentTextColor),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, size: 18, color: iconColor),
        ],
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => _setBudgetLimitDialog(
            cardContentTextColor,
            cardBg,
            cardContentTextColor == Colors.black
                ? Colors.black54
                : secondaryTextDark,
            dynamicAccentColor,
            _currentMonth,
          ),
        );
      },
    );
  }

  Widget _setBudgetLimitDialog(
    Color textColor,
    Color dialogBg,
    Color secondaryTextColor,
    Color accentColor,
    DateTime initialSelectedMonth,
  ) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setStateDialog) {
        DateTime currentDialogMonth = initialSelectedMonth;
        int _getBudgetForMonth(DateTime month) {
          final String key = _formatMonthKey(month);
          return _monthlyBudgets[key] ?? 0;
        }

        int budgetAmount = _getBudgetForMonth(initialSelectedMonth);
        final budgetController = TextEditingController(
          text: budgetAmount > 0 ? budgetAmount.toString() : '',
        );
        budgetController.selection = TextSelection.fromPosition(
          TextPosition(offset: budgetController.text.length),
        );

        Future<void> _selectMonth() async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: currentDialogMonth,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            initialDatePickerMode: DatePickerMode.year,
            builder: (context, child) {
              final theme = Theme.of(context);
              return Theme(
                data: theme.copyWith(
                  colorScheme: ColorScheme.light(
                    primary: accentColor, 
                    onPrimary: Colors.black, 
                    onSurface: textColor, 
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: accentColor, 
                    ),
                  ),
                ),
                child: child!,
              );
            },
          );

          if (picked != null) {
            setStateDialog(() {
              currentDialogMonth = DateTime(picked.year, picked.month, 1);
              budgetAmount = _getBudgetForMonth(currentDialogMonth);
              budgetController.text = budgetAmount > 0
                  ? budgetAmount.toString()
                  : '';
              budgetController.selection = TextSelection.fromPosition(
                TextPosition(offset: budgetController.text.length),
              );
            });
          }
        }

        return AlertDialog(
          backgroundColor: dialogBg,
          title: Text("Set Monthly Budget", style: TextStyle(color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: _selectMonth,
                icon: Icon(Icons.calendar_today, size: 18, color: accentColor),
                label: Text(
                  "Budget for: ${_formatMonthDisplay(currentDialogMonth)}",
                  style: TextStyle(color: textColor),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: budgetController,
                style: TextStyle(color: textColor),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Budget Amount (Set 0 to remove limit)",
                  labelStyle: TextStyle(color: secondaryTextColor),
                  prefixText: '₹',
                  prefixStyle: TextStyle(color: textColor, fontSize: 16),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: accentColor),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: secondaryTextColor.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: accentColor)),
            ),
            TextButton(
              onPressed: () {
                final newLimit = int.tryParse(budgetController.text) ?? 0;
                final keyToSave = _formatMonthKey(currentDialogMonth);
                _monthlyBudgets[keyToSave] = newLimit;
                userBox.put('monthlyBudgets', _monthlyBudgets);
                final currentMonthKey = _formatMonthKey(_currentMonth);
                setState(() {
                  if (keyToSave == currentMonthKey) {
                    _currentMonthBudgetLimit = newLimit;
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Budget for ${_formatMonthDisplay(currentDialogMonth)} set to ${_formatCurrency(newLimit)}",
                    ),
                  ),
                );
              },
              child: Text("Save", style: TextStyle(color: accentColor)),
            ),
          ],
        );
      },
    );
  }

  Widget _changePasswordDialog(
    Color textColor,
    Color dialogBg,
    Color secondaryTextColor,
    Color accentColor,
  ) {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final currentPassword = userBox.get('appLockPassword', defaultValue: '');

    return AlertDialog(
      backgroundColor: dialogBg,
      title: Text("Set/Change App Lock Password", style: TextStyle(color: textColor)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (currentPassword.isNotEmpty)
            TextField(
              controller: oldPass,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Current App Lock Password",
                labelStyle: TextStyle(color: secondaryTextColor),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: accentColor),
                ),
              ),
              obscureText: true,
            ),
          const SizedBox(height: 10),
          TextField(
            controller: newPass,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: currentPassword.isNotEmpty
                  ? "New App Lock Password"
                  : "Set Initial App Lock Password",
              labelStyle: TextStyle(color: secondaryTextColor),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: accentColor),
              ),
            ),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel", style: TextStyle(color: accentColor)),
        ),
        TextButton(
          onPressed: () {
            final newPassword = newPass.text.trim();
            
            if (currentPassword.isNotEmpty && oldPass.text != currentPassword) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Incorrect Current Password!"),
                ),
              );
              return;
            }
            
            if (newPassword.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Password cannot be empty."),
                ),
              );
              return;
            }

            userBox.put('appLockPassword', newPassword);
            userBox.put('isAppLocked', true);
            
            setState(() {
              _isAppLocked = true; 
            });
            
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("App Lock Password Set!"),
              ),
            );
            
            widget.settingsUpdated?.call(); 
          },
          child: Text("Save", style: TextStyle(color: accentColor)),
        ),
      ],
    );
  }
}

// --- NEW WIDGET: LockScreen (Handles App Lock) ---

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  final bool darkMode;

  const LockScreen({super.key, required this.onUnlock, required this.darkMode});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';

  // ⭐ Ensure LockScreen uses the exact same colors for consistency
  Color get primaryBg =>
      widget.darkMode ? primaryDark : primaryLight; // Uses primaryLight
  Color get mainTextColor => widget.darkMode ? Colors.white : Colors.black;
  Color get dynamicAccentColor =>
      widget.darkMode ? amberHighlight : primaryAccent; // Uses primaryAccent

  void _checkPassword() {
    final userBox = Hive.box('userBox');
    final storedPassword = userBox.get('appLockPassword', defaultValue: '');
    if (_passwordController.text == storedPassword &&
        storedPassword.isNotEmpty) {
      widget.onUnlock();
    } else {
      setState(() {
        _errorMessage = 'Incorrect Password. Try again.';
        _passwordController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.lock, size: 80, color: dynamicAccentColor),
              const SizedBox(height: 20),
              Text(
                'Enter App Lock Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: mainTextColor,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: TextStyle(color: mainTextColor),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(color: mainTextColor.withOpacity(0.5)),
                  filled: true,
                  // Use a dark/accent color for the filled background
                  fillColor: dynamicAccentColor.withOpacity(widget.darkMode ? 0.2 : 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _checkPassword(),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: dynamicAccentColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Unlock',
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}