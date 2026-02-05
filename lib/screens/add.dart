// add.dart
// ignore_for_file: camel_case_types, sized_box_for_whitespace, non_constant_identifier_names, avoid_unnecessary_containers, annotate_overrides, unused_field, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_application/data/model/add_date.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Add_Screen extends StatefulWidget {
  const Add_Screen({super.key});

  @override
  State<Add_Screen> createState() => _Add_ScreenState();
}

class _Add_ScreenState extends State<Add_Screen> {
  final Box userBox = Hive.box('userBox');

  // --- THEME COLORS (Consistent with other files) ---
  // Dark Theme Colors
  static const Color primaryDark = Color(0xFF0D1829); // Main Background
  static const Color cardDark = Color(0xFF1B2C42); // Card Background
  static const Color amberHighlight = Color(0xFFE5B80B); // Dark Accent/Active
  static const Color secondaryTextDark = Colors.white70;
  static const Color mainTextDark = Colors.white;

  // Light Theme Colors
  // Original primaryLight was Color.fromARGB(255, 240, 218, 187) - The light tan background
  static const Color lightTanBg = Color.fromARGB(255, 240, 218, 187);
  // Requested Deep Green Accent Color: RGB 255, 105, 128, 60
  static const Color deepGreenAccent = Color.fromARGB(255, 105, 128, 60);

  static const Color cardLight = Colors.white; // White for Card background, input fields
  // Set brightAccentLight to the requested deep green
  static const Color brightAccentLight = deepGreenAccent;
  static const Color mainTextLight = Colors.black; // Main text color
  static const Color secondaryTextLight = Colors.black54; // Secondary text color

  static const double cardRadius = 14.0;
  static const double padding = 18.0;
  static const double horizontalPaddingFactor = 0.8;
  // ----------------------

  final box = Hive.box<Add_data>('data');

  DateTime date = DateTime.now();
  String? selectedItem;
  String? selctedItemi;
  final TextEditingController expalin_C = TextEditingController();
  FocusNode ex = FocusNode();
  final TextEditingController amount_c = TextEditingController();
  FocusNode amount_ = FocusNode();
  final List<String> _items = [
    "Food",
    "Education",
    "Transportation",
    "Transfer",
    "Work",
  ];
  final List<String> _itemei = ['Income', "Expend"];

  @override
  void initState() {
    super.initState();
    ex.addListener(() {
      setState(() {});
    });
    amount_.addListener(() {
      setState(() {});
    });
  }

  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: userBox.listenable(keys: ['darkMode']),
      builder: (context, box, child) {
        final bool darkMode = userBox.get('darkMode', defaultValue: false);

        // Dynamic Colors based on the desired look from Image 2 for Light Mode
        final Color scaffoldBg = darkMode ? primaryDark : lightTanBg; // Light tan background
        final Color mainCardBg = darkMode ? cardDark : cardLight; // White for the main card

        // Header specific colors (Set to lightTanBg for background, mainTextLight for title)
        final Color headerBg = darkMode ? cardDark : lightTanBg; // Light tan header background
        // Change: Header title color is now Black in Light Mode
        final Color headerTitleColor = darkMode ? mainTextDark : mainTextLight; // Black title text
        final Color headerIconColor = darkMode ? amberHighlight : brightAccentLight; // Bright accent for icons (Green)

        // Input field specific colors
        final Color inputFillColor = darkMode ? cardDark : cardLight; // White for text fields
        // Change: Border color is now Deep Green
        final Color inputBorderColor = darkMode ? secondaryTextDark.withOpacity(0.5) : brightAccentLight; // Deep Green border
        // Change: Focus border color is now Deep Green
        final Color inputFocusBorderColor = darkMode ? amberHighlight : brightAccentLight; // Deep Green focus border
        // Change: Label focus color is now Deep Green
        final Color labelFocusColor = darkMode ? amberHighlight : brightAccentLight; // Deep Green label when focused
        // Change: Text color is Black
        final Color inputTextColor = darkMode ? mainTextDark : mainTextLight; // Black text for input
        final Color inputHintColor = darkMode ? secondaryTextDark : secondaryTextLight; // Black54 hint for input

        // Save Button specific colors
        // Change: Start color is Deep Green
        final Color saveButtonGradientStart = darkMode ? amberHighlight : brightAccentLight; // Deep Green for save button start
        // Change: End color is also Deep Green for solid color
        final Color saveButtonGradientEnd = darkMode ? const Color(0xFFFFC000) : brightAccentLight; // Deep Green for solid color
        final Color saveButtonTextColor = darkMode ? primaryDark : cardLight; // White text on save button
        final Color saveButtonShadowColor = darkMode ? amberHighlight.withOpacity(0.3) : brightAccentLight.withOpacity(0.5); // Deep green shadow

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SafeArea(
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                background_container(
                  context,
                  headerBg, // Pass single color now (light tan)
                  headerTitleColor, // Pass black color for title
                  headerIconColor,
                ),
                Positioned(
                  top: 120,
                  child: main_container(
                    mainCardBg,
                    inputTextColor,
                    inputHintColor,
                    inputFillColor,
                    inputBorderColor,
                    inputFocusBorderColor,
                    labelFocusColor,
                    saveButtonGradientStart,
                    saveButtonGradientEnd,
                    saveButtonTextColor,
                    saveButtonShadowColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // UPDATED: Parameters for main_container
  Container main_container(
    Color mainCardBg,
    Color inputTextColor,
    Color inputHintColor,
    Color inputFillColor,
    Color inputBorderColor,
    Color inputFocusBorderColor,
    Color labelFocusColor,
    Color saveButtonGradientStart,
    Color saveButtonGradientEnd,
    Color saveButtonTextColor,
    Color saveButtonShadowColor,
  ) {
    final bool darkMode = userBox.get('darkMode', defaultValue: false);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        color: mainCardBg, // White for the main card in Light Mode
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(darkMode ? 0.5 : 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      height: 550,
      width: 340,
      child: Column(
        children: [
          const SizedBox(height: 50),
          name(
            inputTextColor,
            inputHintColor,
            inputBorderColor,
            inputFillColor,
            labelFocusColor, // Accent color for dropdown icon
          ),
          const SizedBox(height: 30),
          Explain(
            inputTextColor,
            inputHintColor,
            inputFillColor,
            inputBorderColor,
            inputFocusBorderColor,
            labelFocusColor,
          ),
          const SizedBox(height: 30),
          Amount(
            inputTextColor,
            inputHintColor,
            inputFillColor,
            inputBorderColor,
            inputFocusBorderColor,
            labelFocusColor,
          ),
          const SizedBox(height: 30),
          How(
            inputTextColor,
            inputHintColor,
            inputBorderColor,
            inputFillColor,
            labelFocusColor, // Accent color for dropdown icon
          ),
          const SizedBox(height: 30),
          Date_Time(
            inputTextColor,
            inputHintColor,
            inputBorderColor,
            inputFillColor,
            labelFocusColor, // Accent color for date picker
          ),
          const Spacer(),
          Save(
            saveButtonGradientStart,
            saveButtonGradientEnd,
            saveButtonTextColor,
            saveButtonShadowColor,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // UPDATED: Parameters for Save button (Solid Green)
  GestureDetector Save(
    Color startColor,
    Color endColor,
    Color textColor,
    Color shadowColor,
  ) {
    return GestureDetector(
      onTap: () async {
        if (selectedItem == null || selctedItemi == null || amount_c.text.isEmpty || expalin_C.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please fill all fields."),
            ),
          );
          return;
        }

        if (int.tryParse(amount_c.text) == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please enter a valid numeric amount"),
            ),
          );
          return;
        }
        var add = Add_data(
          selctedItemi!,
          amount_c.text,
          date,
          expalin_C.text,
          selectedItem!,
        );
        final box = await Hive.openBox<Add_data>('data');
        box.add(add);

        Navigator.of(context).pop();
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardRadius * 0.7),
          // Gradient uses the same start and end color for a solid green button
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        width: 120,
        height: 50,
        child: Text(
          'Save',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor, // White text
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  // UPDATED: Parameters for Date_Time (Borders and Text are correct)
  Widget Date_Time(
    Color inputTextColor,
    Color inputHintColor,
    Color inputBorderColor,
    Color inputFillColor,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: padding * horizontalPaddingFactor),
      child: Container(
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardRadius * 0.7),
          border: Border.all(
            width: 2,
            color: inputBorderColor, // Deep Green border
          ),
          color: inputFillColor, // White in Light Mode
        ),
        child: TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () async {
            DateTime? newDate = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2200),
              builder: (context, child) {
                final bool darkMode = userBox.get('darkMode', defaultValue: false);
                return Theme(
                  data: darkMode
                      ? ThemeData.dark().copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: accentColor, // Header background (Amber)
                            onPrimary: primaryDark, // Header text (Dark Blue)
                            surface: cardDark, // Dialog background
                            onSurface: mainTextDark, // Text color
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: accentColor, // Button text color
                            ),
                          ),
                        )
                      : ThemeData.light().copyWith(
                          colorScheme: ColorScheme.light(
                            primary: deepGreenAccent, // Header background (Deep Green)
                            onPrimary: cardLight, // Header text (White)
                            surface: cardLight, // Dialog background (White)
                            onSurface: mainTextLight, // Text color (Black)
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: deepGreenAccent, // Button text color (Deep Green)
                            ),
                          ),
                          dialogBackgroundColor: cardLight,
                        ),
                  child: child!,
                );
              },
            );
            if (newDate != null) {
              setState(() {
                date = newDate;
              });
            }
          },
          child: Text(
            'Date: ${date.day}/${date.month}/${date.year}',
            style: TextStyle(
              fontSize: 17,
              color: inputTextColor, // Black in Light Mode
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // UPDATED: Parameters for How dropdown (Border, Text, and Icon are correct)
  Padding How(
    Color inputTextColor,
    Color inputHintColor,
    Color inputBorderColor,
    Color inputFillColor,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: padding * horizontalPaddingFactor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardRadius * 0.7),
          border: Border.all(width: 2, color: inputBorderColor), // Deep Green border
          color: inputFillColor, // White in Light Mode
        ),
        child: DropdownButton<String>(
          value: selctedItemi,
          onChanged: (value) {
            setState(() {
              selctedItemi = value!;
            });
          },
          items: _itemei
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: TextStyle(fontSize: 17, color: inputTextColor), // Black in Light Mode
                  ),
                ),
              )
              .toList(),
          hint: Text(
            'How (Income/Expense)',
            style: TextStyle(color: inputHintColor, fontSize: 17), // Black54 in Light Mode
          ),
          dropdownColor: inputFillColor, // White dropdown menu background
          isExpanded: true,
          underline: Container(),
          icon: Icon(Icons.arrow_downward, color: accentColor), // Deep Green in Light Mode
        ),
      ),
    );
  }

  // UPDATED: Parameters for Amount text field (Borders and Text are correct)
  Padding Amount(
    Color inputTextColor,
    Color inputHintColor,
    Color inputFillColor,
    Color inputBorderColor,
    Color inputFocusBorderColor,
    Color labelFocusColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: padding * horizontalPaddingFactor),
      child: TextField(
        keyboardType: TextInputType.number,
        focusNode: amount_,
        controller: amount_c,
        style: TextStyle(color: inputTextColor), // Black in Light Mode
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          labelText: 'Amount',
          labelStyle: TextStyle(
              fontSize: 17,
              color: amount_.hasFocus ? labelFocusColor : inputHintColor), // Deep Green when focused, black54 otherwise
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(cardRadius * 0.7),
            borderSide: BorderSide(width: 2, color: inputBorderColor), // Deep Green border
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(cardRadius * 0.7),
            borderSide: BorderSide(width: 2, color: inputFocusBorderColor), // Deep Green focus border
          ),
          fillColor: inputFillColor, // White field background
          filled: true,
        ),
      ),
    );
  }

  // UPDATED: Parameters for Explain text field (Borders and Text are correct)
  Padding Explain(
    Color inputTextColor,
    Color inputHintColor,
    Color inputFillColor,
    Color inputBorderColor,
    Color inputFocusBorderColor,
    Color labelFocusColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: padding * horizontalPaddingFactor),
      child: TextField(
        focusNode: ex,
        controller: expalin_C,
        style: TextStyle(color: inputTextColor), // Black in Light Mode
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          labelText: 'Explain',
          labelStyle: TextStyle(
              fontSize: 17,
              color: ex.hasFocus ? labelFocusColor : inputHintColor), // Deep Green when focused, black54 otherwise
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(cardRadius * 0.7),
            borderSide: BorderSide(width: 2, color: inputBorderColor), // Deep Green border
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(cardRadius * 0.7),
            borderSide: BorderSide(width: 2, color: inputFocusBorderColor), // Deep Green focus border
          ),
          fillColor: inputFillColor, // White field background
          filled: true,
        ),
      ),
    );
  }

  // UPDATED: Parameters for name dropdown (Border, Text, and Icon are correct)
  Padding name(
    Color inputTextColor,
    Color inputHintColor,
    Color inputBorderColor,
    Color inputFillColor,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: padding * horizontalPaddingFactor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardRadius * 0.7),
          border: Border.all(width: 2, color: inputBorderColor), // Deep Green border
          color: inputFillColor, // White in Light Mode
        ),
        child: DropdownButton<String>(
          value: selectedItem,
          items: _items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Row(
                    children: [
                      Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: inputFillColor, // White for icon background
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(5),
                          child: Image.asset('images/$e.png')),
                      const SizedBox(width: 10),
                      Text(e, style: TextStyle(fontSize: 17, color: inputTextColor)), // Black in Light Mode
                    ],
                  ),
                ),
              )
              .toList(),
          selectedItemBuilder: (BuildContext context) => _items
              .map(
                (e) => Row(
                  children: [
                    Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: inputFillColor, // White for icon background
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(5),
                        child: Image.asset('images/$e.png')),
                    const SizedBox(width: 5),
                    Text(e, style: TextStyle(color: inputTextColor, fontWeight: FontWeight.w500, fontSize: 17)), // Black in Light Mode
                  ],
                ),
              )
              .toList(),
          hint: Text('Name (Category)', style: TextStyle(color: inputHintColor, fontSize: 17)), // Black54 in Light Mode
          dropdownColor: inputFillColor, // White dropdown menu background
          isExpanded: true,
          underline: Container(),
          icon: Icon(Icons.arrow_downward, color: accentColor), // Deep Green in Light Mode
          onChanged: (value) {
            setState(() {
              selectedItem = value!;
            });
          },
        ),
      ),
    );
  }

  // UPDATED: Header background changed to light tan, title changed to black
  Column background_container(
    BuildContext context,
    Color headerBg, // Single color for header background (light tan)
    Color headerTitleColor, // Black for title
    Color headerIconColor,
  ) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            color: headerBg, // Solid light tan for header
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(cardRadius),
              bottomRight: Radius.circular(cardRadius),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Icon(Icons.arrow_back, color: headerIconColor), // Deep Green for icons
                    ),
                    Text(
                      'Adding Transaction',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: headerTitleColor, // Black for title
                      ),
                    ),
                    Icon(Icons.attach_file_outlined, color: headerIconColor), // Deep Green for icons
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}