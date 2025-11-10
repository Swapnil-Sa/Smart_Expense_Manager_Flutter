// lib/screens/chatbot_screen.dart

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_application/data/model/add_date.dart'; // Adjust path as needed
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [
    {'role': 'ai', 'text': 'Hello! I\'m your financial assistant. Tap "Get Report" to analyze your spending or ask me a question!'}
  ];
  
  bool _isLoading = false;
  String? _apiError; // To store API key error status

  late final GenerativeModel _model;
  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();
    // 1. Get API Key securely from .env
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      _apiError = 'ERROR: GEMINI_API_KEY is not set. Chat functionality disabled.';
      _messages.add({'role': 'ai', 'text': _apiError!});
      // Do NOT proceed with model initialization if key is missing
      return; 
    }

    // 2. Initialize the Gemini Model and Chat Session
    try {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash', 
        apiKey: apiKey,
      );
      _chat = _model.startChat();
    } catch (e) {
      _apiError = 'ERROR: Model initialization failed. $e';
      _messages.add({'role': 'ai', 'text': _apiError!});
    }
  }

  // Helper function to format transaction data for the AI
  String _formatExpenseDataForAI() {
    // Check if Hive boxes are open before accessing
    if (!Hive.isBoxOpen('data') || !Hive.isBoxOpen('userBox')) {
       return "ERROR: Hive data boxes are not open. Cannot retrieve expense data.";
    }

    final box = Hive.box<Add_data>('data');
    final transactions = box.values.toList();
    
    // Group and format by category
    final Map<String, double> categoryExpenses = {};
    final DateTime now = DateTime.now();
    double totalMonthlyExpense = 0;
    
    for (var tx in transactions) {
      // NOTE: Assuming 'Expand' is the correct identifier for expenses
      if (tx.IN == 'Expand' && tx.datetime.month == now.month) {
        // Ensure robust parsing and remove potential thousands separators
        final amount = double.tryParse(tx.amount.replaceAll(RegExp(r'[, ]'), '')) ?? 0.0;
        categoryExpenses.update(tx.name, (value) => value + amount, ifAbsent: () => amount);
        totalMonthlyExpense += amount;
      }
    }

    if (totalMonthlyExpense == 0) return "No expenses recorded for the current month (${DateFormat('MMMM').format(now)}).";

    String data = "Monthly Expense Report for ${DateFormat('MMMM yyyy').format(now)}:\n";
    data += "Total Expense: ₹${NumberFormat('#,##0').format(totalMonthlyExpense)}\n";
    data += "Expenses by Category:\n";

    categoryExpenses.forEach((category, amount) {
      final percentage = (amount / totalMonthlyExpense) * 100;
      data += "- $category: ₹${NumberFormat('#,##0').format(amount)} (${percentage.toStringAsFixed(1)}%)\n";
    });

    final monthlyLimit = Hive.box('userBox').get('monthlyLimit', defaultValue: 0.0) as double; // Ensure double for comparison
    if (monthlyLimit > 0) {
      final remaining = monthlyLimit - totalMonthlyExpense;
      data += "\nYour monthly budget is ₹${NumberFormat('#,##0').format(monthlyLimit)}.\n";
      data += remaining >= 0 
          ? "You have ₹${NumberFormat('#,##0').format(remaining.abs())} remaining." 
          : "You are over budget by ₹${NumberFormat('#,##0').format(remaining.abs())}.";
    }

    return data;
  }
  
  void _scrollToBottom() {
     WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || _isLoading || _apiError != null) return;
    
    setState(() {
      _messages.insert(0, {'role': 'user', 'text': message});
      _controller.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(message));
      setState(() {
        _messages.insert(0, {'role': 'ai', 'text': response.text ?? 'Sorry, I couldn\'t process that request.'});
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.insert(0, {'role': 'ai', 'text': 'Error: Failed to connect to AI. Check your API key and connection. ($e)'});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  // Pre-defined function to get AI report
  Future<void> _getFinancialReport() async {
    if (_isLoading || _apiError != null) return;
    
    final expenseData = _formatExpenseDataForAI();
    final systemPrompt = "You are a friendly and professional financial assistant. Analyze the user's current month expense data provided below. Give a summary of the spending, intelligently suggest 2-3 specific areas where they can reduce expenses, and provide 2-3 actionable tips on how to avoid spending money. Keep your advice concise and encouraging. The data is in INR (₹).\n\nDATA:\n$expenseData";
    
    setState(() {
      _messages.insert(0, {'role': 'user', 'text': 'Generate my monthly financial report and advice.'});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // Use generateContent for a fresh, powerful system-prompt-based response
      final response = await _model.generateContent([Content.text(systemPrompt)]);
      setState(() {
        _messages.insert(0, {'role': 'ai', 'text': response.text ?? 'Failed to generate report.'});
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.insert(0, {'role': 'ai', 'text': 'Error generating report: $e'});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Financial Assistant 🤖'),
        backgroundColor: const Color(0xff368983),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.analytics_outlined, color: Colors.white),
            label: const Text('Get Report', style: TextStyle(color: Colors.white)),
            onPressed: _isLoading || _apiError != null ? null : _getFinancialReport,
          ),
        ],
      ),
      body: Column(
        children: [
          // Display API Error if present
          if (_apiError != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_apiError!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                // Read from the last message to the first
                final message = _messages[index]; 
                return MessageBubble(message: message);
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          InputArea(
            controller: _controller,
            onSend: _sendMessage,
            isLoading: _isLoading || _apiError != null,
          ),
        ],
      ),
    );
  }
}

// --- Separated MessageBubble Widget ---
class MessageBubble extends StatelessWidget {
  final Map<String, String> message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isAI = message['role'] == 'ai';
    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
        padding: const EdgeInsets.all(12.0),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isAI ? Colors.grey.shade200 : const Color(0xff368983).withOpacity(0.8),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            // Adjusted logic for consistent bubble tails
            bottomLeft: isAI ? Radius.zero : const Radius.circular(15),
            bottomRight: isAI ? const Radius.circular(15) : Radius.zero,
          ),
        ),
        child: Text(
          message['text']!,
          style: TextStyle(
            color: isAI ? Colors.black87 : Colors.white,
          ),
        ),
      ),
    );
  }
}

// --- Separated InputArea Widget ---
class InputArea extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final bool isLoading;

  const InputArea({
    super.key,
    required this.controller,
    required this.onSend,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isLoading, // Disable input when loading
              decoration: InputDecoration(
                hintText: 'Ask your financial question...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              ),
              onSubmitted: isLoading ? null : onSend,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xff368983),
            child: IconButton(
              icon: isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: isLoading || controller.text.trim().isEmpty ? null : () => onSend(controller.text),
            ),
          ),
        ],
      ),
    );
  }
}