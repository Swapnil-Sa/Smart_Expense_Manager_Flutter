// ignore_for_file: unnecessary_string_escapes, non_constant_identifier_names

import 'package:flutter_application/data/1.dart';

List<Money> geter_Top() {
  Money snapFood = Money();
  snapFood.time = 'Jan 30, 2022';
  snapFood.image = 'Food.png';
  snapFood.buy = true;
  snapFood.fee = '- \₹100';
  snapFood.name = 'Food';

  Money snap = Money();
  snap.image = 'Transfer.png';
  snap.time = 'Today';
  snap.buy = true;
  snap.name = 'Transfer';
  snap.fee = '- \₹ 60';

  return [snapFood, snap];
}
