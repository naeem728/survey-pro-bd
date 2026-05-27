// lib/core/constants/app_constants.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary       = Color(0xFF1A5276);
  static const Color primaryDark   = Color(0xFF0D2B45);
  static const Color accent        = Color(0xFF2ECC71);
  static const Color background    = Color(0xFFF4F6F7);
  static const Color card          = Color(0xFFFFFFFF);
  static const Color text          = Color(0xFF1A1A2E);
  static const Color textLight     = Color(0xFF566573);
  static const Color error         = Color(0xFFE74C3C);
  static const Color warning       = Color(0xFFF39C12);
  static const Color success       = Color(0xFF27AE60);

  // Canvas colors
  static const Color boundary      = Color(0xFF000000);  // Solid Black
  static const Color dimension     = Color(0xFFE74C3C);  // Solid Red
  static const Color diagonal      = Color(0xFFE74C3C);  // Dashed Red
  static const Color northArrow    = Color(0xFF1A5276);
  static const Color canvasBg      = Color(0xFFFAFAFA);
  static const Color gridLine      = Color(0xFFECF0F1);
  static const Color vertex        = Color(0xFF2ECC71);
  static const Color vertexFirst   = Color(0xFFE74C3C);
}

class AppTextStyles {
  static const TextStyle banglaHeading = TextStyle(
    fontFamily: 'Kalpurush',
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const TextStyle banglaBody = TextStyle(
    fontFamily: 'Kalpurush',
    fontSize: 16,
    color: AppColors.text,
  );

  static const TextStyle banglaCaption = TextStyle(
    fontFamily: 'Kalpurush',
    fontSize: 13,
    color: AppColors.textLight,
  );

  static const TextStyle banglaLabel = TextStyle(
    fontFamily: 'Kalpurush',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const TextStyle banglaButton = TextStyle(
    fontFamily: 'Kalpurush',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}

class AppConstants {
  static const String appName     = 'Survey Pro BD';
  static const String appNameBn   = 'সার্ভে প্রো বিডি';

  static const List<String> scalePresets = [
    '১৬" = ১ মাইল',
    '৩২" = ১ মাইল',
    '৬৪" = ১ মাইল',
    '১:৩৯৬০',
    '১:১৯৮০',
    'কাস্টম স্কেল',
  ];

  static const List<String> districts = [
    'ঢাকা', 'চট্টগ্রাম', 'রাজশাহী', 'সিলেট', 'খুলনা',
    'বরিশাল', 'রংপুর', 'ময়মনসিংহ', 'কুমিল্লা', 'গাজীপুর',
    'নারায়ণগঞ্জ', 'টাঙ্গাইল', 'জামালপুর', 'কিশোরগঞ্জ',
    'নেত্রকোণা', 'শেরপুর', 'ব্রাহ্মণবাড়িয়া', 'চাঁদপুর',
    'লক্ষ্মীপুর', 'ফেনী', 'নোয়াখালী', 'কক্সবাজার',
    'বান্দরবান', 'রাঙামাটি', 'খাগড়াছড়ি',
    'মানিকগঞ্জ', 'মুন্সীগঞ্জ', 'নরসিংদী', 'ফরিদপুর',
    'রাজবাড়ী', 'মাদারীপুর', 'গোপালগঞ্জ', 'শরীয়তপুর',
    'বগুড়া', 'জয়পুরহাট', 'নওগাঁ', 'নাটোর', 'চাঁপাইনবাবগঞ্জ',
    'পাবনা', 'সিরাজগঞ্জ',
    'দিনাজপুর', 'গাইবান্ধা', 'কুড়িগ্রাম', 'লালমনিরহাট',
    'নীলফামারী', 'পঞ্চগড়', 'ঠাকুরগাঁও',
    'যশোর', 'ঝিনাইদহ', 'মাগুরা', 'নড়াইল', 'সাতক্ষীরা',
    'মেহেরপুর', 'কুষ্টিয়া', 'চুয়াডাঙ্গা',
    'বাগেরহাট', 'পিরোজপুর', 'ঝালকাঠি', 'পটুয়াখালী',
    'ভোলা', 'বরগুনা',
    'হবিগঞ্জ', 'মৌলভীবাজার', 'সুনামগঞ্জ',
  ];
}
