// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get commonTryAgain => 'حاول مرة أخرى';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonBack => 'رجوع';

  @override
  String get commonMore => 'المزيد';

  @override
  String get commonSend => 'إرسال';

  @override
  String get loginWelcomeBack => 'أهلاً بعودتك';

  @override
  String get loginSignInToContinue => 'سجّل الدخول للمتابعة';

  @override
  String get loginUsername => 'اسم المستخدم';

  @override
  String get loginEnterUsername => 'أدخل اسم المستخدم';

  @override
  String get loginPassword => 'كلمة المرور';

  @override
  String get loginEnterPassword => 'أدخل كلمة المرور';

  @override
  String get loginSignIn => 'تسجيل الدخول';

  @override
  String get loginFooter => 'Cloud Data Solutions · للاستخدام الداخلي فقط';

  @override
  String get dashboardGoodMorning => 'صباح الخير';

  @override
  String get dashboardGoodAfternoon => 'مساء الخير';

  @override
  String get dashboardGoodEvening => 'مساء الخير';

  @override
  String get dashboardWelcome => 'أهلاً';

  @override
  String get dashboardHello => 'مرحباً';

  @override
  String get dashboardOverview => 'نظرة عامة';

  @override
  String get dashboardThisMonth => 'هذا الشهر';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navTasks => 'المهام';

  @override
  String get dashboardAttendance => 'الحضور';

  @override
  String get dashboardLeaveRequests => 'طلبات الإجازة';

  @override
  String get dashboardOpenTasks => 'مهام مفتوحة';

  @override
  String get dashboardQuickActions => 'إجراءات سريعة';

  @override
  String get dashboardDailyExpenses => 'المصاريف اليومية';

  @override
  String get dashboardDailyExpensesSub => 'سجّل الكيلومترات والعملاء والمجاميع';

  @override
  String get dashboardLeaveRequest => 'طلب إجازة';

  @override
  String get dashboardLeaveRequestSub => 'مغادرة أو إجازة';

  @override
  String get dashboardRecentActivity => 'النشاط الأخير';

  @override
  String get dashboardViewAll => 'عرض الكل';

  @override
  String get dashboardNoActivity => 'لا يوجد نشاط هذا الشهر بعد.';

  @override
  String get dashboardCheckedIn => 'تم تسجيل الدخول';

  @override
  String get dashboardTripSubmitted => 'تم إرسال الرحلة';

  @override
  String get dashboardWorkHoursToday => 'ساعات العمل اليوم';

  @override
  String get dashboardEmployeesPunched => 'بصموا اليوم';

  @override
  String get dashboardCouldNotLoad => 'تعذّر تحميل لوحة التحكم';

  @override
  String get dashboardManagerEyebrow => 'نظرة على الفريق';

  @override
  String get dashboardEmployeeEyebrow => 'نظرة على عملك';

  @override
  String get dashboardManagerSubtitle => 'هاي نظرة على أداء فريقك اليوم.';

  @override
  String get dashboardEmployeeSubtitle => 'هاي ملخص يومك.';

  @override
  String get dashboardDailySummary => 'ملخص الأداء اليومي';

  @override
  String dashboardLastUpdated(String time) {
    return 'آخر تحديث $time';
  }

  @override
  String get dashboardTasksThisMonth => 'مهام هذا الشهر';

  @override
  String dashboardDoneCount(int count) {
    return '$count منجزة';
  }

  @override
  String get dashboardFinishedThisMonth => 'منجزة هذا الشهر';

  @override
  String dashboardOpenedThisMonth(int count) {
    return '$count فُتحت هذا الشهر';
  }

  @override
  String dashboardOverdueCount(int count) {
    return '$count متأخرة';
  }

  @override
  String get dashboardNoPunchToday => 'لا توجد بصمة اليوم';

  @override
  String get dashboardAttendanceToday => 'الحضور اليوم';

  @override
  String dashboardOfTeam(int percent) {
    return '$percent% من الفريق';
  }

  @override
  String get dashboardCompletionRate => 'نسبة إنجاز مهام الشهر';

  @override
  String get dashboardPendingApprovals => 'طلبات بانتظار موافقتك';

  @override
  String get dashboardTeamToday => 'الفريق اليوم';

  @override
  String dashboardOnLeaveAbsent(int onLeave, int absent) {
    return '$onLeave إجازة · $absent لم يبصم';
  }

  @override
  String get dashboardUpcomingTasks => 'المهام القادمة';

  @override
  String get dashboardPresent => 'حاضر';

  @override
  String get dashboardNotPunched => 'لم يبصم';

  @override
  String get dashboardOnLeave => 'إجازة';

  @override
  String get dashboardTeamLabel => 'الفريق';

  @override
  String get checkInAttendance => 'الحضور';

  @override
  String get checkInLive => 'مباشر';

  @override
  String get checkInVerifying => 'جارٍ التحقق…';

  @override
  String get checkInTapToPunch => 'اضغط للبصم';

  @override
  String get checkInNoPunchToday => 'لم تسجل بصمة اليوم';

  @override
  String get checkInIn => 'دخول';

  @override
  String get checkInOut => 'خروج';

  @override
  String checkInDurationHoursMinutes(int hours, int minutes) {
    return '$hoursس $minutesد';
  }

  @override
  String checkInDurationMinutes(int minutes) {
    return '$minutesد';
  }

  @override
  String checkInElapsedSince(String duration, String time) {
    return '$duration · منذ $time';
  }

  @override
  String checkInPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بصمة بانتظار الاتصال — سترسل تلقائياً',
      many: '$count بصمة بانتظار الاتصال — سترسل تلقائياً',
      few: '$count بصمات بانتظار الاتصال — سترسل تلقائياً',
      two: 'بصمتان بانتظار الاتصال — سترسلان تلقائياً',
      one: 'بصمة واحدة بانتظار الاتصال — سترسل تلقائياً',
    );
    return '$_temp0';
  }

  @override
  String get checkInInsideGeofence => 'داخل النطاق الجغرافي';

  @override
  String checkInInsideSite(String siteName) {
    return 'داخل · $siteName';
  }

  @override
  String get checkInFingerprintRequired => 'مطلوب بصمة';

  @override
  String get checkInSomethingWrong => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get appOutsideWorkSite => 'أنت خارج موقع العمل';

  @override
  String get appOutsideWorkSiteBlocked =>
      'أنت خارج موقع العمل — ما بتقدر تسجل البصمة من هون.';

  @override
  String get appNoConnectionPunchQueued =>
      'لا يوجد اتصال — تم حفظ البصمة وسترسل تلقائياً';

  @override
  String get appNoFingerprintEnrolled => 'لا توجد بصمة مسجلة على هذا الجهاز.';

  @override
  String get appConfirmFingerprintReason => 'أكّد بصمتك للتسجيل';

  @override
  String get appFingerprintNotRecognised =>
      'لم يتم التعرّف على البصمة. حاول مرة أخرى.';

  @override
  String appCheckedIn(String time) {
    return 'تم تسجيل الدخول$time';
  }

  @override
  String appCheckedOut(String time) {
    return 'تم تسجيل الخروج$time';
  }

  @override
  String get statusNotPunched => 'لم يسجل';

  @override
  String get statusIn => 'داخل';

  @override
  String statusInSince(String time) {
    return 'داخل منذ $time';
  }

  @override
  String statusInOut(String start, String end) {
    return 'دخول $start — خروج $end';
  }

  @override
  String statusInAt(String time) {
    return 'دخول $time';
  }

  @override
  String get attendanceScreenTitle => 'سجل الحضور';

  @override
  String get attendanceDailyLog => 'السجل اليومي';

  @override
  String attendanceEntriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سجل',
      many: 'سجلاً',
      few: 'سجلات',
      two: 'سجلان',
      one: 'سجل',
    );
    return '$count $_temp0';
  }

  @override
  String get attendanceCouldNotLoad => 'تعذّر تحميل الحضور';

  @override
  String get attendanceNoRecords => 'لا توجد سجلات حضور';

  @override
  String get attendanceNoRecordsMsg => 'لا يوجد شيء مسجل للتواريخ المحددة.';

  @override
  String get attendanceStart => 'دخول';

  @override
  String get attendanceEnd => 'خروج';

  @override
  String get attendanceLate => 'متأخر';

  @override
  String get attendanceByDevice => 'بصمة الجهاز';

  @override
  String get attendanceByMobile => 'بصمة الموبايل';

  @override
  String get attendanceDaysWorked => 'أيام الدوام';

  @override
  String get attendanceOnTime => 'بالوقت';

  @override
  String get attendanceAvgHours => 'معدل الساعات';

  @override
  String get attendanceInProgress => 'قيد الدوام';

  @override
  String get attendanceNoCheckout => 'بدون خروج';

  @override
  String get attendanceSummary => 'الملخص';

  @override
  String get rangeTitle => 'اختر الفترة';

  @override
  String get rangePeriod => 'الفترة';

  @override
  String get rangeToday => 'اليوم';

  @override
  String get rangeThisWeek => 'هذا الأسبوع';

  @override
  String get rangeLast7 => 'آخر 7 أيام';

  @override
  String get rangeThisMonth => 'هذا الشهر';

  @override
  String get rangeLastMonth => 'الشهر الماضي';

  @override
  String get rangeLast30 => 'آخر 30 يوم';

  @override
  String get rangeFrom => 'من';

  @override
  String get rangeTo => 'إلى';

  @override
  String get rangeApply => 'تطبيق';

  @override
  String rangeDays(int count) {
    return '$count يوم';
  }

  @override
  String get tasksTitle => 'مهامي';

  @override
  String get tasksProjects => 'المشاريع';

  @override
  String get tasksCouldNotLoad => 'تعذّر تحميل المهام';

  @override
  String get tasksNoneAssigned => 'لا توجد مهام مسندة';

  @override
  String get tasksNoneAssignedMsg => 'ستظهر هنا المهام الجديدة المسندة إليك.';

  @override
  String get tasksNoneAssignedMemberMsg =>
      'لا يوجد شيء مسند لهذا الشخص حالياً.';

  @override
  String get tasksThisWeek => 'هذا الأسبوع';

  @override
  String get tasksKeepMomentum => 'واصل التقدم';

  @override
  String tasksDoneOfTotal(int total) {
    return '/ $total مكتملة';
  }

  @override
  String tasksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مهمة',
      many: 'مهمة',
      few: 'مهام',
      two: 'مهمتان',
      one: 'مهمة',
    );
    return '$count $_temp0';
  }

  @override
  String get tasksClient => 'العميل';

  @override
  String get tasksDescription => 'الوصف';

  @override
  String get tasksAttachments => 'المرفقات';

  @override
  String get tasksCouldNotLoadAttachments => 'تعذّر تحميل المرفقات.';

  @override
  String get tasksCouldNotOpenAttachment => 'تعذّر فتح الملف.';

  @override
  String get tasksMarkDone => 'تم الإنجاز ✓';

  @override
  String get tasksDelete => 'حذف';

  @override
  String get tasksDeleteConfirmTitle => 'حذف هذه المهمة؟';

  @override
  String get tasksDeleteConfirmMsg => 'سيتم حذف المهمة ومرفقاتها نهائياً.';

  @override
  String tasksCreatedBy(String name) {
    return 'أنشأها: $name';
  }

  @override
  String get tasksFinishedTitle => 'منجزة هذا الشهر';

  @override
  String get tasksFinishedEmpty => 'لا توجد مهام منجزة هذا الشهر';

  @override
  String get tasksFinishedEmptyMsg => 'المهام التي تنجزها هذا الشهر ستظهر هنا.';

  @override
  String get tasksRemind => 'تذكير';

  @override
  String tasksReminderSent(String names) {
    return 'تم إرسال التذكير إلى $names';
  }

  @override
  String get commonAnd => ' و ';

  @override
  String get chatTitle => 'المحادثة';

  @override
  String chatWith(String name) {
    return 'مع $name';
  }

  @override
  String get chatEmpty => 'لا توجد رسائل بعد';

  @override
  String get chatEmptyMsg => 'ابدأ المحادثة برسالة.';

  @override
  String get chatCouldNotLoad => 'تعذّر تحميل المحادثة';

  @override
  String get chatLocked => 'هذه المحادثة مقفلة.';

  @override
  String chatLocksAt(String time) {
    return 'تُقفل في $time';
  }

  @override
  String get chatTypeMessage => 'اكتب رسالة…';

  @override
  String get chatAttach => 'إرفاق ملفات';

  @override
  String get chatRecordVoice => 'تسجيل رسالة صوتية';

  @override
  String get chatStopRecording => 'إيقاف التسجيل';

  @override
  String chatRecording(String time) {
    return 'جارِ التسجيل… $time';
  }

  @override
  String get chatVoiceMessage => '🎤 رسالة صوتية';

  @override
  String get chatPhoto => '📷 صورة';

  @override
  String get chatVideo => '🎬 فيديو';

  @override
  String get chatCouldNotSend => 'تعذّر إرسال الرسالة.';

  @override
  String get chatCouldNotRecord => 'تعذّر بدء التسجيل.';

  @override
  String get chatMicPermissionDenied =>
      'يلزم إذن الميكروفون لتسجيل رسالة صوتية.';

  @override
  String get chatRemoveFile => 'إزالة';

  @override
  String get chatYesterday => 'أمس';

  @override
  String get chatCopied => 'تم نسخ الرسالة';

  @override
  String get projectsTitle => 'المشاريع';

  @override
  String get projectsCouldNotLoad => 'تعذّر تحميل المشاريع';

  @override
  String get projectsEmpty => 'لا توجد مشاريع بعد';

  @override
  String get projectsDone => 'منجزة';

  @override
  String get projectsWorking => 'قيد العمل';

  @override
  String get projectsOpen => 'مفتوحة';

  @override
  String get projectsOverdue => 'متأخرة';

  @override
  String projectsDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم متبقي',
      two: 'يومان متبقيان',
      one: 'يوم واحد متبقي',
      zero: 'اليوم',
    );
    return '$_temp0';
  }

  @override
  String get projectsNoSprint => 'بدون سبرنت';

  @override
  String get projectsSprintEmpty => 'لا توجد مهام بهذا السبرنت';

  @override
  String get calendarTitle => 'التقويم';

  @override
  String get calendarTeamTasks => 'مهام الفريق';

  @override
  String get calendarNothingThisDay => 'لا يوجد شيء بهذا اليوم';

  @override
  String get calendarAllDay => 'اليوم كامل';

  @override
  String get calendarPending => 'قيد الانتظار';

  @override
  String get calendarCouldNotSave => 'تعذّر حفظ الحدث.';

  @override
  String get calendarNewEvent => 'حدث جديد';

  @override
  String get calendarEventTitle => 'الحدث';

  @override
  String get calendarEventName => 'العنوان';

  @override
  String get calendarStart => 'البداية';

  @override
  String get calendarEnd => 'النهاية';

  @override
  String get calendarPlace => 'المكان';

  @override
  String get calendarNotes => 'ملاحظات';

  @override
  String get calendarPeople => 'الأشخاص';

  @override
  String get calendarSave => 'حفظ الحدث';

  @override
  String get calendarTitleRequired => 'أدخل عنواناً للحدث';

  @override
  String get calendarEndBeforeStart => 'يجب أن يكون الانتهاء بعد البداية';

  @override
  String get calendarSearchPeople => 'ابحث عن شخص';

  @override
  String calendarSelectedCount(int count) {
    return '$count محدد';
  }

  @override
  String get calendarToday => 'اليوم';

  @override
  String get calendarEventSaved => 'تم حفظ الحدث';

  @override
  String get calendarDeleteTitle => 'حذف هذا الحدث؟';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsClearAllTitle => 'مسح كل الإشعارات؟';

  @override
  String get notificationsClearAll => 'مسح الكل';

  @override
  String get notificationsUpdates => 'التحديثات';

  @override
  String get notificationsCouldNotLoad => 'تعذّر تحميل الإشعارات';

  @override
  String get notificationsNothingNew => 'لا جديد';

  @override
  String get notificationsNothingNewMsg => 'ستظهر هنا الإعلانات والتحديثات.';

  @override
  String get notificationsCouldNotDismiss => 'تعذّر إخفاء الإشعار.';

  @override
  String get notificationsCouldNotClear => 'تعذّر مسح الإشعارات.';

  @override
  String get notificationsReadAll => 'تعليم الكل كمقروء';

  @override
  String get notificationsCouldNotMarkRead => 'تعذّر تعليم الإشعارات كمقروءة.';

  @override
  String get transportationTitle => 'المصاريف اليومية';

  @override
  String get transportationEntrySaved => 'تم حفظ السجل.';

  @override
  String get transportationOpenReport => 'فتح التقرير';

  @override
  String get transportationOpenReportPdf => 'فتح التقرير (PDF)';

  @override
  String get transportationCouldNotGenerateReport => 'تعذّر إنشاء التقرير.';

  @override
  String get transportationDeleteTitle => 'حذف هذا السجل؟';

  @override
  String get transportationDelete => 'حذف';

  @override
  String get transportationEntryDeleted => 'تم حذف السجل.';

  @override
  String get transportationCouldNotDelete => 'تعذّر حذف السجل.';

  @override
  String get transportationEntriesLabel => 'السجلات';

  @override
  String get transportationTotal => 'الإجمالي';

  @override
  String get transportationDistance => 'المسافة';

  @override
  String get transportationEntriesMetric => 'السجلات';

  @override
  String get transportationCouldNotLoadEntries => 'تعذّر تحميل السجلات';

  @override
  String get transportationNoEntries => 'لا توجد سجلات بعد';

  @override
  String get transportationNoEntriesMsg =>
      'اضغط + لتسجيل رحلة بالكيلومترات والعملاء والمجموع.';

  @override
  String get transportationNoEntriesMember => 'لا توجد سجلات';

  @override
  String get transportationNoTripsMemberMsg =>
      'لم تُسجَّل أي رحلات في التواريخ المحددة.';

  @override
  String get transportationDeleteEntryTooltip => 'حذف السجل';

  @override
  String get transportationReportTitle => 'التقرير';

  @override
  String get editorEditEntry => 'تعديل السجل';

  @override
  String get editorNewEntry => 'سجل جديد';

  @override
  String get editorTransactionLabel => 'المعاملة';

  @override
  String get editorDate => 'التاريخ';

  @override
  String get editorKm => 'كم';

  @override
  String get editorTotal => 'الإجمالي';

  @override
  String get editorNotes => 'ملاحظات';

  @override
  String get editorClientsLabel => 'العملاء';

  @override
  String get editorAddClient => 'إضافة عميل';

  @override
  String get editorNoClients => 'لا يوجد عملاء مرفقون بهذه الرحلة بعد.';

  @override
  String get editorSaving => 'جارٍ الحفظ…';

  @override
  String get editorSaveEntry => 'حفظ السجل';

  @override
  String get editorCouldNotSave => 'تعذّر حفظ السجل.';

  @override
  String get editorRequired => 'مطلوب';

  @override
  String get editorEnterNumber => 'أدخل رقماً';

  @override
  String get editorAddClientTitle => 'إضافة عميل';

  @override
  String get editorSearchClients => 'ابحث عن عملاء';

  @override
  String get editorNoClientsAvailable => 'لا يوجد عملاء متاحون';

  @override
  String get editorNoMatches => 'لا توجد نتائج';

  @override
  String get editorClientListFailed => 'تعذّر تحميل قائمة العملاء.';

  @override
  String get editorTryDifferentSearch => 'جرّب كلمة بحث مختلفة.';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get profileSignOutTitle => 'تسجيل الخروج؟';

  @override
  String get profileSignOutMsg =>
      'ستحتاج اسم المستخدم وكلمة المرور لتسجيل الدخول مجدداً.';

  @override
  String get profileSignOut => 'تسجيل الخروج';

  @override
  String get profileWorkspace => 'مساحة العمل';

  @override
  String get profileTeamRequestsSub => 'وافق أو ارفض طلبات فريقك';

  @override
  String get profileAccount => 'الحساب';

  @override
  String get profileUserId => 'معرّف المستخدم';

  @override
  String get profileServer => 'الخادم';

  @override
  String get profileSignOutSub => 'إنهاء هذه الجلسة على هذا الجهاز';

  @override
  String get profileLanguage => 'اللغة';

  @override
  String get profileLanguageSub => 'بدّل لغة التطبيق بين الإنجليزية والعربية';

  @override
  String get memberViewOnly => 'عرض فقط';

  @override
  String get memberTabAttendance => 'الحضور';

  @override
  String get memberTabLeaves => 'الإجازات';

  @override
  String get memberTabTasks => 'المهام';

  @override
  String get memberTabTransportation => 'المواصلات';

  @override
  String get memberToday => 'اليوم';

  @override
  String get memberCouldNotLoadLeaveRequests => 'تعذّر تحميل طلبات الإجازة';

  @override
  String get memberNoLeaveRequests => 'لا توجد طلبات إجازة';

  @override
  String get requestsInRangeMsg => 'ستظهر هنا الطلبات ضمن التواريخ المحددة.';

  @override
  String get teamTitle => 'فريقي';

  @override
  String get teamCouldNotLoadBoard => 'تعذّر تحميل لوحة الفريق';

  @override
  String get teamNoMembers => 'لا يوجد أعضاء بالفريق';

  @override
  String get teamNoMembersMsg => 'سيظهر هنا كل من يرفع تقاريره إليك.';

  @override
  String get teamLeaveTitle => 'طلبات الفريق';

  @override
  String get teamLeaveApproveTitle => 'الموافقة على الطلب؟';

  @override
  String get teamLeaveApprove => 'موافقة';

  @override
  String get teamLeaveApproved => 'تمت الموافقة على الطلب';

  @override
  String get teamLeaveRejected => 'تم رفض الطلب';

  @override
  String get teamLeaveForbidden => 'لا تملك صلاحية على هذا الطلب';

  @override
  String get teamLeaveAlreadyDecided => 'تم اتخاذ قرار بهذا الطلب مسبقاً';

  @override
  String get teamLeaveNotFound => 'الطلب لم يعد موجوداً';

  @override
  String get teamLeaveFailed => 'تعذّر تنفيذ العملية';

  @override
  String get teamLeaveRequestsLabel => 'الطلبات';

  @override
  String get teamLeaveAllDates => 'كل التواريخ';

  @override
  String get teamLeaveAllEmployees => 'كل الموظفين';

  @override
  String get teamLeaveNoRequests => 'لا توجد طلبات';

  @override
  String get teamLeaveMatchingMsg => 'ستظهر هنا الطلبات المطابقة لهذه الفلاتر.';

  @override
  String get teamLeaveCouldNotLoad => 'تعذّر تحميل طلبات الفريق';

  @override
  String rejectionReason(String reason) {
    return 'سبب الرفض: $reason';
  }

  @override
  String get teamLeaveReject => 'رفض';

  @override
  String get teamLeaveWaitingDirectManager => 'بانتظار قرار المدير المباشر';

  @override
  String get teamLeaveRejectDialogTitle => 'رفض الطلب';

  @override
  String get teamLeaveRejectionHint => 'سبب الرفض';

  @override
  String get teamLeaveReasonRequired => 'السبب مطلوب';

  @override
  String get filterAll => 'الكل';

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusApproved => 'موافق عليه';

  @override
  String get statusRejected => 'مرفوض';

  @override
  String get leaveKindLeaving => 'مغادرة';

  @override
  String get leaveKindVacation => 'إجازة';

  @override
  String get leaveTitle => 'الإجازات والمغادرات';

  @override
  String get leaveTakePhoto => 'التقاط صورة';

  @override
  String get leaveChooseFromGallery => 'اختيار من المعرض';

  @override
  String get leaveMedicalReportAttached => 'تم إرفاق التقرير الطبي.';

  @override
  String get leaveCouldNotAttach => 'تعذّر إرفاق التقرير.';

  @override
  String get leaveRequestSentToManager => 'تم إرسال الطلب إلى مديرك';

  @override
  String get leaveAttachMedicalTitle => 'إرفاق التقرير الطبي؟';

  @override
  String get leaveAttachLaterMsg => 'يمكنك أيضاً إرفاقه لاحقاً من بطاقة الطلب.';

  @override
  String get leaveLater => 'لاحقاً';

  @override
  String get leaveAttachNow => 'إرفاق الآن';

  @override
  String get leaveCancelRequestTitle => 'إلغاء هذا الطلب؟';

  @override
  String get leaveKeep => 'إبقاء';

  @override
  String get leaveCancelRequest => 'إلغاء الطلب';

  @override
  String get leaveRequestCancelled => 'تم إلغاء الطلب.';

  @override
  String get leaveCouldNotCancel => 'تعذّر إلغاء الطلب.';

  @override
  String leaveKindRequests(String kind) {
    return 'طلبات $kind';
  }

  @override
  String get leaveNewRequest => 'طلب جديد';

  @override
  String get leaveCouldNotLoadRequests => 'تعذّر تحميل الطلبات';

  @override
  String leaveNoKindRequests(String kind) {
    return 'لا توجد طلبات $kind';
  }

  @override
  String get leaveNoVacationBalance => 'لا يوجد رصيد إجازات محدد لهذه السنة.';

  @override
  String leaveRemainingOf(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم متبقٍ من',
      many: '$count يوماً متبقياً من',
      few: '$count أيام متبقية من',
      two: 'يومان متبقيان من',
      one: 'يوم واحد متبقٍ من',
    );
    return '$_temp0';
  }

  @override
  String get leaveAttachMedicalReportTooltip => 'إرفاق تقرير طبي';

  @override
  String get leaveAttachmentsTitle => 'المرفقات';

  @override
  String get leaveCouldNotLoadAttachments => 'تعذّر تحميل المرفقات.';

  @override
  String get leaveNoAttachments => 'لا توجد مرفقات بعد.';

  @override
  String get leaveViewMedicalReport => 'عرض التقرير الطبي';

  @override
  String durationHours(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ساعة',
      many: '$count ساعة',
      few: '$count ساعات',
      two: 'ساعتان',
      one: 'ساعة واحدة',
    );
    return '$_temp0';
  }

  @override
  String durationDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يوماً',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String leaveApprovedBy(String name) {
    return 'تمت الموافقة من قبل $name';
  }

  @override
  String get leaveDetailTitle => 'تفاصيل الطلب';

  @override
  String get leaveDetailCouldNotLoad => 'تعذّر تحميل الطلب';

  @override
  String leavePendingWith(String name) {
    return 'بانتظار: $name';
  }

  @override
  String get leaveStepsTitle => 'سجل الطلب';

  @override
  String leaveStepSubmitted(String name) {
    return '$name قدّم الطلب';
  }

  @override
  String leaveStepForwarded(String from, String to) {
    return '$from حوّلته إلى $to';
  }

  @override
  String leaveStepApproved(String name) {
    return '$name وافق على الطلب';
  }

  @override
  String leaveStepRejected(String name) {
    return '$name رفض الطلب';
  }

  @override
  String leaveForwardTo(String name) {
    return 'تحويل إلى $name';
  }

  @override
  String get leaveForwardNoteHint => 'ملاحظة اختيارية';

  @override
  String get leaveForwardButton => 'تحويل';

  @override
  String get leaveForwarded => 'تم تحويل الطلب.';

  @override
  String get leaveWithdraw => 'سحب الطلب';

  @override
  String get leaveWithdrawConfirmTitle => 'سحب هذا الطلب؟';

  @override
  String get leaveEditorChooseType => 'اختر نوعاً لهذا الطلب.';

  @override
  String get leaveEditorEndBeforeStart =>
      'لا يمكن أن يكون تاريخ الانتهاء قبل تاريخ البدء.';

  @override
  String get leaveEditorCouldNotSubmit => 'تعذّر إرسال الطلب.';

  @override
  String get leaveEditorFrom => 'من';

  @override
  String get leaveEditorTo => 'إلى';

  @override
  String get leaveEditorSubmitting => 'جارٍ الإرسال…';

  @override
  String get leaveEditorSubmitRequest => 'إرسال الطلب';

  @override
  String get leaveEditorConflictsTitle => 'زملاء في إجازة بنفس الفترة';

  @override
  String leaveEditorConflictLine(String name, String from, String to) {
    return '$name في إجازة بنفس الفترة ($from → $to)';
  }

  @override
  String get leaveEditorSubmitAnyway => 'إرسال على أي حال';

  @override
  String get leaveEditorType => 'النوع';

  @override
  String get leaveEditorNoTypesAvailable => 'لا توجد أنواع متاحة';

  @override
  String get leaveEditorChooseTypeValidator => 'اختر نوعاً';

  @override
  String get leaveWorkLeavingClientsLabel => 'رايح عند أي عميل؟';

  @override
  String get leaveChooseClientRequired => 'اختر العميل اللي رايح عنده';
}
