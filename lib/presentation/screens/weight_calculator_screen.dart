import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      body: Column(
        children: [
          // Gradient Header
          _buildHeader(context, l10n, isRTL),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
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
                      ),

                    if (calculatorProvider.error.isNotEmpty)
                      _buildErrorCard(context, calculatorProvider.error),

                    const SizedBox(height: 16),

                    // Disclaimer
                    _buildDisclaimer(context, l10n, isRTL),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n, bool isRTL) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.85),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Back Button
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      isRTL ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.calculator,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.navCalculator,
                      style: const TextStyle(
                        fontSize: 18,
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
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
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
                  Icon(
                    LucideIcons.user,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isRTL ? 'بيانات المريض' : 'Patient Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // Reset Button
              Material(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: _resetCalculator,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      LucideIcons.rotateCcw,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
                    LucideIcons.user,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isRTL ? 'العمر' : 'Age',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
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
                      decoration: InputDecoration(
                        hintText: isRTL ? 'العمر...' : 'Age...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
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
                      border: Border.all(color: theme.colorScheme.outline),
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
          const SizedBox(height: 12),

          // Pediatric/Adult Badge
          if (_ageController.text.isNotEmpty)
            _isChild()
                ? _buildBadge(
                  context,
                  icon: LucideIcons.baby,
                  label: isRTL ? 'طفل' : 'Pediatric',
                  color: AppColors.info,
                )
                : _buildBadge(
                  context,
                  icon: LucideIcons.user,
                  label: isRTL ? 'بالغ' : 'Adult',
                  color: theme.colorScheme.secondary,
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
    final theme = Theme.of(context);
    final isSelected = _ageUnit == value;
    return GestureDetector(
      onTap: () => setState(() => _ageUnit = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(9) : Radius.zero,
            right: !isFirst ? const Radius.circular(9) : Radius.zero,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color:
                isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
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
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
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
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.shadowCard,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.pill,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isRTL ? 'اختر الدواء' : 'Select Drug',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                      ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                      : const Icon(LucideIcons.calculator, size: 16),
              label: Text(
                calculatorProvider.isLoading
                    ? (isRTL ? 'جاري الحساب...' : 'Calculating...')
                    : (isRTL ? 'حساب الجرعة' : 'Calculate Dose'),
              ),
              onPressed: calculatorProvider.isLoading ? null : _calculateDose,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
    final theme = Theme.of(context);
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
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.calculator,
                size: 16,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              Text(
                isRTL ? 'الجرعة المحسوبة' : 'Calculated Dose',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dose Value
          Text(
            result.dosage,
            style: theme.textTheme.headlineMedium?.copyWith(
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

          // Drug Info Section (matching reference design)
          if (provider.selectedDrug != null) ...[
            // Dose per kg row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isRTL ? 'الجرعة لكل كجم:' : 'Dose per kg:',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${provider.selectedDrug!.concentration} ${provider.selectedDrug!.unit}/kg',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Max dose row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isRTL ? 'الحد الأقصى للجرعة:' : 'Maximum dose:',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  provider.selectedDrug!.dosageForm,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Notes
          if (result.notes != null && result.notes!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRTL ? 'ملاحظات:' : 'Notes:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.notes!,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String error) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
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
              style: TextStyle(color: AppColors.danger.withOpacity(0.9)),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.info,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isRTL
                  ? 'هذه الحاسبة للإرشاد فقط ولا تحل محل المشورة الطبية المهنية. تحقق دائمًا من الجرعات مع مراجع موثوقة واستشر طبيبًا أو صيدليًا.'
                  : 'This calculator is for guidance only and does not replace professional medical advice. Always verify doses with reliable references and consult a doctor or pharmacist.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
