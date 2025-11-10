import 'package:flutter_application/data/1.dart';

List<Money>  geter(){
  Money upwork = Money();
  upwork.name = 'upwork';
  upwork.fee = '650';
  upwork.time = 'today';
  upwork.image = 'Work.png';
  upwork.buy = false;
  Money starbucks = Money();
  starbucks.buy = true;
  starbucks.fee = '150';
  starbucks.image = 'star.jpg'; // must match actual file name
  starbucks.name = 'starbucks';
  starbucks.time = 'Today';
  Money transfer = Money();
  transfer.buy = true;
  transfer.fee = '200';
  transfer.image = 'Transfer.png';
  transfer.name = 'Transfer to Naman';
  transfer.time = 'Sept/16/2025';

  return[upwork,starbucks, transfer, upwork, starbucks, transfer];
}