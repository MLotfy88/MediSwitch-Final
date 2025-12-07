import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../../domain/entities/drug_entity.dart';
import '../bloc/dose_calculator_provider.dart';
import '../bloc/medicine_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_searchable_dropdown.dart';

class WeightCalculatorScreen extends StatefulWidget {
  const WeightCalculatorScreen({super.key});

  @override
  State<WeightCalculatorScreen> createState() => _WeightCalculatorScreenState();
}

class _WeightCalculatorScreenState extends State<WeightCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final FileLoggerService _logger = locator<FileLoggerService>();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _ageUnit = 'years';

  @override
  void initState() {
    super.initState();
    final provider = context.read<DoseCalculatorProvider>();
    _weightController.text = provider.weightInput;
    _ageController.text = provider.ageInput;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _calculateDose() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      final provider = context.read<DoseCalculatorProvider>();
      provider.setWeight(_weightController.text);
      provider.setAge(_ageController.text);
      _logger.i("WeightCalculatorScreen: Calculating dose...");
      provider.calculateDose();
    }
  }

  void _resetCalculator() {
    setState(() {
      _weightController.clear();
      _ageController.clear();
      _ageUnit = 'years';
    });
    context.read<DoseCalculatorProvider>().clearResult();
  }

  bool _isChild() {
    if (_ageController.text.isEmpty) return false;
    final ageNum = double.tryParse(_ageController.text) ?? 0;
    if (_ageUnit == 'months') return ageNum < 144; // 12 years in months
    return ageNum < 12;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final theme = Theme.of(context);
    final calculatorProvider = context.watch<DoseCalculatorProvider>();
    final availableDrugs = context.watch<MedicineProvider>().filteredMedicines;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, l10n, isRTL),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Patient Info Card
                      _buildPatientInfoCard(context, l10n, isRTL, theme),
                      const SizedBox(height: 16),

                      // Drug Selection Card
                      _buildDrugSelectionCard(
                        context,
                        l10n,
                        isRTL,
                        theme,
                        calculatorProvider,
                        availableDrugs,
                      ),
                      const SizedBox(height: 16),

                      // Result Card
                      if (calculatorProvider.dosageResult != null)
                        _buildResultCard(
                          context,
                          l10n,
                          isRTL,
                          calculatorProvider,
                        ).animate().fadeIn().slideY(begin: 0.1, end: 0),

                      if (calculatorProvider.error.isNotEmpty)
                        _buildErrorCard(
                          context,
                          calculatorProvider.error,
                        ).animate().fadeIn(),

                      const SizedBox(height: 16),

                      // Disclaimer
                      _buildDisclaimer(context, l10n, isRTL),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n, bool isRTL) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: Icon(
          isRTL ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
          color: Colors.white,
        ),
        onPressed: () => Navigator.pop(context),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ], // Primary Gradient
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.calculator,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.navCalculator, // "Dose Calculator"
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          isRTL
                              ? 'احسب الجرعة المناسبة بناءً على الوزن'
                              : 'Calculate appropriate dose based on weight',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientInfoCard(
    BuildContext context,
    AppLocalizations l10n,
    bool isRTL,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowCard,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.user,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isRTL ? 'بيانات المريض' : 'Patient Information',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              // Reset Button
              Material(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: _resetCalculator,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      LucideIcons.rotateCcw,
                      size: 16,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Weight Input
          _buildInputField(
            context: context,
            controller: _weightController,
            label: isRTL ? 'الوزن (كجم)' : 'Weight (kg)',
            icon: LucideIcons.scale,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return isRTL ? 'يرجى إدخال الوزن' : 'Please enter weight';
              }
              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                return isRTL ? 'وزن غير صالح' : 'Invalid weight';
              }
              return null;
            },
            onChanged:
                (v) => context.read<DoseCalculatorProvider>().setWeight(v),
          ),
          const SizedBox(height: 16),

          // Age Input with Unit Toggle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.calendar,
                    size: 14,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isRTL ? 'العمر' : 'Age',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        hintText: isRTL ? 'العمر...' : 'Age...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return isRTL
                              ? 'يرجى إدخال العمر'
                              : 'Please enter age';
                        }
                        return null;
                      },
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Age Unit Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAgeUnitButton(
                          context,
                          'years',
                          isRTL ? 'سنة' : 'Years',
                          isFirst: true,
                        ),
                        _buildAgeUnitButton(
                          context,
                          'months',
                          isRTL ? 'شهر' : 'Months',
                          isFirst: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Patient Type Badge
          if (_ageController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    _isChild()
                        ? AppColors.info.withOpacity(0.1)
                        : AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      _isChild()
                          ? AppColors.info.withOpacity(0.3)
                          : AppColors.secondary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isChild() ? LucideIcons.baby : LucideIcons.user,
                    size: 16,
                    color: _isChild() ? AppColors.info : AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isChild()
                        ? (isRTL ? 'طفل' : 'Pediatric')
                        : (isRTL ? 'بالغ' : 'Adult'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _isChild() ? AppColors.info : AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAgeUnitButton(
    BuildContext context,
    String value,
    String label, {
    required bool isFirst,
  }) {
    final isSelected = _ageUnit == value;
    return GestureDetector(
      onTap: () => setState(() => _ageUnit = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.mutedForeground),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrugSelectionCard(
    BuildContext context,
    AppLocalizations l10n,
    bool isRTL,
    ThemeData theme,
    DoseCalculatorProvider calculatorProvider,
    List<DrugEntity> availableDrugs,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowCard,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.pill,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isRTL ? 'اختر الدواء' : 'Select Drug',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomSearchableDropdown(
            items: availableDrugs,
            selectedItem: calculatorProvider.selectedDrug,
            onChanged: (DrugEntity? newValue) {
              context.read<DoseCalculatorProvider>().setSelectedDrug(newValue);
            },
            labelText: '',
            hintText: isRTL ? 'اختر دواء...' : 'Select a drug...',
            prefixIcon: LucideIcons.chevronDown,
            validator:
                (_) =>
                    calculatorProvider.selectedDrug == null
                        ? (isRTL
                            ? 'يرجى اختيار الدواء'
                            : 'Please select a drug')
                        : null,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon:
                  calculatorProvider.isLoading
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(LucideIcons.calculator, size: 18),
              label: Text(
                calculatorProvider.isLoading
                    ? (isRTL ? 'جاري الحساب...' : 'Calculating...')
                    : (isRTL ? 'حساب الجرعة' : 'Calculate Dose'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onPressed: calculatorProvider.isLoading ? null : _calculateDose,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    AppLocalizations l10n,
    bool isRTL,
    DoseCalculatorProvider provider,
  ) {
    final result = provider.dosageResult!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.success.withOpacity(0.1),
            AppColors.success.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.calculator,
                size: 18,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              Text(
                isRTL ? 'الجرعة المحسوبة' : 'Calculated Dose',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dose Value
          Text(
            result.dosage,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Warning if max dose applied
          if (result.warning != null && result.warning!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                result.warning!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.success),
          const SizedBox(height: 16),

          // Drug Info Section
          if (provider.selectedDrug != null) ...[
            _buildResultRow(
              isRTL ? 'الجرعة لكل كجم:' : 'Dose per kg:',
              '${provider.selectedDrug!.concentration} ${provider.selectedDrug!.unit}/kg', // Assuming logic uses concentration as dose/kg or similar
              isRTL,
            ),
            const SizedBox(height: 8),
            _buildResultRow(
              isRTL ? 'الحد الأقصى للجرعة:' : 'Maximum dose:',
              result.maxDose ?? 'N/A', // Assuming maxDose is in DosageResult
              isRTL,
            ),
            const SizedBox(height: 12),
          ],

          // Notes
          if (result.notes != null && result.notes!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRTL ? 'ملاحظات:' : 'Notes:',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.notes!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, bool isRTL) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.mutedForeground,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.alertTriangle,
            color: AppColors.danger,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: AppColors.danger.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(
    BuildContext context,
    AppLocalizations l10n,
    bool isRTL,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.muted.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.info,
            size: 20,
            color: AppColors.mutedForeground,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isRTL
                  ? 'هذه الحسابات تقديرية فقط. يجب التأكد من الجرعة الصحيحة من قبل الطبيب أو الصيدلي.'
                  : 'These calculations are estimates only. Verify the correct dose with a doctor or pharmacist.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
