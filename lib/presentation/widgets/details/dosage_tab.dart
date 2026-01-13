import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/constants/app_spacing.dart';
import 'package:mediswitch/core/utils/dosage_parser.dart';
import 'package:mediswitch/domain/entities/dosage_guidelines.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/presentation/bloc/medicine_provider.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';
import 'package:provider/provider.dart';

/// تبويبة الجرعات المصغرة
class DosageTab extends StatelessWidget {
  /// Creates a dosage tab
  const DosageTab({required this.drug, super.key});

  /// The drug entity
  final DrugEntity drug;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = l10n.localeName == 'ar';

    return SingleChildScrollView(
      padding: AppSpacing.edgeInsetsAllMedium,
      child: FutureBuilder<List<DosageGuidelines>>(
        future: Provider.of<MedicineProvider>(
          context,
          listen: false,
        ).getDosageGuidelines(drug.id ?? 0),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 1. Handle Fetch Errors
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.alertTriangle,
                      size: 48,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'خطأ في تحميل البيانات\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          }

          // 2. Wrap UI logic in Try-Catch to debug "Gray Screen"
          try {
            // Fix: Cast explicitly to base type to prevent runtime type mismatch in reduce()
            // Error was: (Base, Base)->Base is not subtype of (Model, Model)->Model
            // Fix: Cast explicitly to base type to prevent runtime type mismatch in reduce()
            final guidelines =
                (snapshot.data ?? []).cast<DosageGuidelines>().toList();

            if (guidelines.isEmpty) {
              return Center(
                child: Padding(
                  padding: AppSpacing.edgeInsetsAllLarge,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.fileX, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        isAr
                            ? 'لا توجد معلومات جرعات متاحة لهذا الدواء حالياً.'
                            : 'No dosage information available for this drug yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'MedID: ${drug.id}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Safe aggregation logic
            final primary = guidelines.reduce((curr, next) {
              try {
                int currScore = 0;
                int nextScore = 0;

                if (curr.blackBoxWarning?.isNotEmpty == true) currScore += 5;
                if (curr.contraindications?.isNotEmpty == true) currScore += 2;
                if (curr.warnings?.isNotEmpty == true) currScore += 1;
                if (curr.adverseReactions?.isNotEmpty == true) currScore += 1;

                if (next.blackBoxWarning?.isNotEmpty == true) nextScore += 5;
                if (next.contraindications?.isNotEmpty == true) nextScore += 2;
                if (next.warnings?.isNotEmpty == true) nextScore += 1;
                if (next.adverseReactions?.isNotEmpty == true) nextScore += 1;

                return currScore >= nextScore ? curr : next;
              } catch (e) {
                return curr; // Fallback
              }
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StandardDoseCard(
                  guideline: primary,
                  drugForm: drug.dosageForm,
                  isAr: isAr,
                  concentration: drug.concentration,
                ),
                const SizedBox(height: 16),
                if (drug.concentration.isNotEmpty)
                  _MiniDoseCalculator(
                    concentration: drug.concentration,
                    standardDose: primary.minDose,
                    frequency: primary.frequency,
                    isAr: isAr,
                  ),
                if (primary.instructions != null &&
                    primary.instructions!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _InstructionsCard(
                    instructions: primary.instructions!,
                    isAr: isAr,
                  ),
                ],

                // --- New Rich Data Sections ---
                if (primary.blackBoxWarning != null &&
                    primary.blackBoxWarning!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SafetyAlertCard(
                    title:
                        isAr ? 'تحذير خطير (Boxed Warning)' : 'Boxed Warning',
                    content: primary.blackBoxWarning ?? '',
                    icon: LucideIcons.alertTriangle,
                    color: Colors.red,
                    isAr: isAr,
                  ),
                ],

                if (primary.renalAdjustment != null &&
                    primary.renalAdjustment!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SafetyAlertCard(
                    title: isAr ? 'تعديل جرعة الكلى' : 'Renal Adjustment',
                    content: primary.renalAdjustment ?? '',
                    icon: LucideIcons.filter,
                    color: Colors.purple,
                    isAr: isAr,
                  ),
                ],

                if (primary.hepaticAdjustment != null &&
                    primary.hepaticAdjustment!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SafetyAlertCard(
                    title: isAr ? 'تعديل جرعة الكبد' : 'Hepatic Adjustment',
                    content: primary.hepaticAdjustment ?? '',
                    icon: LucideIcons.activity,
                    color: Colors.brown,
                    isAr: isAr,
                  ),
                ],

                if (primary.contraindications != null &&
                    primary.contraindications!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SafetyAlertCard(
                    title: isAr ? 'موانع الاستعمال' : 'Contraindications',
                    content: primary.contraindications ?? '',
                    icon: LucideIcons.ban,
                    color: Colors.redAccent,
                    isAr: isAr,
                  ),
                ],

                if (primary.warnings != null &&
                    primary.warnings!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SafetyAlertCard(
                    title: isAr ? 'تحذيرات' : 'Warnings',
                    content: primary.warnings ?? '',
                    icon: LucideIcons.alertCircle,
                    color: Colors.orange[800]!,
                    isAr: isAr,
                  ),
                ],

                if (primary.adverseReactions != null &&
                    primary.adverseReactions!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SafetyAlertCard(
                    title: isAr ? 'الأعراض الجانبية' : 'Adverse Reactions',
                    content: primary.adverseReactions ?? '',
                    icon: LucideIcons.frown,
                    color: Colors.grey[700]!,
                    isAr: isAr,
                    isCollapsible: true,
                  ),
                ],

                // --- NCBI Clinical Info ---
                if (primary.ncbiIndications != null &&
                    primary.ncbiIndications!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SafetyAlertCard(
                    title: isAr ? 'دواعي الاستعمال' : 'Indications & Usage',
                    content: primary.ncbiIndications ?? '',
                    icon: LucideIcons.stethoscope,
                    color: Colors.blue,
                    isAr: isAr,
                    isCollapsible: true,
                  ),
                ],

                if (primary.ncbiMechanism != null &&
                    primary.ncbiMechanism!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SafetyAlertCard(
                    title: isAr ? 'آلية العمل' : 'Mechanism of Action',
                    content: primary.ncbiMechanism ?? '',
                    icon: LucideIcons.zap,
                    color: Colors.amber[800]!,
                    isAr: isAr,
                    isCollapsible: true,
                  ),
                ],

                if (primary.ncbiMonitoring != null &&
                    primary.ncbiMonitoring!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SafetyAlertCard(
                    title: isAr ? 'المراقبة' : 'Monitoring Parameters',
                    content: primary.ncbiMonitoring ?? '',
                    icon: LucideIcons.eye,
                    color: Colors.teal[700]!,
                    isAr: isAr,
                    isCollapsible: true,
                  ),
                ],

                if (primary.ncbiAdministration != null &&
                    primary.ncbiAdministration!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SafetyAlertCard(
                    title: isAr ? 'طريقة الإعطاء' : 'Administration',
                    content: primary.ncbiAdministration ?? '',
                    icon: LucideIcons.syringe,
                    color: Colors.indigo,
                    isAr: isAr,
                    isCollapsible: true,
                  ),
                ],

                if (primary.structuredDosage != null &&
                    primary.structuredDosage!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _StructuredDosageView(
                    compressedData: primary.structuredDosage!,
                    isAr: isAr,
                  ),
                ],
              ],
            ).animate().fadeIn(duration: 300.ms);
          } catch (e, s) {
            return Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SelectableText(
                'UI RENDER ERROR:\n$e\n\n$s',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            );
          }
        },
      ),
    );
  }
}

/// Renders the new JSON-based cards (The "Focused" View)
class _StructuredDosageView extends StatefulWidget {
  const _StructuredDosageView({
    required this.compressedData,
    required this.isAr,
  });

  final List<int> compressedData;
  final bool isAr;

  @override
  State<_StructuredDosageView> createState() => _StructuredDosageViewState();
}

class _StructuredDosageViewState extends State<_StructuredDosageView> {
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _parseData();
  }

  void _parseData() {
    try {
      // 1. Decompress ZLIB
      final bytes = ZLibDecoder().decodeBytes(widget.compressedData);
      final jsonStr = utf8.decode(bytes);
      final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
      setState(() {
        _data = jsonMap;
      });
    } catch (e) {
      debugPrint('Error parsing structured dosage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) return const SizedBox.shrink();

    final uiSections = _data!['ui_sections'] as List<dynamic>? ?? [];
    if (uiSections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header for the new section
        Row(
          children: [
            Icon(LucideIcons.sparkles, size: 18, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              widget.isAr ? 'الجرعات الذكية' : 'Smart Dosages',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...uiSections.map((section) {
          if (section['type'] == 'table_cards') {
            final cards = section['data'] as List<dynamic>;
            return Column(
              children:
                  cards
                      .map(
                        (c) => _FocusedDosageCard(
                          data: c as Map<String, dynamic>,
                          isAr: widget.isAr,
                        ),
                      )
                      .toList(),
            );
          }
          return const SizedBox.shrink();
        }).toList(),
      ],
    );
  }
}

class _FocusedDosageCard extends StatefulWidget {
  const _FocusedDosageCard({required this.data, required this.isAr});

  final Map<String, dynamic> data;
  final bool isAr;

  @override
  State<_FocusedDosageCard> createState() => _FocusedDosageCardState();
}

class _FocusedDosageCardState extends State<_FocusedDosageCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.data;

    // Extract fields
    final hero = data['hero_dose'] as String?;
    final contextTitle =
        data['Indication/Context'] ?? data['Population'] ?? 'Dosage Info';
    final String instruction =
        (data['Dosage Instruction'] ?? data.values.join('\n')).toString();
    final maxDose = data['max_dose_constraint'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header (Context)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.activity,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (contextTitle ?? 'Dosage Info').toString(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. HERO DOSE (The "Focus")
                if (hero != null) ...[
                  Text(
                    hero,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // 3. Max Dose tag
                if (maxDose != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.ban,
                          size: 12,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Max: $maxDose',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                // 4. Collapsible Details
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Text(
                          _expanded
                              ? (widget.isAr
                                  ? 'إخفاء التفاصيل'
                                  : 'Hide Details')
                              : (widget.isAr
                                  ? 'عرض التفاصيل والتحذيرات'
                                  : 'Show Details & Warnings'),
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _expanded
                              ? LucideIcons.chevronUp
                              : LucideIcons.chevronDown,
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_expanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      instruction,
                      style: TextStyle(
                        height: 1.5,
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StandardDoseCard extends StatelessWidget {
  const _StandardDoseCard({
    required this.guideline,
    required this.drugForm,
    required this.isAr,
    this.concentration,
  });

  final DosageGuidelines? guideline;
  final String drugForm;
  final bool isAr;
  final String? concentration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;

    // Logic to avoid generic data
    final hasValidDose = guideline?.minDose != null && guideline!.minDose! > 0;

    // "Hero" Content is the Instructions if available (WikEM protocol)
    // If not, it falls back to a structured dose summary
    final heroInstruction = guideline?.instructions;
    final bool showInstructionAsHero =
        heroInstruction != null && heroInstruction.length > 20;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.border.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.05),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HERO CONTENT (The Main Protocol)
          if (showInstructionAsHero) ...[
            Row(
              children: [
                Icon(
                  LucideIcons.scroll,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isAr ? 'بروتوكول العلاج' : 'Dosing Protocol',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                heroInstruction!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 2. Numeric Summary (Only if valid and makes sense)
          // Hide if just "As directed" or useless
          if (hasValidDose) ...[
            Row(
              children: [
                Expanded(
                  child: _BigNumberCard(
                    label: isAr ? 'الجرعة' : 'Dose',
                    value: _formatDoseRange(guideline!),
                    subValue: concentration != null ? '($concentration)' : null,
                    icon: LucideIcons.pill,
                    color: theme.colorScheme.primary,
                    isAr: isAr,
                  ),
                ),
                if (guideline?.frequency != null &&
                    guideline!.frequency! > 0) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BigNumberCard(
                      label: isAr ? 'التكرار' : 'Frequency',
                      value: _formatFrequencyShort(guideline!.frequency!, isAr),
                      icon: LucideIcons.clock,
                      color: Colors.orange,
                      isAr: isAr,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDoseRange(DosageGuidelines g) {
    if (g.minDose == null) return '-';
    if (g.maxDose != null && g.minDose != null && g.maxDose! > g.minDose!) {
      return '${g.minDose!.toStringAsFixed(0)}-${g.maxDose!.toStringAsFixed(0)} mg';
    }
    return '${g.minDose!.toStringAsFixed(0)} mg';
  }

  String _formatFrequencyShort(int freq, bool isAr) {
    if (freq == 24) return isAr ? '1× يومياً' : '1x Daily';
    if (freq == 12) return isAr ? '2× يومياً' : '2x Daily';
    if (freq == 8) return isAr ? '3× يومياً' : '3x Daily';
    if (freq == 6) return isAr ? '4× يومياً' : '4x Daily';
    return isAr ? 'كل $freq س' : 'q${freq}h';
  }
}

class _BigNumberCard extends StatelessWidget {
  const _BigNumberCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isAr,
    this.subValue,
  });

  final String label;
  final String value;
  final String? subValue;
  final IconData icon;
  final Color color;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (subValue != null) ...[
            const SizedBox(height: 4),
            Text(
              subValue!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniDoseCalculator extends StatefulWidget {
  const _MiniDoseCalculator({
    required this.concentration,
    required this.isAr,
    this.standardDose,
    this.frequency,
  });

  final String concentration;
  final double? standardDose;
  final int? frequency;
  final bool isAr;

  @override
  State<_MiniDoseCalculator> createState() => _MiniDoseCalculatorState();
}

class _MiniDoseCalculatorState extends State<_MiniDoseCalculator> {
  final _weightController = TextEditingController();
  final _dosePerKgController = TextEditingController(text: '10');
  double? _resultMg;
  double? _resultMl;

  // New: Frequency logic
  int _timesPerDay = 3; // Default

  @override
  void initState() {
    super.initState();
    if (widget.standardDose != null) {
      _dosePerKgController.text = widget.standardDose!.toStringAsFixed(0);
    }
    if (widget.frequency != null) {
      // If frequency is hours (e.g. 8), times = 24/8 = 3.
      if (widget.frequency! > 0 && widget.frequency! <= 24) {
        _timesPerDay = (24 / widget.frequency!).round();
        if (_timesPerDay == 0) _timesPerDay = 1;
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _dosePerKgController.dispose();
    super.dispose();
  }

  void _calculate() {
    final weight = double.tryParse(_weightController.text);
    final dosePerKg = double.tryParse(_dosePerKgController.text);

    if (weight == null || dosePerKg == null) {
      setState(() {
        _resultMg = null;
        _resultMl = null;
      });
      return;
    }

    final totalMg = weight * dosePerKg;
    final parsed = DosageParser.parseConcentration(widget.concentration);

    setState(() {
      _resultMg = totalMg;
      if (parsed != null && parsed.volume != null && parsed.amount > 0) {
        _resultMl = (totalMg / parsed.amount) * parsed.volume!;
      } else {
        _resultMl = null;
      }
    });
  }

  void _copyResult() {
    if (_resultMg == null) return;

    // Construct detailed string
    String doseStr =
        _resultMl != null
            ? '${_resultMg!.toStringAsFixed(1)} mg (${_resultMl!.toStringAsFixed(1)} ml)'
            : '${_resultMg!.toStringAsFixed(1)} mg';

    String freqStr =
        widget.isAr ? '$_timesPerDay مرات يومياً' : '$_timesPerDay times daily';

    if (widget.frequency != null && widget.frequency! > 0) {
      // If usage is specifically "Every X hours"
      freqStr =
          widget.isAr
              ? 'كل ${widget.frequency} ساعة ($_timesPerDay مرات يومياً)'
              : 'Every ${widget.frequency} hours ($_timesPerDay times daily)';
    }

    final text = '$doseStr - $freqStr';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isAr ? 'تم النسخ' : 'Copied'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.border.withValues(alpha: 0.3)),
        boxShadow: appColors.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.calculator,
                size: 18,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.isAr ? 'حاسبة الجرعة السريعة' : 'Quick Dose Calculator',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InputField(
                  controller: _weightController,
                  label: widget.isAr ? 'الوزن (kg)' : 'Weight (kg)',
                  hint: '25',
                  onChanged: (_) => _calculate(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InputField(
                  controller: _dosePerKgController,
                  label: widget.isAr ? 'mg/kg' : 'mg/kg',
                  hint: '10',
                  onChanged: (_) => _calculate(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Frequency Selector Chips
          Text(
            widget.isAr ? 'التكرار:' : 'Frequency:',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _FrequencyChip(
                label: widget.isAr ? '1×' : '1x',
                subLabel: widget.isAr ? 'يومياً' : 'daily',
                isSelected: _timesPerDay == 1,
                onTap:
                    () => setState(() {
                      _timesPerDay = 1;
                    }),
                theme: theme,
              ),
              const SizedBox(width: 8),
              _FrequencyChip(
                label: widget.isAr ? '2×' : '2x',
                subLabel: widget.isAr ? 'يومياً' : 'daily',
                isSelected: _timesPerDay == 2,
                onTap:
                    () => setState(() {
                      _timesPerDay = 2;
                    }),
                theme: theme,
              ),
              const SizedBox(width: 8),
              _FrequencyChip(
                label: widget.isAr ? '3×' : '3x',
                subLabel: widget.isAr ? 'يومياً' : 'daily',
                isSelected: _timesPerDay == 3,
                onTap:
                    () => setState(() {
                      _timesPerDay = 3;
                    }),
                theme: theme,
              ),
              const SizedBox(width: 8),
              _FrequencyChip(
                label: widget.isAr ? '4×' : '4x',
                subLabel: widget.isAr ? 'يومياً' : 'daily',
                isSelected: _timesPerDay == 4,
                onTap:
                    () => setState(() {
                      _timesPerDay = 4;
                    }),
                theme: theme,
              ),
            ],
          ),

          const SizedBox(height: 12),
          if (_resultMg != null)
            GestureDetector(
              onTap: _copyResult,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                      theme.colorScheme.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.isAr ? 'الجرعة الواحدة:' : 'Single Dose:',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        Icon(
                          LucideIcons.copy,
                          size: 16,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _resultMl != null
                          ? '${_resultMg!.toStringAsFixed(1)} mg (${_resultMl!.toStringAsFixed(1)} ml)'
                          : '${_resultMg!.toStringAsFixed(1)} mg',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),

                    const Divider(height: 24),

                    // Daily Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isAr
                                  ? 'الجرعة اليومية الإجمالية:'
                                  : 'Daily Total:',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            Text(
                              _resultMl != null
                                  ? '${(_resultMg! * _timesPerDay).toStringAsFixed(0)} mg (${(_resultMl! * _timesPerDay).toStringAsFixed(1)} ml)'
                                  : '${(_resultMg! * _timesPerDay).toStringAsFixed(0)} mg',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_timesPerDay× ${widget.isAr ? "يومياً" : "daily"}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Frequency selector chip for the mini calculator
class _FrequencyChip extends StatelessWidget {
  const _FrequencyChip({
    required this.label,
    required this.subLabel,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final String subLabel;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color:
                      isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                ),
              ),
              Text(
                subLabel,
                style: TextStyle(
                  fontSize: 9,
                  color:
                      isSelected
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  const _InstructionsCard({required this.instructions, required this.isAr});

  final String instructions;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColors.infoSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appColors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.info, size: 16, color: appColors.info),
              const SizedBox(width: 8),
              Text(
                isAr ? 'إرشادات سريرية' : 'Clinical Guidelines',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: appColors.info,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            _cleanInstructions(instructions),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _cleanInstructions(String text) {
    var cleaned = text;

    // 1. Remove "Standard Dose: X mg." prefix if present
    // Matches "Standard Dose: 1000.0mg. " or similar variations
    final prefixRegex = RegExp(
      r'^Standard Dose:\s*[\d\.]+\s*mg\.?\s*',
      caseSensitive: false,
    );
    cleaned = cleaned.replaceAll(prefixRegex, '');

    // 2. Format headers (WORDS IN CAPS)
    // Add double newline before headers like "DOSAGE AND ADMINISTRATION"
    // Heuristic: continuous uppercase words of length > 3
    final headerRegex = RegExp(r'([A-Z]{3,}(\s+[A-Z]{3,})*)');
    cleaned = cleaned.replaceAllMapped(headerRegex, (match) {
      final header = match.group(0);
      // Avoid matching simple acronyms like WHO, FDA unless it's a longer phrase
      if (header != null && header.length > 5) {
        return '\n\n$header\n';
      }
      return header ?? '';
    });

    // 3. Clean up generic weirdness
    cleaned = cleaned.replaceAll(' .', '.'); // fix space before dot
    cleaned = cleaned.trim();

    return cleaned;
  }
}

class _SafetyAlertCard extends StatefulWidget {
  const _SafetyAlertCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
    required this.isAr,
    this.isCollapsible = false,
  });

  final String title;
  final String content;
  final IconData icon;
  final Color color;
  final bool isAr;
  final bool isCollapsible;

  @override
  State<_SafetyAlertCard> createState() => _SafetyAlertCardState();
}

class _SafetyAlertCardState extends State<_SafetyAlertCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Truncate long content if collapsible and not expanded
    final showContent =
        widget.isCollapsible && !_isExpanded
            ? (widget.content.length > 150
                ? '${widget.content.substring(0, 150)}...'
                : widget.content)
            : widget.content;

    return Directionality(
      textDirection: widget.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: widget.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.isCollapsible)
                    InkWell(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          _isExpanded
                              ? LucideIcons.chevronUp
                              : LucideIcons.chevronDown,
                          size: 16,
                          color: widget.color,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: widget.color.withValues(alpha: 0.1)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                showContent,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.5,
                ),
                textAlign: widget.isAr ? TextAlign.justify : TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
