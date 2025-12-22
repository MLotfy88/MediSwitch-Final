/// Utility for parsing medication dosage strings.
class DosageParser {
  /// Represents a parsed concentration: amount (mg, mcg, etc.) per volume (ml).
  /// If volume is null, it might be a solid form (e.g. 500mg tablet).
  static ({double amount, String unit, double? volume, String? volumeUnit})?
  parseConcentration(String concentration) {
    if (concentration.isEmpty) return null;

    // Clean string: remove spaces, lowercase
    final clean = concentration.toLowerCase().replaceAll(' ', '');

    // Pattern 1: Simple Xmg (e.g., "500mg", "1gm", "50mcg")
    // Pattern 2: Xmg/Yml (e.g., "250mg/5ml", "100mg/1ml", "0.5mg/2ml")

    // Regex for Amount part (Start of string)
    // Matches numbers (int or float) followed by unit (mg, gm, g, mcg, iu)
    // Regex for Amount part (Start of string)
    // Matches numbers (int or float) followed by unit (mg, gm, g, mcg, iu)
    final amountRegex = RegExp(r'^(\d*\.?\d+)(mg|gm|g|mcg|iu|%)');
    final amountMatch = amountRegex.firstMatch(clean);

    if (amountMatch == null) return null;

    var amount = double.parse(amountMatch.group(1)!);
    var unit = amountMatch.group(2)!;

    // Normalize units to mg if possible, or keep as is.
    // This is optional but good for calculation consistency.
    if (unit == 'gm' || unit == 'g') {
      amount *= 1000;
      unit = 'mg';
    }

    // Check for "per volume" part
    final remaining = clean.substring(amountMatch.end);
    double? volume;
    String? volumeUnit;

    if (remaining.startsWith('/')) {
      // Regex for Volume part
      // Matches / followed by optional number and unit (ml, l)
      // implicity /ml means /1ml
      final volumeRegex = RegExp(r'^/?(\d*\.?\d+)?(ml|l)$');
      final volumeMatch = volumeRegex.firstMatch(remaining);

      if (volumeMatch != null) {
        final volumeStr = volumeMatch.group(1);
        volume =
            volumeStr != null && volumeStr.isNotEmpty
                ? double.parse(volumeStr)
                : 1.0; // Default to 1 if just /ml
        volumeUnit = volumeMatch.group(2);
      }
    }

    return (amount: amount, unit: unit, volume: volume, volumeUnit: volumeUnit);
  }

  /// Helper to calculate volume needed for a target dose
  static double? calculateVolume({
    required double targetDoseMg,
    required double concentrationAmountMg,
    required double concentrationVolumeMl,
  }) {
    if (concentrationAmountMg == 0) return null;
    return (targetDoseMg * concentrationVolumeMl) / concentrationAmountMg;
  }

  /// Helper to calculate number of units (tablets/capsules) needed
  static double? calculateUnits({
    required double targetDoseMg,
    required double concentrationAmountMg,
  }) {
    if (concentrationAmountMg == 0) return null;
    return targetDoseMg / concentrationAmountMg;
  }
}
