// utility.dart

// ignore_for_file: non_constant_identifier_names, avoid_print, unnecessary_new

import 'package:hive/hive.dart';
import 'package:flutter_application/data/model/add_date.dart';

int totals = 0;

final box = Hive.box<Add_data>('data');

int total() {
  var history2 = box.values.toList();
  List<int> a = [0];
  for (var i = 0; i < history2.length; i++) {
    int amount = int.tryParse(history2[i].amount) ?? 0;
    a.add(history2[i].IN == 'Income' ? amount : -amount);
  }
  totals = a.reduce((value, element) => value + element);
  return totals;
}

int income() {
  var history2 = box.values.toList();
  List<int> a = [0];
  for (var i = 0; i < history2.length; i++) {
    int amount = int.tryParse(history2[i].amount) ?? 0;
    a.add(history2[i].IN == 'Income' ? amount : 0);
  }
  totals = a.reduce((value, element) => value + element);
  return totals;
}

int expenses() {
  var history2 = box.values.toList();
  List<int> a = [0];
  for (var i = 0; i < history2.length; i++) {
    int amount = int.tryParse(history2[i].amount) ?? 0;
    // Expenses are added as negative numbers here: -amount
    a.add(history2[i].IN == 'Income' ? 0 : -amount);
  }
  totals = a.reduce((value, element) => value + element);
  
  // 🔑 FIX: Return the absolute (positive) value of the total expenses.
  // This is crucial for correct budget limit calculations (limit - expenses) 
  // and for displaying the "Spent" amount as a positive number in the UI.
  return totals.abs(); 
}


List<Add_data> today() {
  List<Add_data> a = [];
  var history2 = box.values.toList();
  DateTime date = new DateTime.now();
  for (var i = 0; i < history2.length; i++) {
    if (history2[i].datetime.day == date.day) {
      a.add(history2[i]);
    }
  }
  return a;
}

List<Add_data> week() {
  List<Add_data> a = [];
  DateTime date = new DateTime.now();
  var history2 = box.values.toList();
  
  // Note: This weekly calculation can be problematic as it only checks the 'day' 
  // number and doesn't account for the month boundary or a rolling 7-day period.
  // However, I am keeping your original logic unchanged here.
  for (var i = 0; i < history2.length; i++) {
    if (date.day - 7 <= history2[i].datetime.day &&
        history2[i].datetime.day <= date.day) {
      a.add(history2[i]);
    }
  }
  return a;
}

List<Add_data> month() {
  List<Add_data> a = [];
  var history2 = box.values.toList();
  DateTime date = new DateTime.now();
  for (var i = 0; i < history2.length; i++) {
    if (history2[i].datetime.month == date.month) {
      a.add(history2[i]);
    }
  }
  return a;
}

List<Add_data> year() {
  List<Add_data> a = [];
  var history2 = box.values.toList();
  DateTime date = new DateTime.now();
  for (var i = 0; i < history2.length; i++) {
    if (history2[i].datetime.year == date.year) {
      a.add(history2[i]);
    }
  }
  return a;
}

int total_chart(List<Add_data> history2) {
  List a = [0, 0];

  for (var i = 0; i < history2.length; i++) {
    a.add(history2[i].IN == 'Income'
        ? int.parse(history2[i].amount)
        : int.parse(history2[i].amount) * -1);
  }
  totals = a.reduce((value, element) => value + element);
  return totals;
}

List time(List<Add_data> history2, bool hour) {
  List<Add_data> a = [];
  List total = [];
  int counter = 0;
  for (var c = 0; c < history2.length; c++) {
    for (var i = c; i < history2.length; i++) {
      if (hour) {
        if (history2[i].datetime.hour == history2[c].datetime.hour) {
          a.add(history2[i]);
          counter = i;
        }
      } else {
        if (history2[i].datetime.day == history2[c].datetime.day) {
          a.add(history2[i]);
          counter = i;
        }
      }
    }
    total.add(total_chart(a));
    a.clear();
    c = counter;
  }
  print(total);
  return total;
}