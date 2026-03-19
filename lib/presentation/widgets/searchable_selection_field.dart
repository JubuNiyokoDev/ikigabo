import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';

class SelectionOption<T> {
  final T value;
  final String label;

  const SelectionOption({required this.value, required this.label});
}

class SearchableSelectionField<T> extends StatelessWidget {
  final String label;
  final String hint;
  final List<SelectionOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final IconData? prefixIcon;
  final bool enabled;
  final String? searchHint;
  final String? noResultsText;

  const SearchableSelectionField({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.prefixIcon,
    this.enabled = true,
    this.searchHint,
    this.noResultsText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localeCode = Localizations.localeOf(context).languageCode;
    final effectiveSearchHint =
        searchHint ??
        _l(
          localeCode,
          fr: 'Rechercher...',
          en: 'Search...',
          rn: 'Rondera...',
          sw: 'Tafuta...',
        );
    final effectiveNoResultsText =
        noResultsText ??
        _l(
          localeCode,
          fr: 'Aucun resultat',
          en: 'No results',
          rn: 'Nta bisubizo',
          sw: 'Hakuna matokeo',
        );
    final selectedLabel = options
        .cast<SelectionOption<T>?>()
        .firstWhere(
          (option) => option?.value == selectedValue,
          orElse: () => null,
        )
        ?.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 6.h),
        InkWell(
          onTap: enabled
              ? () => _openSelector(
                  context,
                  isDark,
                  effectiveSearchHint,
                  effectiveNoResultsText,
                )
              : null,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              children: [
                if (prefixIcon != null)
                  Padding(
                    padding: EdgeInsets.only(right: 10.w),
                    child: Icon(
                      prefixIcon,
                      size: 18.sp,
                      color: enabled
                          ? AppColors.primary
                          : Colors.grey.withValues(alpha: 0.7),
                    ),
                  ),
                Expanded(
                  child: Text(
                    selectedLabel ?? hint,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: selectedLabel == null
                          ? (isDark
                                ? AppColors.textSecondaryDark
                                : Colors.grey.shade500)
                          : (isDark ? AppColors.textDark : Colors.black87),
                    ),
                  ),
                ),
                Icon(
                  AppIcons.menu,
                  size: 16.sp,
                  color: enabled
                      ? (isDark
                            ? AppColors.textSecondaryDark
                            : Colors.grey.shade600)
                      : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openSelector(
    BuildContext context,
    bool isDark,
    String effectiveSearchHint,
    String effectiveNoResultsText,
  ) async {
    final selected = await showModalBottomSheet<SelectionOption<T>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (context) {
        final controller = TextEditingController();
        var filtered = List<SelectionOption<T>>.from(options);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16.w,
                  12.h,
                  16.w,
                  16.h + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.borderDark
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textDark : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: effectiveSearchHint,
                        prefixIcon: Icon(AppIcons.search, size: 18.sp),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.backgroundDark
                            : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          final query = value.trim().toLowerCase();
                          filtered = options
                              .where(
                                (item) =>
                                    item.label.toLowerCase().contains(query),
                              )
                              .toList();
                        });
                      },
                    ),
                    SizedBox(height: 10.h),
                    Flexible(
                      child: filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                child: Text(
                                  effectiveNoResultsText,
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : Colors.grey.shade600,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final isSelected = item.value == selectedValue;
                                return ListTile(
                                      dense: true,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                      ),
                                      title: Text(
                                        item.label,
                                        style: TextStyle(fontSize: 13.sp),
                                      ),
                                      trailing: isSelected
                                          ? Icon(
                                              AppIcons.success,
                                              color: AppColors.primary,
                                              size: 16.sp,
                                            )
                                          : null,
                                      onTap: () => Navigator.pop(context, item),
                                    )
                                    .animate(delay: (index * 24).ms)
                                    .fadeIn(duration: 180.ms)
                                    .slideX(
                                      begin: 0.03,
                                      end: 0,
                                      duration: 180.ms,
                                    );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected != null) {
      onChanged(selected.value);
    }
  }

  String _l(
    String localeCode, {
    required String fr,
    required String en,
    required String rn,
    required String sw,
  }) {
    return switch (localeCode) {
      'en' => en,
      'rn' => rn,
      'sw' => sw,
      _ => fr,
    };
  }
}
