import 'package:flutter/material.dart';

// Ink and blue match the website tokens (forma/app/globals.css).
const ink = Color(0xFF152039);
const blue = Color(0xFF275CF3);
const muted = Color(0xFF646B7E);

/// Warm drafting-paper background.
const canvas = Color(0xFFF7F5F0);
const line = Color(0xFFE6E2D9);
const blueSoft = Color(0xFFE9EEFE);

/// Deep blueprint surfaces: hero panels and the desktop sidebar.
const blueprint = Color(0xFF14296E);
const blueprintInk = Color(0xFF0E1C4D);

const sage = Color(0xFF2B6E50);
const sageSoft = Color(0xFFE6F2EB);
const clay = Color(0xFFA84A22);
const claySoft = Color(0xFFFBEEE6);
const danger = Color(0xFFA82A35);
const dangerSoft = Color(0xFFFCECEC);

/// Manrope is bundled in weights 400 to 800: 800 for large display text, 700
/// for titles, 600 for labels and 500 for small text, which keeps it legible.
abstract final class AppText {
  static const eyebrow = TextStyle(
    fontSize: 11,
    letterSpacing: 1.8,
    color: muted,
    fontWeight: FontWeight.w700,
  );
  static const title = TextStyle(
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -.5,
    wordSpacing: 1.5,
    color: ink,
  );
  static const cardTitle = TextStyle(
    fontSize: 18,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -.2,
    wordSpacing: 1,
    color: ink,
  );
  static const label = TextStyle(
    fontWeight: FontWeight.w600,
    color: ink,
    wordSpacing: .8,
  );
  static const body = TextStyle(color: muted, height: 1.55, wordSpacing: .8);
  static const small = TextStyle(
    color: muted,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w500,
    wordSpacing: .8,
  );
}

ThemeData appTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: blue,
    primary: blue,
    onSurface: ink,
    surface: Colors.white,
    error: danger,
  );
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: line),
  );
  const buttonText = TextStyle(
    fontFamily: 'PlanizSans',
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'PlanizSans',
    colorScheme: scheme,
    scaffoldBackgroundColor: canvas,
    hoverColor: const Color(0x0A275CF3),
    textTheme: ThemeData.light().textTheme.apply(
      fontFamily: 'PlanizSans',
      bodyColor: ink,
      displayColor: ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'PlanizSans',
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      barrierColor: const Color(0x80152039),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        fontFamily: 'PlanizSans',
        fontSize: 21,
        fontWeight: FontWeight.w700,
        letterSpacing: -.4,
        color: ink,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'PlanizSans',
        fontSize: 14,
        height: 1.55,
        color: muted,
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: blueprint,
      headerForegroundColor: Colors.white,
      dividerColor: line,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      modalBackgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: Color(0x80152039),
      dragHandleColor: line,
      constraints: BoxConstraints(maxWidth: 640),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: muted),
      hintStyle: const TextStyle(color: muted),
      prefixIconColor: muted,
      suffixIconColor: muted,
      border: inputBorder,
      enabledBorder: inputBorder,
      disabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: blue, width: 1.6),
      ),
      errorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: danger),
      ),
      focusedErrorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: danger, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFDAD7CF),
        disabledForegroundColor: const Color(0xFF6F7078),
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: buttonText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        textStyle: buttonText,
        side: const BorderSide(color: Color(0xFFCFCABE)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: blue,
        minimumSize: const Size(0, 44),
        textStyle: buttonText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: ink),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: ink,
      disabledColor: canvas,
      checkmarkColor: Colors.white,
      side: const BorderSide(color: line),
      showCheckmark: false,
      labelStyle: TextStyle(
        fontFamily: 'PlanizSans',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        wordSpacing: .8,
        color: WidgetStateColor.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : ink,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: ink,
        selectedBackgroundColor: ink,
        selectedForegroundColor: Colors.white,
        side: const BorderSide(color: line),
        textStyle: buttonText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.transparent
            : const Color(0xFFCFCABE),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      side: const BorderSide(color: Color(0xFFB9B4A8), width: 1.4),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: blue,
      linearTrackColor: line,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
      contentTextStyle: const TextStyle(
        fontFamily: 'PlanizSans',
        fontSize: 14,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shadowColor: const Color(0x33152039),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: line),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: blueSoft,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 23,
          color: states.contains(WidgetState.selected) ? blue : muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'PlanizSans',
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w400,
          color: states.contains(WidgetState.selected) ? ink : muted,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(color: line, space: 32),
  );
}

/// Parses `#RRGGBB`, returning [fallback] for anything else.
Color parseHexColor(String? value, Color fallback) {
  if (value == null || !RegExp(r'^#[a-fA-F0-9]{6}$').hasMatch(value)) {
    return fallback;
  }
  return Color(int.parse(value.replaceFirst('#', 'FF'), radix: 16));
}
