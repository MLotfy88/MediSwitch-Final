import 'package:mediswitch/core/utils/dosage_parser.dart';

void main() {
  final samples = [
    '250mg/5ml',
    '500 mg',
    '1gm',
    '1000 mg',
    '100/25mg', // Complex, might need specific handling or just take first
    '125mg/5ml',
    '0.5mg/2ml',
    '50mcg',
    '10.000 iu', // Note: dot as thousands separator might need handling if not standard US
    '2%', // Percentage distinct handling or ignore
  ];

  print('Testing DosageParser...');
  for (final sample in samples) {
    final result = DosageParser.parseConcentration(sample);
    if (result != null) {
      print(
        '$sample -> Amount: ${result.amount} ${result.unit}, Volume: ${result.volume} ${result.volumeUnit ?? ""}',
      );
    } else {
      print('$sample -> Failed to parse');
    }
  }
}
