import 'package:flutter/material.dart';
import 'package:wfveflutterexample/application/app_theme/text_themes.dart';

import 'color_scheme.dart';

ThemeData get lightTheme => ThemeData.light().copyWith(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: ColorManager.primary,
        brightness: Brightness.light,
        surfaceVariant: Colors.transparent,
        background: ColorManager.bg,
        surfaceTint: ColorManager.bg,
      ),
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          filled: true,
          fillColor: ColorManager.white,
          labelStyle: textTheme.bodyMedium!.copyWith(color: ColorManager.placeHolder),
          hintStyle: textTheme.bodyMedium!.copyWith(
            color: ColorManager.placeHolderLight, height: 0.09,
            // letterSpacing: -0.5
          ),
          floatingLabelStyle: textTheme.bodyMedium!.copyWith(color: ColorManager.primary),
          errorStyle: textTheme.labelLarge!.copyWith(color: ColorManager.error, height: 0.6),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ColorManager.secondary, width: 1)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ColorManager.border, width: 1)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ColorManager.border, width: 1)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ColorManager.error, width: 1))),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        )),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          textStyle: MaterialStateProperty.all<TextStyle>(textTheme.titleLarge!),
          backgroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.pressed)
              ? ColorManager.primary
              : states.contains(MaterialState.disabled)
                  ? ColorManager.placeHolderLight
                  : ColorManager.primary),
          padding:
              MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
          shape: MaterialStateProperty.all<OutlinedBorder>(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          )),
          foregroundColor: MaterialStateProperty.resolveWith(
              (states) => states.contains(MaterialState.disabled) ? ColorManager.border : ColorManager.white),
        ),
      ),
      dividerTheme: const DividerThemeData(color: ColorManager.placeHolder, thickness: 0.3),
      disabledColor: ColorManager.placeHolder,
      scaffoldBackgroundColor: ColorManager.bg,
      // textTheme: textTheme,
    );
