import 'package:flutter/material.dart';

const String defaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

const List<String> categories = <String>[
  'Education & Learning',
  'Health & Wellness',
  'Women & Child',
  'Employment & Skill Development',
  'Financial Services',
  'Agriculture & Rural Development',
  'Housing',
  'Social Security',
  'Business & MSME',
  'Specially Abled',
];

const List<String> indianStates = <String>[
  'All India',
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chhattisgarh',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
  'Delhi',
];

const Map<String, String> schemeQuickApplyLinks = <String, String>{
  'pm_awas_yojana_urban':
      'https://pmaymis.gov.in/pmaymis2_2024/PMAY_SURVEY/Applicant_Login.aspx',
  'pm_awas_yojana_gramin':
      'https://pmayg.dord.gov.in/applicant_public/beneficiary_details/',
  'pm_kisan': 'https://pmkisan.gov.in/',
  'pm_surya_ghar_muft_bijli': 'https://pmsuryaghar.gov.in/',
  'ayushman_bharat': 'https://mera.pmjay.gov.in/search/login',
  'pradhan_mantri_mudra_yojana': 'https://www.mudra.org.in/',
  'jan_aushadhi': 'https://janaushadhi.gov.in/',
  'skill_india': 'https://www.skillindia.gov.in/',
  'startup_india': 'https://www.startupindia.gov.in/',
  'digital_india': 'https://digitalindia.gov.in/',
  'swachh_bharat': 'https://swachhbharat.mygov.in/',
  'pradhan_mantri_garib_kalyan': 'https://www.pmgky.gov.in/',
  'national_scholarship_portal': 'https://scholarships.gov.in/',
  'ration_card_services': 'https://nfsa.gov.in/',
  'employment_guarantee': 'https://nrega.nic.in/netnrega/home.aspx',
  'pm_vishwakarma': 'https://pmvishwakarma.gov.in/',
  'lakhpati_didi': 'https://aajeevika.gov.in/en/lakhpati-didi',
  'namo_drone_didi': 'https://agricoop.gov.in/en/namo-drone-didi',
  'karunya_arogya_suraksha': 'https://karunya.kerala.gov.in/',
};

const Color primaryBlue = Color(0xFF2196F3);
const Color primaryBlueDark = Color(0xFF1B5CE5);
const Color secondaryBlue = Color(0xFF66B2FF);
const Color accentLightBlue = Color(0xFFE9F4FF);
const Color accentPaleBlue = Color(0xFFF4F9FF);
const Color surfaceCard = Color(0xFFFFFFFF);
const Color neutralText = Color(0xFF324A70);
const Color mutedText = Color(0xFF5B6C94);
const Color dividerColor = Color(0xFFE2EBFF);
const Color errorRed = Color(0xFFF44336);
const Color backgroundColor = Color(0xFFF5F8FF);

const double defaultRadius = 20;
const double largeRadius = 28;

const Gradient schemeBlueGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: <Color>[primaryBlue, primaryBlueDark],
);

const Gradient softBlueGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: <Color>[Color(0xFFE4EEFF), Color(0xFFF5FAFF)],
);

const Map<String, IconData> categoryIconMap = <String, IconData>{
  'Education & Learning': Icons.school_rounded,
  'Health & Wellness': Icons.health_and_safety_rounded,
  'Women & Child': Icons.family_restroom_rounded,
  'Employment & Skill Development': Icons.handshake_rounded,
  'Financial Services': Icons.account_balance_wallet_rounded,
  'Agriculture & Rural Development': Icons.agriculture_rounded,
  'Housing': Icons.other_houses_rounded,
  'Social Security': Icons.shield_moon_rounded,
  'Business & MSME': Icons.business_center_rounded,
  'Specially Abled': Icons.accessible_rounded,
};

const Map<String, List<Color>> categoryGradientMap = <String, List<Color>>{
  'Education & Learning': <Color>[Color(0xFF64B5F6), Color(0xFF1976D2)],
  'Health & Wellness': <Color>[Color(0xFF8BC34A), Color(0xFF388E3C)],
  'Women & Child': <Color>[Color(0xFFFF8A80), Color(0xFFE53935)],
  'Employment & Skill Development': <Color>[
    Color(0xFFFFB74D),
    Color(0xFFF57C00)
  ],
  'Financial Services': <Color>[Color(0xFF81D4FA), Color(0xFF0288D1)],
  'Agriculture & Rural Development': <Color>[
    Color(0xFFA5D6A7),
    Color(0xFF2E7D32)
  ],
  'Housing': <Color>[Color(0xFFFFCC80), Color(0xFFFB8C00)],
  'Social Security': <Color>[Color(0xFF90CAF9), Color(0xFF1E88E5)],
  'Business & MSME': <Color>[Color(0xFFCE93D8), Color(0xFF8E24AA)],
  'Specially Abled': <Color>[Color(0xFFFFE082), Color(0xFFFBC02D)],
};
