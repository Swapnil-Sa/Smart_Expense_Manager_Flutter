// chatbot_screen.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_application/data/model/add_date.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'role': 'ai', 'text': 'Hello! I\'m your financial assistant. Tap "Get Report" to analyze your spending or ask me a question!'}
  ];
  bool _isLoading = false;

  late final GenerativeModel _model;
  late final ChatSession _chat;
  
  // Theme variables
  bool _isDarkMode = false;
  late Color _primaryBg;
  late Color _primaryAccent;
  late Color _appBarBg;
  late Color _mainTextColor;

  // --- Theme Colors ---
  static const Color primaryDark = Color(0xFF0F111A);
  static const Color primaryLight = Color(0xFF1E5033);
  static const Color amberHighlight = Colors.amber;
  // static const Color brightAccentLight = Color(0xffB8FF80); // Retained for reference
  
  void _resolveThemeColors() {
    final userBox = Hive.box('userBox');
    _isDarkMode = userBox.get('darkMode', defaultValue: false);

    if (_isDarkMode) {
      _primaryBg = primaryDark;
      _primaryAccent = amberHighlight;
      _appBarBg = primaryDark;
      _mainTextColor = Colors.white;
    } else {
      _primaryBg = Colors.white;
      _primaryAccent = const Color(0xff368983);
      _appBarBg = primaryLight;
      _mainTextColor = Colors.white;
    }
  }

  @override
  void initState() {
    super.initState();
    _resolveThemeColors();

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      _messages.add({'role': 'ai', 'text': 'ERROR: GEMINI_API_KEY is not set in the .env file. Chat functionality disabled.'});
      return;
    }
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
    _chat = _model.startChat();
  }

  // 🎯 NEW FUNCTIONALITY: Format all transaction data for AI analysis
  String _formatTransactionDataForAI() {
    final box = Hive.box<Add_data>('data');
    
    // Sort transactions by date (newest first for readability)
    final sortedTransactions = box.values.toList()
      ..sort((a, b) => b.datetime.compareTo(a.datetime));
    
    if (sortedTransactions.isEmpty) {
      return "No transactions have been recorded yet.";
    }

    final formatCurrency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final formatDate = DateFormat('dd/MM/yy');

    // Section 1: Detailed Chronological List
    StringBuffer detailedList = StringBuffer("User's Recent Financial Transactions (Newest to Oldest):\n");
    for (var tx in sortedTransactions) {
      final sign = tx.IN == 'Income' ? '+' : '-';
      final formattedAmount = formatCurrency.format(double.tryParse(tx.amount.replaceAll(',', '')) ?? 0.0);
      final explanation = tx.explain.isNotEmpty ? " | Note: ${tx.explain}" : "";
      
      detailedList.writeln(
        "- [${formatDate.format(tx.datetime)}] Type: ${tx.IN} | Category: ${tx.name} | Amount: $sign$formattedAmount$explanation"
      );
    }

    // Section 2: Monthly Summary (Existing Logic - Improved Formatting)
    final DateTime now = DateTime.now();
    double totalMonthlyIncome = 0;
    double totalMonthlyExpense = 0;
    
    for (var tx in sortedTransactions.where((t) => t.datetime.month == now.month)) {
      final amount = double.tryParse(tx.amount.replaceAll(',', '')) ?? 0.0;
      if (tx.IN == 'Income') {
        totalMonthlyIncome += amount;
      } else if (tx.IN == 'Expand' || tx.IN == 'Expense') { // Handles both possible expense keys
        totalMonthlyExpense += amount;
      }
    }
    
    detailedList.writeln("\nMonthly Financial Summary (${DateFormat('MMMM yyyy').format(now)}):");
    detailedList.writeln("Total Income: ${formatCurrency.format(totalMonthlyIncome)}");
    detailedList.writeln("Total Expenses: ${formatCurrency.format(totalMonthlyExpense)}");
    detailedList.writeln("Net Flow: ${formatCurrency.format(totalMonthlyIncome - totalMonthlyExpense)}");

    final monthlyLimit = Hive.box('userBox').get('monthlyLimit', defaultValue: 0);
    if (monthlyLimit > 0) {
      final remaining = monthlyLimit - totalMonthlyExpense;
      detailedList.writeln("\nMonthly Budget: ${formatCurrency.format(monthlyLimit)}");
      detailedList.writeln(remaining >= 0 
          ? "Budget Status: ${formatCurrency.format(remaining.abs())} remaining." 
          : "Budget Status: Over budget by ${formatCurrency.format(remaining.abs())}."
      );
    }

    return detailedList.toString();
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || _isLoading) return;
    
    setState(() {
      _messages.add({'role': 'user', 'text': message});
      _controller.clear();
      _isLoading = true;
    });

    try {
      // 🎯 Provide all transaction data to the AI for conversational context
      final transactionData = _formatTransactionDataForAI();
      final systemInstruction = "You are a helpful and detailed financial assistant. The user is asking a question about their finances. Here is their transaction data: \n\nDATA:\n$transactionData\n\nUser's Question: $message";
      
      final response = await _chat.sendMessage(Content.text(systemInstruction));
      setState(() {
        _messages.add({'role': 'ai', 'text': response.text ?? 'Sorry, I couldn\'t process that request.'});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'text': 'Error: Failed to connect to AI. Check your API key and connection. ($e)'});
        _isLoading = false;
      });
    }
  }

  Future<void> _getFinancialReport() async {
    final transactionData = _formatTransactionDataForAI();
    // System instruction for the AI model remains focused on generating a report
    final systemPrompt = "You are a friendly and professional financial assistant. Analyze the user's current month transaction data (Income, Expenses, and notes) provided below. Give a summary of the spending and income, highlight any unusual or high-amount transactions based on the notes/explanations, intelligently suggest 2-3 specific areas where they can improve their finances, and provide 2-3 actionable tips. Keep your advice concise and encouraging. The data is in INR (₹).\n\nDATA:\n$transactionData";
    
    setState(() {
      _messages.add({'role': 'user', 'text': 'Generate my monthly financial report and advice.'});
      _isLoading = true;
    });

    try {
      final response = await _model.generateContent([Content.text(systemPrompt)]);
      setState(() {
        _messages.add({'role': 'ai', 'text': response.text ?? 'Failed to generate report.'});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'text': 'Error generating report: $e'});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryBg,
      appBar: AppBar(
        title: Text('AI Financial Assistant 🤖', style: TextStyle(color: _mainTextColor)),
        backgroundColor: _appBarBg,
        iconTheme: IconThemeData(color: _mainTextColor),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.analytics_outlined, color: _mainTextColor),
            label: Text('Get Report', style: TextStyle(color: _mainTextColor)),
            onPressed: _isLoading ? null : _getFinancialReport,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return _MessageBubble(message: message, isDarkMode: _isDarkMode, accentColor: _primaryAccent);
              },
            ),
          ),
          if (_isLoading) LinearProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryAccent)),
          _InputArea(
            controller: _controller,
            onSend: _sendMessage,
            isLoading: _isLoading,
            accentColor: _primaryAccent,
            mainTextColor: _isDarkMode ? Colors.white : Colors.black,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, String> message;
  final bool isDarkMode;
  final Color accentColor;
  
  const _MessageBubble({required this.message, required this.isDarkMode, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final isAI = message['role'] == 'ai';
    
    final Color aiBubbleColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final Color userBubbleColor = accentColor.withOpacity(0.9);
    
    final Color aiTextColor = isDarkMode ? Colors.white : Colors.black87;
    final Color userTextColor = Colors.white;

    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
        padding: const EdgeInsets.all(12.0),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isAI ? aiBubbleColor : userBubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isAI ? Radius.zero : const Radius.circular(15),
            bottomRight: isAI ? const Radius.circular(15) : Radius.zero,
          ),
        ),
        child: Text(
          message['text']!,
          style: TextStyle(
            color: isAI ? aiTextColor : userTextColor,
          ),
        ),
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final bool isLoading;
  final Color accentColor;
  final Color mainTextColor;

  const _InputArea({
    required this.controller,
    required this.onSend,
    required this.isLoading,
    required this.accentColor,
    required this.mainTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final inputFillColor = mainTextColor == Colors.white ? Colors.grey.shade800 : Colors.grey.shade100;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(color: mainTextColor),
              decoration: InputDecoration(
                hintText: 'Ask your financial question...',
                hintStyle: TextStyle(color: mainTextColor.withOpacity(0.5)),
                filled: true,
                fillColor: inputFillColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              ),
              onSubmitted: isLoading ? null : onSend,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: accentColor,
            child: IconButton(
              icon: isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.black)))
                  : const Icon(Icons.send, color: Colors.black),
              onPressed: isLoading ? null : () => onSend(controller.text),
            ),
          ),
        ],
      ),
    );
  }
}