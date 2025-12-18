class DosageGuidelines {
  final int? id;
  final int medId; // Relational link to Drug
  final String? dailymedSetid;
  final double? minDose;
  final double? maxDose;
  final int? frequency;
  final int? duration;
  final String? instructions;
  final String? condition;
  final String source; // 'DailyMed' or 'Local'
  final bool isPediatric;

  const DosageGuidelines({
    this.id,
    required this.medId,
    this.dailymedSetid,
    this.minDose,
    this.maxDose,
    this.frequency,
    this.duration,
    this.instructions,
    this.condition,
    this.source = 'Local',
    this.isPediatric = false,
  });
}
