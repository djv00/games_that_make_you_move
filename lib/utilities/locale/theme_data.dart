import 'package:flutter/material.dart';
import 'package:flutter_steps_tracker/utilities/constants/app_colors.dart';

class MainTheme {
  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      // 1. 【关键修改】: backgroundColor, primaryColor, errorColor 等
      //    现在都必须放在 colorScheme 内部。
      colorScheme: ColorScheme.light(
        primary: AppColors.kPrimaryColor,        // 替换了旧的 primaryColor
        background: AppColors.kRedAccentColor,  // 替换了旧的 backgroundColor
        error: AppColors.kErrorColor,           // 替换了旧的 errorColor
        // 你也可以在这里定义 secondary, surface 等
      ),

      scaffoldBackgroundColor: AppColors.kScaffoldBackgroundColor,
      // primaryColor: AppColors.kPrimaryColor,             // 【已删除】 被移入 colorScheme
      // backgroundColor: AppColors.kRedAccentColor,      // 【已删除】 被移入 colorScheme
      // errorColor: AppColors.kErrorColor,               // 【已删除】 被移入 colorScheme
      primaryColorDark: AppColors.kGreyColor,           // (这个也已弃用，但暂时不报错)
      primaryColorLight: AppColors.kPrimaryColor,       // (这个也已弃用，但暂时不报错)

      dividerTheme: DividerThemeData(
        color: AppColors.kGreyColor.withOpacity(0.4),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.kScaffoldBackgroundColor,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.kScaffoldBackgroundColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: AppColors.kScaffoldBackgroundColor,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide: const BorderSide(
            color: AppColors.kPrimaryColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide: const BorderSide(
            color: AppColors.kPrimaryColor,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide: const BorderSide(
            color: AppColors.kErrorColor,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide: const BorderSide(
            color: AppColors.kErrorColor,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide: const BorderSide(
            color: AppColors.kPrimaryColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide: const BorderSide(
            color: AppColors.kPrimaryColor,
          ),
        ),
      ),
      canvasColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
    );
  }

  static ThemeData darkTheme(BuildContext context) {
    return ThemeData(
      // 2. 【关键修改】: darkTheme 也一样处理
      colorScheme: ColorScheme.dark(
        primary: AppColors.kScaffoldBackgroundColor, // 替换了旧的 primaryColor
        background: AppColors.kRedAccentColor,     // 替换了旧的 backgroundColor
        error: AppColors.kErrorColor,              // 替换了旧的 errorColor
      ),

      scaffoldBackgroundColor: AppColors.kBlackColor,
      // primaryColor: AppColors.kScaffoldBackgroundColor,  // 【已删除】 被移入 colorScheme
      // backgroundColor: AppColors.kRedAccentColor,      // 【已删除】 被移入 colorScheme
      // errorColor: AppColors.kErrorColor,               // 【已删除】 被移入 colorScheme
      primaryColorLight: AppColors.kPrimaryColor,
      primaryColorDark: AppColors.kScaffoldBackgroundColor,

      dividerTheme: DividerThemeData(
        color: AppColors.kScaffoldBackgroundColor.withOpacity(0.4),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.kBlackColor,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.kScaffoldBackgroundColor,
      ),
      cardColor: Colors.grey,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.kScaffoldBackgroundColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: AppColors.kScaffoldBackgroundColor,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide: const BorderSide(
            color: AppColors.kPrimaryColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide: const BorderSide(
            color: AppColors.kPrimaryColor,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide: const BorderSide(
            color: AppColors.kErrorColor,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide: const BorderSide(
            color: AppColors.kErrorColor,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide: const BorderSide(
            color: AppColors.kPrimaryColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.0),
          borderSide: const BorderSide(
            color: AppColors.kPrimaryColor,
          ),
        ),
      ),
      canvasColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
    );
  }
}