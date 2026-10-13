import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// No description provided for @commonSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get commonSend;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'WELCOME BACK'**
  String get loginWelcomeBack;

  /// No description provided for @loginSignInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSignInToContinue;

  /// No description provided for @loginUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get loginUsername;

  /// No description provided for @loginEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get loginEnterUsername;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get loginEnterPassword;

  /// No description provided for @loginSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSignIn;

  /// No description provided for @loginFooter.
  ///
  /// In en, this message translates to:
  /// **'Cloud Data Solutions · Internal use only'**
  String get loginFooter;

  /// No description provided for @dashboardGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get dashboardGoodMorning;

  /// No description provided for @dashboardGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get dashboardGoodAfternoon;

  /// No description provided for @dashboardGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get dashboardGoodEvening;

  /// No description provided for @dashboardWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get dashboardWelcome;

  /// No description provided for @dashboardHello.
  ///
  /// In en, this message translates to:
  /// **'hello'**
  String get dashboardHello;

  /// No description provided for @dashboardOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get dashboardOverview;

  /// No description provided for @dashboardThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get dashboardThisMonth;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @dashboardAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get dashboardAttendance;

  /// No description provided for @dashboardLeaveRequests.
  ///
  /// In en, this message translates to:
  /// **'Leave requests'**
  String get dashboardLeaveRequests;

  /// No description provided for @dashboardOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'Open tasks'**
  String get dashboardOpenTasks;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardDailyExpenses.
  ///
  /// In en, this message translates to:
  /// **'Daily expenses'**
  String get dashboardDailyExpenses;

  /// No description provided for @dashboardDailyExpensesSub.
  ///
  /// In en, this message translates to:
  /// **'Log KM, clients & totals'**
  String get dashboardDailyExpensesSub;

  /// No description provided for @dashboardLeaveRequest.
  ///
  /// In en, this message translates to:
  /// **'Leave request'**
  String get dashboardLeaveRequest;

  /// No description provided for @dashboardLeaveRequestSub.
  ///
  /// In en, this message translates to:
  /// **'Leaving or vacation'**
  String get dashboardLeaveRequestSub;

  /// No description provided for @dashboardRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get dashboardRecentActivity;

  /// No description provided for @dashboardViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get dashboardViewAll;

  /// No description provided for @dashboardNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity yet this month.'**
  String get dashboardNoActivity;

  /// No description provided for @dashboardCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get dashboardCheckedIn;

  /// No description provided for @dashboardTripSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Trip submitted'**
  String get dashboardTripSubmitted;

  /// No description provided for @dashboardWorkHoursToday.
  ///
  /// In en, this message translates to:
  /// **'Work hours today'**
  String get dashboardWorkHoursToday;

  /// No description provided for @dashboardEmployeesPunched.
  ///
  /// In en, this message translates to:
  /// **'Punched in today'**
  String get dashboardEmployeesPunched;

  /// No description provided for @dashboardCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load the dashboard'**
  String get dashboardCouldNotLoad;

  /// No description provided for @dashboardManagerEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Your team at a glance'**
  String get dashboardManagerEyebrow;

  /// No description provided for @dashboardEmployeeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Your work at a glance'**
  String get dashboardEmployeeEyebrow;

  /// No description provided for @dashboardManagerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s how your team is doing today.'**
  String get dashboardManagerSubtitle;

  /// No description provided for @dashboardEmployeeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s a summary of your day.'**
  String get dashboardEmployeeSubtitle;

  /// No description provided for @dashboardDailySummary.
  ///
  /// In en, this message translates to:
  /// **'Daily performance summary'**
  String get dashboardDailySummary;

  /// No description provided for @dashboardLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String dashboardLastUpdated(String time);

  /// No description provided for @dashboardTasksThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Tasks this month'**
  String get dashboardTasksThisMonth;

  /// No description provided for @dashboardDoneCount.
  ///
  /// In en, this message translates to:
  /// **'{count} done'**
  String dashboardDoneCount(int count);

  /// No description provided for @dashboardFinishedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Finished this month'**
  String get dashboardFinishedThisMonth;

  /// No description provided for @dashboardOpenedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'{count} opened this month'**
  String dashboardOpenedThisMonth(int count);

  /// No description provided for @dashboardOverdueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} overdue'**
  String dashboardOverdueCount(int count);

  /// No description provided for @dashboardNoPunchToday.
  ///
  /// In en, this message translates to:
  /// **'No punch recorded today'**
  String get dashboardNoPunchToday;

  /// No description provided for @dashboardAttendanceToday.
  ///
  /// In en, this message translates to:
  /// **'Attendance today'**
  String get dashboardAttendanceToday;

  /// No description provided for @dashboardOfTeam.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the team'**
  String dashboardOfTeam(int percent);

  /// No description provided for @dashboardCompletionRate.
  ///
  /// In en, this message translates to:
  /// **'Monthly task completion'**
  String get dashboardCompletionRate;

  /// No description provided for @dashboardPendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'Awaiting your approval'**
  String get dashboardPendingApprovals;

  /// No description provided for @dashboardTeamToday.
  ///
  /// In en, this message translates to:
  /// **'Team today'**
  String get dashboardTeamToday;

  /// No description provided for @dashboardOnLeaveAbsent.
  ///
  /// In en, this message translates to:
  /// **'{onLeave} on leave · {absent} not punched'**
  String dashboardOnLeaveAbsent(int onLeave, int absent);

  /// No description provided for @dashboardUpcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'Upcoming tasks'**
  String get dashboardUpcomingTasks;

  /// No description provided for @dashboardPresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get dashboardPresent;

  /// No description provided for @dashboardNotPunched.
  ///
  /// In en, this message translates to:
  /// **'Not punched'**
  String get dashboardNotPunched;

  /// No description provided for @dashboardOnLeave.
  ///
  /// In en, this message translates to:
  /// **'On leave'**
  String get dashboardOnLeave;

  /// No description provided for @dashboardTeamLabel.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get dashboardTeamLabel;

  /// No description provided for @checkInAttendance.
  ///
  /// In en, this message translates to:
  /// **'ATTENDANCE'**
  String get checkInAttendance;

  /// No description provided for @checkInLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get checkInLive;

  /// No description provided for @checkInVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get checkInVerifying;

  /// No description provided for @checkInTapToPunch.
  ///
  /// In en, this message translates to:
  /// **'Tap to punch'**
  String get checkInTapToPunch;

  /// No description provided for @checkInNoPunchToday.
  ///
  /// In en, this message translates to:
  /// **'No punch recorded today'**
  String get checkInNoPunchToday;

  /// No description provided for @checkInIn.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get checkInIn;

  /// No description provided for @checkInOut.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get checkInOut;

  /// No description provided for @checkInDurationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String checkInDurationHoursMinutes(int hours, int minutes);

  /// No description provided for @checkInDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String checkInDurationMinutes(int minutes);

  /// No description provided for @checkInElapsedSince.
  ///
  /// In en, this message translates to:
  /// **'{duration} · since {time}'**
  String checkInElapsedSince(String duration, String time);

  /// No description provided for @checkInPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{One punch waiting for a connection — it will send automatically} other{{count} punches waiting for a connection — they will send automatically}}'**
  String checkInPending(int count);

  /// No description provided for @checkInInsideGeofence.
  ///
  /// In en, this message translates to:
  /// **'Inside geofence'**
  String get checkInInsideGeofence;

  /// No description provided for @checkInInsideSite.
  ///
  /// In en, this message translates to:
  /// **'Inside · {siteName}'**
  String checkInInsideSite(String siteName);

  /// No description provided for @checkInFingerprintRequired.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint required'**
  String get checkInFingerprintRequired;

  /// No description provided for @checkInSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get checkInSomethingWrong;

  /// No description provided for @appOutsideWorkSite.
  ///
  /// In en, this message translates to:
  /// **'You are outside the work site'**
  String get appOutsideWorkSite;

  /// No description provided for @appOutsideWorkSiteBlocked.
  ///
  /// In en, this message translates to:
  /// **'You\'re outside the work site — the punch can\'t be recorded from here.'**
  String get appOutsideWorkSiteBlocked;

  /// No description provided for @appNoConnectionPunchQueued.
  ///
  /// In en, this message translates to:
  /// **'No connection — the punch was saved and will send automatically'**
  String get appNoConnectionPunchQueued;

  /// No description provided for @appNoFingerprintEnrolled.
  ///
  /// In en, this message translates to:
  /// **'No fingerprint is enrolled on this device.'**
  String get appNoFingerprintEnrolled;

  /// No description provided for @appConfirmFingerprintReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm your fingerprint to punch'**
  String get appConfirmFingerprintReason;

  /// No description provided for @appFingerprintNotRecognised.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint not recognised. Try again.'**
  String get appFingerprintNotRecognised;

  /// No description provided for @appCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in{time}'**
  String appCheckedIn(String time);

  /// No description provided for @appCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'Checked out{time}'**
  String appCheckedOut(String time);

  /// No description provided for @statusNotPunched.
  ///
  /// In en, this message translates to:
  /// **'Not punched'**
  String get statusNotPunched;

  /// No description provided for @statusIn.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get statusIn;

  /// No description provided for @statusInSince.
  ///
  /// In en, this message translates to:
  /// **'In since {time}'**
  String statusInSince(String time);

  /// No description provided for @statusInOut.
  ///
  /// In en, this message translates to:
  /// **'In {start} — Out {end}'**
  String statusInOut(String start, String end);

  /// No description provided for @statusInAt.
  ///
  /// In en, this message translates to:
  /// **'In {time}'**
  String statusInAt(String time);

  /// No description provided for @attendanceScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance history'**
  String get attendanceScreenTitle;

  /// No description provided for @attendanceDailyLog.
  ///
  /// In en, this message translates to:
  /// **'Daily log'**
  String get attendanceDailyLog;

  /// No description provided for @attendanceEntriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, one{entry} other{entries}}'**
  String attendanceEntriesCount(int count);

  /// No description provided for @attendanceCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load attendance'**
  String get attendanceCouldNotLoad;

  /// No description provided for @attendanceNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No attendance records'**
  String get attendanceNoRecords;

  /// No description provided for @attendanceNoRecordsMsg.
  ///
  /// In en, this message translates to:
  /// **'There is nothing logged for the selected dates.'**
  String get attendanceNoRecordsMsg;

  /// No description provided for @attendanceStart.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get attendanceStart;

  /// No description provided for @attendanceEnd.
  ///
  /// In en, this message translates to:
  /// **'END'**
  String get attendanceEnd;

  /// No description provided for @attendanceLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get attendanceLate;

  /// No description provided for @attendanceByDevice.
  ///
  /// In en, this message translates to:
  /// **'By Device'**
  String get attendanceByDevice;

  /// No description provided for @attendanceByMobile.
  ///
  /// In en, this message translates to:
  /// **'By Mobile'**
  String get attendanceByMobile;

  /// No description provided for @tasksTitle.
  ///
  /// In en, this message translates to:
  /// **'My tasks'**
  String get tasksTitle;

  /// No description provided for @tasksProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get tasksProjects;

  /// No description provided for @tasksCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load tasks'**
  String get tasksCouldNotLoad;

  /// No description provided for @tasksNoneAssigned.
  ///
  /// In en, this message translates to:
  /// **'No tasks assigned'**
  String get tasksNoneAssigned;

  /// No description provided for @tasksNoneAssignedMsg.
  ///
  /// In en, this message translates to:
  /// **'New work assigned to you will show up here.'**
  String get tasksNoneAssignedMsg;

  /// No description provided for @tasksNoneAssignedMemberMsg.
  ///
  /// In en, this message translates to:
  /// **'Nothing is assigned to this person right now.'**
  String get tasksNoneAssignedMemberMsg;

  /// No description provided for @tasksThisWeek.
  ///
  /// In en, this message translates to:
  /// **'THIS WEEK'**
  String get tasksThisWeek;

  /// No description provided for @tasksKeepMomentum.
  ///
  /// In en, this message translates to:
  /// **'Keep the momentum'**
  String get tasksKeepMomentum;

  /// No description provided for @tasksDoneOfTotal.
  ///
  /// In en, this message translates to:
  /// **'/ {total} done'**
  String tasksDoneOfTotal(int total);

  /// No description provided for @tasksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, one{task} other{tasks}}'**
  String tasksCount(int count);

  /// No description provided for @tasksClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get tasksClient;

  /// No description provided for @tasksDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get tasksDescription;

  /// No description provided for @tasksAttachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get tasksAttachments;

  /// No description provided for @tasksCouldNotLoadAttachments.
  ///
  /// In en, this message translates to:
  /// **'Could not load the attachments.'**
  String get tasksCouldNotLoadAttachments;

  /// No description provided for @tasksCouldNotOpenAttachment.
  ///
  /// In en, this message translates to:
  /// **'Could not open the file.'**
  String get tasksCouldNotOpenAttachment;

  /// No description provided for @tasksMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark done ✓'**
  String get tasksMarkDone;

  /// No description provided for @tasksDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tasksDelete;

  /// No description provided for @tasksDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this task?'**
  String get tasksDeleteConfirmTitle;

  /// No description provided for @tasksDeleteConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'The task and its attachments will be permanently deleted.'**
  String get tasksDeleteConfirmMsg;

  /// No description provided for @tasksCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Opened by: {name}'**
  String tasksCreatedBy(String name);

  /// No description provided for @tasksFinishedTitle.
  ///
  /// In en, this message translates to:
  /// **'Finished this month'**
  String get tasksFinishedTitle;

  /// No description provided for @tasksFinishedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing finished yet this month'**
  String get tasksFinishedEmpty;

  /// No description provided for @tasksFinishedEmptyMsg.
  ///
  /// In en, this message translates to:
  /// **'Tasks you finish this month will show up here.'**
  String get tasksFinishedEmptyMsg;

  /// No description provided for @tasksRemind.
  ///
  /// In en, this message translates to:
  /// **'Remind'**
  String get tasksRemind;

  /// No description provided for @tasksReminderSent.
  ///
  /// In en, this message translates to:
  /// **'Reminder sent to {names}'**
  String tasksReminderSent(String names);

  /// No description provided for @commonAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get commonAnd;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @chatWith.
  ///
  /// In en, this message translates to:
  /// **'With {name}'**
  String chatWith(String name);

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatEmpty;

  /// No description provided for @chatEmptyMsg.
  ///
  /// In en, this message translates to:
  /// **'Say something to get started.'**
  String get chatEmptyMsg;

  /// No description provided for @chatCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load the chat'**
  String get chatCouldNotLoad;

  /// No description provided for @chatLocked.
  ///
  /// In en, this message translates to:
  /// **'This chat is locked.'**
  String get chatLocked;

  /// No description provided for @chatLocksAt.
  ///
  /// In en, this message translates to:
  /// **'Locks at {time}'**
  String chatLocksAt(String time);

  /// No description provided for @chatTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get chatTypeMessage;

  /// No description provided for @chatAttach.
  ///
  /// In en, this message translates to:
  /// **'Attach files'**
  String get chatAttach;

  /// No description provided for @chatRecordVoice.
  ///
  /// In en, this message translates to:
  /// **'Record a voice message'**
  String get chatRecordVoice;

  /// No description provided for @chatStopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get chatStopRecording;

  /// No description provided for @chatRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording… {time}'**
  String chatRecording(String time);

  /// No description provided for @chatVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'🎤 Voice message'**
  String get chatVoiceMessage;

  /// No description provided for @chatPhoto.
  ///
  /// In en, this message translates to:
  /// **'📷 Photo'**
  String get chatPhoto;

  /// No description provided for @chatVideo.
  ///
  /// In en, this message translates to:
  /// **'🎬 Video'**
  String get chatVideo;

  /// No description provided for @chatCouldNotSend.
  ///
  /// In en, this message translates to:
  /// **'Could not send the message.'**
  String get chatCouldNotSend;

  /// No description provided for @chatCouldNotRecord.
  ///
  /// In en, this message translates to:
  /// **'Could not start recording.'**
  String get chatCouldNotRecord;

  /// No description provided for @chatMicPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is needed to record a voice message.'**
  String get chatMicPermissionDenied;

  /// No description provided for @chatRemoveFile.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get chatRemoveFile;

  /// No description provided for @projectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectsTitle;

  /// No description provided for @projectsCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load projects'**
  String get projectsCouldNotLoad;

  /// No description provided for @projectsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get projectsEmpty;

  /// No description provided for @projectsDone.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get projectsDone;

  /// No description provided for @projectsWorking.
  ///
  /// In en, this message translates to:
  /// **'working'**
  String get projectsWorking;

  /// No description provided for @projectsOpen.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get projectsOpen;

  /// No description provided for @projectsOverdue.
  ///
  /// In en, this message translates to:
  /// **'overdue'**
  String get projectsOverdue;

  /// No description provided for @projectsDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{today} one{1 day left} other{{days} days left}}'**
  String projectsDaysLeft(int days);

  /// No description provided for @projectsNoSprint.
  ///
  /// In en, this message translates to:
  /// **'No sprint'**
  String get projectsNoSprint;

  /// No description provided for @projectsSprintEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks in this sprint'**
  String get projectsSprintEmpty;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @calendarTeamTasks.
  ///
  /// In en, this message translates to:
  /// **'Team tasks'**
  String get calendarTeamTasks;

  /// No description provided for @calendarNothingThisDay.
  ///
  /// In en, this message translates to:
  /// **'Nothing on this day'**
  String get calendarNothingThisDay;

  /// No description provided for @calendarAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get calendarAllDay;

  /// No description provided for @calendarPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get calendarPending;

  /// No description provided for @calendarCouldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save the event.'**
  String get calendarCouldNotSave;

  /// No description provided for @calendarNewEvent.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get calendarNewEvent;

  /// No description provided for @calendarEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get calendarEventTitle;

  /// No description provided for @calendarEventName.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get calendarEventName;

  /// No description provided for @calendarStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get calendarStart;

  /// No description provided for @calendarEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get calendarEnd;

  /// No description provided for @calendarPlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get calendarPlace;

  /// No description provided for @calendarNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get calendarNotes;

  /// No description provided for @calendarPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get calendarPeople;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsClearAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all notifications?'**
  String get notificationsClearAllTitle;

  /// No description provided for @notificationsClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get notificationsClearAll;

  /// No description provided for @notificationsUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get notificationsUpdates;

  /// No description provided for @notificationsCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load notifications'**
  String get notificationsCouldNotLoad;

  /// No description provided for @notificationsNothingNew.
  ///
  /// In en, this message translates to:
  /// **'Nothing new'**
  String get notificationsNothingNew;

  /// No description provided for @notificationsNothingNewMsg.
  ///
  /// In en, this message translates to:
  /// **'Announcements and updates will appear here.'**
  String get notificationsNothingNewMsg;

  /// No description provided for @notificationsCouldNotDismiss.
  ///
  /// In en, this message translates to:
  /// **'Could not dismiss the notification.'**
  String get notificationsCouldNotDismiss;

  /// No description provided for @notificationsCouldNotClear.
  ///
  /// In en, this message translates to:
  /// **'Could not clear notifications.'**
  String get notificationsCouldNotClear;

  /// No description provided for @notificationsReadAll.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsReadAll;

  /// No description provided for @notificationsCouldNotMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Could not mark notifications as read.'**
  String get notificationsCouldNotMarkRead;

  /// No description provided for @transportationTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily expenses'**
  String get transportationTitle;

  /// No description provided for @transportationEntrySaved.
  ///
  /// In en, this message translates to:
  /// **'Entry saved.'**
  String get transportationEntrySaved;

  /// No description provided for @transportationOpenReport.
  ///
  /// In en, this message translates to:
  /// **'Open report'**
  String get transportationOpenReport;

  /// No description provided for @transportationOpenReportPdf.
  ///
  /// In en, this message translates to:
  /// **'Open report (PDF)'**
  String get transportationOpenReportPdf;

  /// No description provided for @transportationCouldNotGenerateReport.
  ///
  /// In en, this message translates to:
  /// **'Could not generate the report.'**
  String get transportationCouldNotGenerateReport;

  /// No description provided for @transportationDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get transportationDeleteTitle;

  /// No description provided for @transportationDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get transportationDelete;

  /// No description provided for @transportationEntryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted.'**
  String get transportationEntryDeleted;

  /// No description provided for @transportationCouldNotDelete.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the entry.'**
  String get transportationCouldNotDelete;

  /// No description provided for @transportationEntriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get transportationEntriesLabel;

  /// No description provided for @transportationTotal.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get transportationTotal;

  /// No description provided for @transportationDistance.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE'**
  String get transportationDistance;

  /// No description provided for @transportationEntriesMetric.
  ///
  /// In en, this message translates to:
  /// **'ENTRIES'**
  String get transportationEntriesMetric;

  /// No description provided for @transportationCouldNotLoadEntries.
  ///
  /// In en, this message translates to:
  /// **'Could not load entries'**
  String get transportationCouldNotLoadEntries;

  /// No description provided for @transportationNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get transportationNoEntries;

  /// No description provided for @transportationNoEntriesMsg.
  ///
  /// In en, this message translates to:
  /// **'Tap + to log a trip with its KM, clients and total.'**
  String get transportationNoEntriesMsg;

  /// No description provided for @transportationNoEntriesMember.
  ///
  /// In en, this message translates to:
  /// **'No entries'**
  String get transportationNoEntriesMember;

  /// No description provided for @transportationNoTripsMemberMsg.
  ///
  /// In en, this message translates to:
  /// **'No trips were logged in the selected dates.'**
  String get transportationNoTripsMemberMsg;

  /// No description provided for @transportationDeleteEntryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get transportationDeleteEntryTooltip;

  /// No description provided for @transportationReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get transportationReportTitle;

  /// No description provided for @editorEditEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editorEditEntry;

  /// No description provided for @editorNewEntry.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get editorNewEntry;

  /// No description provided for @editorTransactionLabel.
  ///
  /// In en, this message translates to:
  /// **'TRANSACTION'**
  String get editorTransactionLabel;

  /// No description provided for @editorDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get editorDate;

  /// No description provided for @editorKm.
  ///
  /// In en, this message translates to:
  /// **'KM'**
  String get editorKm;

  /// No description provided for @editorTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get editorTotal;

  /// No description provided for @editorNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get editorNotes;

  /// No description provided for @editorClientsLabel.
  ///
  /// In en, this message translates to:
  /// **'CLIENTS'**
  String get editorClientsLabel;

  /// No description provided for @editorAddClient.
  ///
  /// In en, this message translates to:
  /// **'Add Client'**
  String get editorAddClient;

  /// No description provided for @editorNoClients.
  ///
  /// In en, this message translates to:
  /// **'No clients attached to this trip yet.'**
  String get editorNoClients;

  /// No description provided for @editorSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get editorSaving;

  /// No description provided for @editorSaveEntry.
  ///
  /// In en, this message translates to:
  /// **'Save entry'**
  String get editorSaveEntry;

  /// No description provided for @editorCouldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save the entry.'**
  String get editorCouldNotSave;

  /// No description provided for @editorRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get editorRequired;

  /// No description provided for @editorEnterNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get editorEnterNumber;

  /// No description provided for @editorAddClientTitle.
  ///
  /// In en, this message translates to:
  /// **'Add client'**
  String get editorAddClientTitle;

  /// No description provided for @editorSearchClients.
  ///
  /// In en, this message translates to:
  /// **'Search clients'**
  String get editorSearchClients;

  /// No description provided for @editorNoClientsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No clients available'**
  String get editorNoClientsAvailable;

  /// No description provided for @editorNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get editorNoMatches;

  /// No description provided for @editorClientListFailed.
  ///
  /// In en, this message translates to:
  /// **'The client list could not be loaded.'**
  String get editorClientListFailed;

  /// No description provided for @editorTryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term.'**
  String get editorTryDifferentSearch;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get profileSignOutTitle;

  /// No description provided for @profileSignOutMsg.
  ///
  /// In en, this message translates to:
  /// **'You will need your username and password to sign back in.'**
  String get profileSignOutMsg;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// No description provided for @profileWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get profileWorkspace;

  /// No description provided for @profileTeamRequestsSub.
  ///
  /// In en, this message translates to:
  /// **'Approve or reject your team\'s requests'**
  String get profileTeamRequestsSub;

  /// No description provided for @profileAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccount;

  /// No description provided for @profileUserId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get profileUserId;

  /// No description provided for @profileServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get profileServer;

  /// No description provided for @profileSignOutSub.
  ///
  /// In en, this message translates to:
  /// **'End this session on this device'**
  String get profileSignOutSub;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileLanguageSub.
  ///
  /// In en, this message translates to:
  /// **'Switch the app between English and Arabic'**
  String get profileLanguageSub;

  /// No description provided for @memberViewOnly.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get memberViewOnly;

  /// No description provided for @memberTabAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get memberTabAttendance;

  /// No description provided for @memberTabLeaves.
  ///
  /// In en, this message translates to:
  /// **'Leaves'**
  String get memberTabLeaves;

  /// No description provided for @memberTabTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get memberTabTasks;

  /// No description provided for @memberTabTransportation.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get memberTabTransportation;

  /// No description provided for @memberToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get memberToday;

  /// No description provided for @memberCouldNotLoadLeaveRequests.
  ///
  /// In en, this message translates to:
  /// **'Could not load leave requests'**
  String get memberCouldNotLoadLeaveRequests;

  /// No description provided for @memberNoLeaveRequests.
  ///
  /// In en, this message translates to:
  /// **'No leave requests'**
  String get memberNoLeaveRequests;

  /// No description provided for @requestsInRangeMsg.
  ///
  /// In en, this message translates to:
  /// **'Requests in the selected dates will appear here.'**
  String get requestsInRangeMsg;

  /// No description provided for @teamTitle.
  ///
  /// In en, this message translates to:
  /// **'My Team'**
  String get teamTitle;

  /// No description provided for @teamCouldNotLoadBoard.
  ///
  /// In en, this message translates to:
  /// **'Could not load the team board'**
  String get teamCouldNotLoadBoard;

  /// No description provided for @teamNoMembers.
  ///
  /// In en, this message translates to:
  /// **'No team members'**
  String get teamNoMembers;

  /// No description provided for @teamNoMembersMsg.
  ///
  /// In en, this message translates to:
  /// **'People who report to you will appear here.'**
  String get teamNoMembersMsg;

  /// No description provided for @teamLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Team requests'**
  String get teamLeaveTitle;

  /// No description provided for @teamLeaveApproveTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve this request?'**
  String get teamLeaveApproveTitle;

  /// No description provided for @teamLeaveApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get teamLeaveApprove;

  /// No description provided for @teamLeaveApproved.
  ///
  /// In en, this message translates to:
  /// **'Request approved'**
  String get teamLeaveApproved;

  /// No description provided for @teamLeaveRejected.
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get teamLeaveRejected;

  /// No description provided for @teamLeaveForbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission for this request'**
  String get teamLeaveForbidden;

  /// No description provided for @teamLeaveAlreadyDecided.
  ///
  /// In en, this message translates to:
  /// **'A decision was already made on this request'**
  String get teamLeaveAlreadyDecided;

  /// No description provided for @teamLeaveNotFound.
  ///
  /// In en, this message translates to:
  /// **'This request no longer exists'**
  String get teamLeaveNotFound;

  /// No description provided for @teamLeaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the request'**
  String get teamLeaveFailed;

  /// No description provided for @teamLeaveRequestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get teamLeaveRequestsLabel;

  /// No description provided for @teamLeaveAllDates.
  ///
  /// In en, this message translates to:
  /// **'All dates'**
  String get teamLeaveAllDates;

  /// No description provided for @teamLeaveAllEmployees.
  ///
  /// In en, this message translates to:
  /// **'All employees'**
  String get teamLeaveAllEmployees;

  /// No description provided for @teamLeaveNoRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests'**
  String get teamLeaveNoRequests;

  /// No description provided for @teamLeaveMatchingMsg.
  ///
  /// In en, this message translates to:
  /// **'Requests matching these filters will appear here.'**
  String get teamLeaveMatchingMsg;

  /// No description provided for @teamLeaveCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load team requests'**
  String get teamLeaveCouldNotLoad;

  /// No description provided for @rejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason: {reason}'**
  String rejectionReason(String reason);

  /// No description provided for @teamLeaveReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get teamLeaveReject;

  /// No description provided for @teamLeaveWaitingDirectManager.
  ///
  /// In en, this message translates to:
  /// **'Waiting on the direct manager\'s decision'**
  String get teamLeaveWaitingDirectManager;

  /// No description provided for @teamLeaveRejectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject request'**
  String get teamLeaveRejectDialogTitle;

  /// No description provided for @teamLeaveRejectionHint.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get teamLeaveRejectionHint;

  /// No description provided for @teamLeaveReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'A reason is required'**
  String get teamLeaveReasonRequired;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @leaveKindLeaving.
  ///
  /// In en, this message translates to:
  /// **'Leaving'**
  String get leaveKindLeaving;

  /// No description provided for @leaveKindVacation.
  ///
  /// In en, this message translates to:
  /// **'Vacation'**
  String get leaveKindVacation;

  /// No description provided for @leaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave & vacation'**
  String get leaveTitle;

  /// No description provided for @leaveTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get leaveTakePhoto;

  /// No description provided for @leaveChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get leaveChooseFromGallery;

  /// No description provided for @leaveMedicalReportAttached.
  ///
  /// In en, this message translates to:
  /// **'Medical report attached.'**
  String get leaveMedicalReportAttached;

  /// No description provided for @leaveCouldNotAttach.
  ///
  /// In en, this message translates to:
  /// **'Could not attach the report.'**
  String get leaveCouldNotAttach;

  /// No description provided for @leaveRequestSentToManager.
  ///
  /// In en, this message translates to:
  /// **'Request sent to your manager'**
  String get leaveRequestSentToManager;

  /// No description provided for @leaveAttachMedicalTitle.
  ///
  /// In en, this message translates to:
  /// **'Attach the medical report?'**
  String get leaveAttachMedicalTitle;

  /// No description provided for @leaveAttachLaterMsg.
  ///
  /// In en, this message translates to:
  /// **'You can also attach it later from the request card.'**
  String get leaveAttachLaterMsg;

  /// No description provided for @leaveLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get leaveLater;

  /// No description provided for @leaveAttachNow.
  ///
  /// In en, this message translates to:
  /// **'Attach now'**
  String get leaveAttachNow;

  /// No description provided for @leaveCancelRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this request?'**
  String get leaveCancelRequestTitle;

  /// No description provided for @leaveKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get leaveKeep;

  /// No description provided for @leaveCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get leaveCancelRequest;

  /// No description provided for @leaveRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled.'**
  String get leaveRequestCancelled;

  /// No description provided for @leaveCouldNotCancel.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel the request.'**
  String get leaveCouldNotCancel;

  /// No description provided for @leaveKindRequests.
  ///
  /// In en, this message translates to:
  /// **'{kind} requests'**
  String leaveKindRequests(String kind);

  /// No description provided for @leaveNewRequest.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get leaveNewRequest;

  /// No description provided for @leaveCouldNotLoadRequests.
  ///
  /// In en, this message translates to:
  /// **'Could not load requests'**
  String get leaveCouldNotLoadRequests;

  /// No description provided for @leaveNoKindRequests.
  ///
  /// In en, this message translates to:
  /// **'No {kind} requests'**
  String leaveNoKindRequests(String kind);

  /// No description provided for @leaveNoVacationBalance.
  ///
  /// In en, this message translates to:
  /// **'No vacation balance set for this year.'**
  String get leaveNoVacationBalance;

  /// No description provided for @leaveRemainingOf.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day} other{{count} days}} remaining of'**
  String leaveRemainingOf(num count);

  /// No description provided for @leaveAttachMedicalReportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Attach medical report'**
  String get leaveAttachMedicalReportTooltip;

  /// No description provided for @leaveAttachmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get leaveAttachmentsTitle;

  /// No description provided for @leaveCouldNotLoadAttachments.
  ///
  /// In en, this message translates to:
  /// **'Could not load the attachments.'**
  String get leaveCouldNotLoadAttachments;

  /// No description provided for @leaveNoAttachments.
  ///
  /// In en, this message translates to:
  /// **'No attachments yet.'**
  String get leaveNoAttachments;

  /// No description provided for @leaveViewMedicalReport.
  ///
  /// In en, this message translates to:
  /// **'View medical report'**
  String get leaveViewMedicalReport;

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} hour} other{{count} hours}}'**
  String durationHours(num count);

  /// No description provided for @durationDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day} other{{count} days}}'**
  String durationDays(num count);

  /// No description provided for @leaveApprovedBy.
  ///
  /// In en, this message translates to:
  /// **'Approved by {name}'**
  String leaveApprovedBy(String name);

  /// No description provided for @leaveDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Request details'**
  String get leaveDetailTitle;

  /// No description provided for @leaveDetailCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load the request'**
  String get leaveDetailCouldNotLoad;

  /// No description provided for @leavePendingWith.
  ///
  /// In en, this message translates to:
  /// **'Pending with: {name}'**
  String leavePendingWith(String name);

  /// No description provided for @leaveStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Request history'**
  String get leaveStepsTitle;

  /// No description provided for @leaveStepSubmitted.
  ///
  /// In en, this message translates to:
  /// **'{name} submitted the request'**
  String leaveStepSubmitted(String name);

  /// No description provided for @leaveStepForwarded.
  ///
  /// In en, this message translates to:
  /// **'{from} forwarded it to {to}'**
  String leaveStepForwarded(String from, String to);

  /// No description provided for @leaveStepApproved.
  ///
  /// In en, this message translates to:
  /// **'{name} approved the request'**
  String leaveStepApproved(String name);

  /// No description provided for @leaveStepRejected.
  ///
  /// In en, this message translates to:
  /// **'{name} rejected the request'**
  String leaveStepRejected(String name);

  /// No description provided for @leaveForwardTo.
  ///
  /// In en, this message translates to:
  /// **'Forward to {name}'**
  String leaveForwardTo(String name);

  /// No description provided for @leaveForwardNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Optional note'**
  String get leaveForwardNoteHint;

  /// No description provided for @leaveForwardButton.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get leaveForwardButton;

  /// No description provided for @leaveForwarded.
  ///
  /// In en, this message translates to:
  /// **'Request forwarded.'**
  String get leaveForwarded;

  /// No description provided for @leaveWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get leaveWithdraw;

  /// No description provided for @leaveWithdrawConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw this request?'**
  String get leaveWithdrawConfirmTitle;

  /// No description provided for @leaveEditorChooseType.
  ///
  /// In en, this message translates to:
  /// **'Choose a type for this request.'**
  String get leaveEditorChooseType;

  /// No description provided for @leaveEditorEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'The end date cannot be before the start date.'**
  String get leaveEditorEndBeforeStart;

  /// No description provided for @leaveEditorCouldNotSubmit.
  ///
  /// In en, this message translates to:
  /// **'Could not submit the request.'**
  String get leaveEditorCouldNotSubmit;

  /// No description provided for @leaveEditorFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get leaveEditorFrom;

  /// No description provided for @leaveEditorTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get leaveEditorTo;

  /// No description provided for @leaveEditorSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get leaveEditorSubmitting;

  /// No description provided for @leaveEditorSubmitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get leaveEditorSubmitRequest;

  /// No description provided for @leaveEditorConflictsTitle.
  ///
  /// In en, this message translates to:
  /// **'Teammates off at the same time'**
  String get leaveEditorConflictsTitle;

  /// No description provided for @leaveEditorConflictLine.
  ///
  /// In en, this message translates to:
  /// **'{name} is off in the same window ({from} → {to})'**
  String leaveEditorConflictLine(String name, String from, String to);

  /// No description provided for @leaveEditorSubmitAnyway.
  ///
  /// In en, this message translates to:
  /// **'Submit anyway'**
  String get leaveEditorSubmitAnyway;

  /// No description provided for @leaveEditorType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get leaveEditorType;

  /// No description provided for @leaveEditorNoTypesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No types available'**
  String get leaveEditorNoTypesAvailable;

  /// No description provided for @leaveEditorChooseTypeValidator.
  ///
  /// In en, this message translates to:
  /// **'Choose a type'**
  String get leaveEditorChooseTypeValidator;

  /// No description provided for @leaveWorkLeavingClientsLabel.
  ///
  /// In en, this message translates to:
  /// **'Which client are you going to?'**
  String get leaveWorkLeavingClientsLabel;

  /// No description provided for @leaveChooseClientRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose the client you\'re going to'**
  String get leaveChooseClientRequired;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
