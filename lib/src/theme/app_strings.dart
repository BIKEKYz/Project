/// Simple localization strings for the app.
/// Usage: AppStrings.of(languageCode).myGarden
class AppStrings {
  final String languageCode;
  const AppStrings._(this.languageCode);

  static AppStrings of(String languageCode) =>
      AppStrings._(languageCode == 'en' ? 'en' : 'th');

  // ── Navigation ──────────────────────────────────────────────
  String get explore => languageCode == 'en' ? 'Explore' : 'สำรวจ';
  String get myGarden => languageCode == 'en' ? 'My Garden' : 'สวนของฉัน';

  // ── My Garden Screen ────────────────────────────────────────
  String get myGardenTitle =>
      languageCode == 'en' ? 'My Garden 🌿' : 'สวนของฉัน 🌿';
  String get gardenEmpty =>
      languageCode == 'en' ? 'Your garden is empty' : 'สวนของคุณยังว่างอยู่';
  String get gardenEmptySub => languageCode == 'en'
      ? 'Add plants from Explore tab'
      : 'เพิ่มต้นไม้จากแท็บสำรวจ';
  String get waterNow => languageCode == 'en' ? 'Water now!' : 'รดน้ำด่วน!';
  String inDays(int d) => languageCode == 'en' ? 'In $d days' : 'อีก $d วัน';

  // ── Settings ────────────────────────────────────────────────
  String get settings => languageCode == 'en' ? 'Settings' : 'ตั้งค่า';
  String get darkMode => languageCode == 'en' ? 'Dark Mode' : 'โหมดมืด';
  String get darkModeOn => languageCode == 'en' ? 'Enabled' : 'เปิดใช้งาน';
  String get darkModeOff => languageCode == 'en' ? 'Disabled' : 'ปิดใช้งาน';
  String get wateringSound =>
      languageCode == 'en' ? 'Watering Sound' : 'เสียงแจ้งเตือนรดน้ำ';
  String get selectSound =>
      languageCode == 'en' ? 'Select Watering Sound' : 'เลือกเสียงแจ้งเตือน';
  String get language => languageCode == 'en' ? 'Language' : 'ภาษา';
  String get selectLanguage =>
      languageCode == 'en' ? 'Select Language' : 'เลือกภาษา';
  String get notifications =>
      languageCode == 'en' ? 'Notifications' : 'การแจ้งเตือน';
  String get careSchedule =>
      languageCode == 'en' ? 'Care Schedule' : 'ตารางดูแล';
  String get careCalendar =>
      languageCode == 'en' ? 'Care Calendar' : 'ปฏิทินดูแล';

  // ── Home / Explore ──────────────────────────────────────────
  String welcomeUser(String name) =>
      languageCode == 'en' ? 'Welcome, $name 🌿' : 'สวัสดี, $name 🌿';
  String get searchPlants =>
      languageCode == 'en' ? 'Search plants...' : 'ค้นหาต้นไม้...';
  String get featuredPlants =>
      languageCode == 'en' ? 'Featured Plants' : 'ต้นไม้แนะนำ';
  String get allPlants => languageCode == 'en' ? 'All Plants' : 'ต้นไม้ทั้งหมด';
  String get noPlantsFound =>
      languageCode == 'en' ? 'No plants found' : 'ไม่พบต้นไม้';
  String get profile => languageCode == 'en' ? 'Profile' : 'โปรไฟล์';
  String get logout => languageCode == 'en' ? 'Logout' : 'ออกจากระบบ';
  String get filterPlants =>
      languageCode == 'en' ? 'Filter Plants' : 'กรองต้นไม้';
  String get reset => languageCode == 'en' ? 'Reset' : 'รีเซ็ต';
  String get showResults =>
      languageCode == 'en' ? 'Show Results' : 'แสดงผลลัพธ์';
  String get petSafeOnly =>
      languageCode == 'en' ? 'Pet Safe Only 🐾' : 'ปลอดภัยสำหรับสัตว์เลี้ยง 🐾';
  String get airPurifyingOnly =>
      languageCode == 'en' ? 'Air Purifying Only 🍃' : 'ฟอกอากาศเท่านั้น 🍃';

  // ── Light Advisor ────────────────────────────────────────────
  String get lightAdvisor => languageCode == 'en' ? 'Light' : 'แสง';
  String get lightAdvisorTitle =>
      languageCode == 'en' ? 'Room Light Advisor 🌤' : 'ประเมินแสงในห้อง 🌤';
  String get lightAdvisorSub => languageCode == 'en'
      ? 'Find the best spot for your plants'
      : 'หาตำแหน่งที่ดีที่สุดสำหรับต้นไม้ของคุณ';
}
