// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonBack => 'Back';

  @override
  String get commonMore => 'More';

  @override
  String get commonSend => 'Send';

  @override
  String get loginWelcomeBack => 'WELCOME BACK';

  @override
  String get loginSignInToContinue => 'Sign in to continue';

  @override
  String get loginUsername => 'Username';

  @override
  String get loginEnterUsername => 'Enter your username';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginEnterPassword => 'Enter your password';

  @override
  String get loginSignIn => 'Sign in';

  @override
  String get loginFooter => 'Cloud Data Solutions · Internal use only';

  @override
  String get dashboardGoodMorning => 'Good morning';

  @override
  String get dashboardGoodAfternoon => 'Good afternoon';

  @override
  String get dashboardGoodEvening => 'Good evening';

  @override
  String get dashboardWelcome => 'Welcome';

  @override
  String get dashboardHello => 'hello';

  @override
  String get dashboardOverview => 'Overview';

  @override
  String get dashboardThisMonth => 'This month';

  @override
  String get navHome => 'Home';

  @override
  String get navTasks => 'Tasks';

  @override
  String get dashboardAttendance => 'Attendance';

  @override
  String get dashboardLeaveRequests => 'Leave requests';

  @override
  String get dashboardOpenTasks => 'Open tasks';

  @override
  String get dashboardQuickActions => 'Quick actions';

  @override
  String get dashboardDailyExpenses => 'Daily expenses';

  @override
  String get dashboardDailyExpensesSub => 'Log KM, clients & totals';

  @override
  String get dashboardLeaveRequest => 'Leave request';

  @override
  String get dashboardLeaveRequestSub => 'Leaving or vacation';

  @override
  String get dashboardRecentActivity => 'Recent activity';

  @override
  String get dashboardViewAll => 'View all';

  @override
  String get dashboardNoActivity => 'No activity yet this month.';

  @override
  String get dashboardCheckedIn => 'Checked in';

  @override
  String get dashboardTripSubmitted => 'Trip submitted';

  @override
  String get dashboardWorkHoursToday => 'Work hours today';

  @override
  String get dashboardEmployeesPunched => 'Punched in today';

  @override
  String get dashboardCouldNotLoad => 'Could not load the dashboard';

  @override
  String get dashboardManagerEyebrow => 'Your team at a glance';

  @override
  String get dashboardEmployeeEyebrow => 'Your work at a glance';

  @override
  String get dashboardManagerSubtitle =>
      'Here\'s how your team is doing today.';

  @override
  String get dashboardEmployeeSubtitle => 'Here\'s a summary of your day.';

  @override
  String get dashboardDailySummary => 'Daily performance summary';

  @override
  String dashboardLastUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get dashboardTasksThisMonth => 'Tasks this month';

  @override
  String dashboardDoneCount(int count) {
    return '$count done';
  }

  @override
  String get dashboardFinishedThisMonth => 'Finished this month';

  @override
  String dashboardOpenedThisMonth(int count) {
    return '$count opened this month';
  }

  @override
  String dashboardOverdueCount(int count) {
    return '$count overdue';
  }

  @override
  String get dashboardNoPunchToday => 'No punch recorded today';

  @override
  String get dashboardAttendanceToday => 'Attendance today';

  @override
  String dashboardOfTeam(int percent) {
    return '$percent% of the team';
  }

  @override
  String get dashboardCompletionRate => 'Monthly task completion';

  @override
  String get dashboardPendingApprovals => 'Awaiting your approval';

  @override
  String get dashboardTeamToday => 'Team today';

  @override
  String dashboardOnLeaveAbsent(int onLeave, int absent) {
    return '$onLeave on leave · $absent not punched';
  }

  @override
  String get dashboardUpcomingTasks => 'Upcoming tasks';

  @override
  String get dashboardPresent => 'Present';

  @override
  String get dashboardNotPunched => 'Not punched';

  @override
  String get dashboardOnLeave => 'On leave';

  @override
  String get dashboardTeamLabel => 'Team';

  @override
  String get checkInAttendance => 'ATTENDANCE';

  @override
  String get checkInLive => 'Live';

  @override
  String get checkInVerifying => 'Verifying…';

  @override
  String get checkInTapToPunch => 'Tap to punch';

  @override
  String get checkInNoPunchToday => 'No punch recorded today';

  @override
  String get checkInIn => 'In';

  @override
  String get checkInOut => 'Out';

  @override
  String checkInDurationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String checkInDurationMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String checkInElapsedSince(String duration, String time) {
    return '$duration · since $time';
  }

  @override
  String checkInPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count punches waiting for a connection — they will send automatically',
      one: 'One punch waiting for a connection — it will send automatically',
    );
    return '$_temp0';
  }

  @override
  String get checkInInsideGeofence => 'Inside geofence';

  @override
  String checkInInsideSite(String siteName) {
    return 'Inside · $siteName';
  }

  @override
  String get checkInFingerprintRequired => 'Fingerprint required';

  @override
  String get checkInSomethingWrong => 'Something went wrong. Please try again.';

  @override
  String get appOutsideWorkSite => 'You are outside the work site';

  @override
  String get appOutsideWorkSiteBlocked =>
      'You\'re outside the work site — the punch can\'t be recorded from here.';

  @override
  String get appNoConnectionPunchQueued =>
      'No connection — the punch was saved and will send automatically';

  @override
  String get appNoFingerprintEnrolled =>
      'No fingerprint is enrolled on this device.';

  @override
  String get appConfirmFingerprintReason => 'Confirm your fingerprint to punch';

  @override
  String get appFingerprintNotRecognised =>
      'Fingerprint not recognised. Try again.';

  @override
  String appCheckedIn(String time) {
    return 'Checked in$time';
  }

  @override
  String appCheckedOut(String time) {
    return 'Checked out$time';
  }

  @override
  String get statusNotPunched => 'Not punched';

  @override
  String get statusIn => 'In';

  @override
  String statusInSince(String time) {
    return 'In since $time';
  }

  @override
  String statusInOut(String start, String end) {
    return 'In $start — Out $end';
  }

  @override
  String statusInAt(String time) {
    return 'In $time';
  }

  @override
  String get attendanceScreenTitle => 'Attendance history';

  @override
  String get attendanceDailyLog => 'Daily log';

  @override
  String attendanceEntriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'entries',
      one: 'entry',
    );
    return '$count $_temp0';
  }

  @override
  String get attendanceCouldNotLoad => 'Could not load attendance';

  @override
  String get attendanceNoRecords => 'No attendance records';

  @override
  String get attendanceNoRecordsMsg =>
      'There is nothing logged for the selected dates.';

  @override
  String get attendanceStart => 'START';

  @override
  String get attendanceEnd => 'END';

  @override
  String get attendanceLate => 'Late';

  @override
  String get attendanceByDevice => 'By Device';

  @override
  String get attendanceByMobile => 'By Mobile';

  @override
  String get tasksTitle => 'My tasks';

  @override
  String get tasksProjects => 'Projects';

  @override
  String get tasksCouldNotLoad => 'Could not load tasks';

  @override
  String get tasksNoneAssigned => 'No tasks assigned';

  @override
  String get tasksNoneAssignedMsg =>
      'New work assigned to you will show up here.';

  @override
  String get tasksNoneAssignedMemberMsg =>
      'Nothing is assigned to this person right now.';

  @override
  String get tasksThisWeek => 'THIS WEEK';

  @override
  String get tasksKeepMomentum => 'Keep the momentum';

  @override
  String tasksDoneOfTotal(int total) {
    return '/ $total done';
  }

  @override
  String tasksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tasks',
      one: 'task',
    );
    return '$count $_temp0';
  }

  @override
  String get tasksClient => 'Client';

  @override
  String get tasksDescription => 'Description';

  @override
  String get tasksAttachments => 'Attachments';

  @override
  String get tasksCouldNotLoadAttachments => 'Could not load the attachments.';

  @override
  String get tasksCouldNotOpenAttachment => 'Could not open the file.';

  @override
  String get tasksMarkDone => 'Mark done ✓';

  @override
  String get tasksDelete => 'Delete';

  @override
  String get tasksDeleteConfirmTitle => 'Delete this task?';

  @override
  String get tasksDeleteConfirmMsg =>
      'The task and its attachments will be permanently deleted.';

  @override
  String tasksCreatedBy(String name) {
    return 'Opened by: $name';
  }

  @override
  String get tasksFinishedTitle => 'Finished this month';

  @override
  String get tasksFinishedEmpty => 'Nothing finished yet this month';

  @override
  String get tasksFinishedEmptyMsg =>
      'Tasks you finish this month will show up here.';

  @override
  String get tasksRemind => 'Remind';

  @override
  String tasksReminderSent(String names) {
    return 'Reminder sent to $names';
  }

  @override
  String get commonAnd => ' and ';

  @override
  String get chatTitle => 'Chat';

  @override
  String chatWith(String name) {
    return 'With $name';
  }

  @override
  String get chatEmpty => 'No messages yet';

  @override
  String get chatEmptyMsg => 'Say something to get started.';

  @override
  String get chatCouldNotLoad => 'Could not load the chat';

  @override
  String get chatLocked => 'This chat is locked.';

  @override
  String chatLocksAt(String time) {
    return 'Locks at $time';
  }

  @override
  String get chatTypeMessage => 'Type a message…';

  @override
  String get chatAttach => 'Attach files';

  @override
  String get chatRecordVoice => 'Record a voice message';

  @override
  String get chatStopRecording => 'Stop recording';

  @override
  String chatRecording(String time) {
    return 'Recording… $time';
  }

  @override
  String get chatVoiceMessage => '🎤 Voice message';

  @override
  String get chatPhoto => '📷 Photo';

  @override
  String get chatVideo => '🎬 Video';

  @override
  String get chatCouldNotSend => 'Could not send the message.';

  @override
  String get chatCouldNotRecord => 'Could not start recording.';

  @override
  String get chatMicPermissionDenied =>
      'Microphone permission is needed to record a voice message.';

  @override
  String get chatRemoveFile => 'Remove';

  @override
  String get projectsTitle => 'Projects';

  @override
  String get projectsCouldNotLoad => 'Could not load projects';

  @override
  String get projectsEmpty => 'No projects yet';

  @override
  String get projectsDone => 'done';

  @override
  String get projectsWorking => 'working';

  @override
  String get projectsOpen => 'open';

  @override
  String get projectsOverdue => 'overdue';

  @override
  String projectsDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String get projectsNoSprint => 'No sprint';

  @override
  String get projectsSprintEmpty => 'No tasks in this sprint';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarTeamTasks => 'Team tasks';

  @override
  String get calendarNothingThisDay => 'Nothing on this day';

  @override
  String get calendarAllDay => 'All day';

  @override
  String get calendarPending => 'Pending';

  @override
  String get calendarCouldNotSave => 'Could not save the event.';

  @override
  String get calendarNewEvent => 'New event';

  @override
  String get calendarEventTitle => 'Event';

  @override
  String get calendarEventName => 'Title';

  @override
  String get calendarStart => 'Start';

  @override
  String get calendarEnd => 'End';

  @override
  String get calendarPlace => 'Place';

  @override
  String get calendarNotes => 'Notes';

  @override
  String get calendarPeople => 'People';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsClearAllTitle => 'Clear all notifications?';

  @override
  String get notificationsClearAll => 'Clear all';

  @override
  String get notificationsUpdates => 'Updates';

  @override
  String get notificationsCouldNotLoad => 'Could not load notifications';

  @override
  String get notificationsNothingNew => 'Nothing new';

  @override
  String get notificationsNothingNewMsg =>
      'Announcements and updates will appear here.';

  @override
  String get notificationsCouldNotDismiss =>
      'Could not dismiss the notification.';

  @override
  String get notificationsCouldNotClear => 'Could not clear notifications.';

  @override
  String get notificationsReadAll => 'Mark all as read';

  @override
  String get notificationsCouldNotMarkRead =>
      'Could not mark notifications as read.';

  @override
  String get transportationTitle => 'Daily expenses';

  @override
  String get transportationEntrySaved => 'Entry saved.';

  @override
  String get transportationOpenReport => 'Open report';

  @override
  String get transportationOpenReportPdf => 'Open report (PDF)';

  @override
  String get transportationCouldNotGenerateReport =>
      'Could not generate the report.';

  @override
  String get transportationDeleteTitle => 'Delete this entry?';

  @override
  String get transportationDelete => 'Delete';

  @override
  String get transportationEntryDeleted => 'Entry deleted.';

  @override
  String get transportationCouldNotDelete => 'Could not delete the entry.';

  @override
  String get transportationEntriesLabel => 'Entries';

  @override
  String get transportationTotal => 'TOTAL';

  @override
  String get transportationDistance => 'DISTANCE';

  @override
  String get transportationEntriesMetric => 'ENTRIES';

  @override
  String get transportationCouldNotLoadEntries => 'Could not load entries';

  @override
  String get transportationNoEntries => 'No entries yet';

  @override
  String get transportationNoEntriesMsg =>
      'Tap + to log a trip with its KM, clients and total.';

  @override
  String get transportationNoEntriesMember => 'No entries';

  @override
  String get transportationNoTripsMemberMsg =>
      'No trips were logged in the selected dates.';

  @override
  String get transportationDeleteEntryTooltip => 'Delete entry';

  @override
  String get transportationReportTitle => 'Report';

  @override
  String get editorEditEntry => 'Edit entry';

  @override
  String get editorNewEntry => 'New entry';

  @override
  String get editorTransactionLabel => 'TRANSACTION';

  @override
  String get editorDate => 'Date';

  @override
  String get editorKm => 'KM';

  @override
  String get editorTotal => 'Total';

  @override
  String get editorNotes => 'Notes';

  @override
  String get editorClientsLabel => 'CLIENTS';

  @override
  String get editorAddClient => 'Add Client';

  @override
  String get editorNoClients => 'No clients attached to this trip yet.';

  @override
  String get editorSaving => 'Saving…';

  @override
  String get editorSaveEntry => 'Save entry';

  @override
  String get editorCouldNotSave => 'Could not save the entry.';

  @override
  String get editorRequired => 'Required';

  @override
  String get editorEnterNumber => 'Enter a number';

  @override
  String get editorAddClientTitle => 'Add client';

  @override
  String get editorSearchClients => 'Search clients';

  @override
  String get editorNoClientsAvailable => 'No clients available';

  @override
  String get editorNoMatches => 'No matches';

  @override
  String get editorClientListFailed => 'The client list could not be loaded.';

  @override
  String get editorTryDifferentSearch => 'Try a different search term.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSignOutTitle => 'Sign out?';

  @override
  String get profileSignOutMsg =>
      'You will need your username and password to sign back in.';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileWorkspace => 'Workspace';

  @override
  String get profileTeamRequestsSub =>
      'Approve or reject your team\'s requests';

  @override
  String get profileAccount => 'Account';

  @override
  String get profileUserId => 'User ID';

  @override
  String get profileServer => 'Server';

  @override
  String get profileSignOutSub => 'End this session on this device';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileLanguageSub => 'Switch the app between English and Arabic';

  @override
  String get memberViewOnly => 'View only';

  @override
  String get memberTabAttendance => 'Attendance';

  @override
  String get memberTabLeaves => 'Leaves';

  @override
  String get memberTabTasks => 'Tasks';

  @override
  String get memberTabTransportation => 'Transportation';

  @override
  String get memberToday => 'Today';

  @override
  String get memberCouldNotLoadLeaveRequests => 'Could not load leave requests';

  @override
  String get memberNoLeaveRequests => 'No leave requests';

  @override
  String get requestsInRangeMsg =>
      'Requests in the selected dates will appear here.';

  @override
  String get teamTitle => 'My Team';

  @override
  String get teamCouldNotLoadBoard => 'Could not load the team board';

  @override
  String get teamNoMembers => 'No team members';

  @override
  String get teamNoMembersMsg => 'People who report to you will appear here.';

  @override
  String get teamLeaveTitle => 'Team requests';

  @override
  String get teamLeaveApproveTitle => 'Approve this request?';

  @override
  String get teamLeaveApprove => 'Approve';

  @override
  String get teamLeaveApproved => 'Request approved';

  @override
  String get teamLeaveRejected => 'Request rejected';

  @override
  String get teamLeaveForbidden =>
      'You do not have permission for this request';

  @override
  String get teamLeaveAlreadyDecided =>
      'A decision was already made on this request';

  @override
  String get teamLeaveNotFound => 'This request no longer exists';

  @override
  String get teamLeaveFailed => 'Could not complete the request';

  @override
  String get teamLeaveRequestsLabel => 'Requests';

  @override
  String get teamLeaveAllDates => 'All dates';

  @override
  String get teamLeaveAllEmployees => 'All employees';

  @override
  String get teamLeaveNoRequests => 'No requests';

  @override
  String get teamLeaveMatchingMsg =>
      'Requests matching these filters will appear here.';

  @override
  String get teamLeaveCouldNotLoad => 'Could not load team requests';

  @override
  String rejectionReason(String reason) {
    return 'Rejection reason: $reason';
  }

  @override
  String get teamLeaveReject => 'Reject';

  @override
  String get teamLeaveWaitingDirectManager =>
      'Waiting on the direct manager\'s decision';

  @override
  String get teamLeaveRejectDialogTitle => 'Reject request';

  @override
  String get teamLeaveRejectionHint => 'Rejection reason';

  @override
  String get teamLeaveReasonRequired => 'A reason is required';

  @override
  String get filterAll => 'All';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get leaveKindLeaving => 'Leaving';

  @override
  String get leaveKindVacation => 'Vacation';

  @override
  String get leaveTitle => 'Leave & vacation';

  @override
  String get leaveTakePhoto => 'Take a photo';

  @override
  String get leaveChooseFromGallery => 'Choose from gallery';

  @override
  String get leaveMedicalReportAttached => 'Medical report attached.';

  @override
  String get leaveCouldNotAttach => 'Could not attach the report.';

  @override
  String get leaveRequestSentToManager => 'Request sent to your manager';

  @override
  String get leaveAttachMedicalTitle => 'Attach the medical report?';

  @override
  String get leaveAttachLaterMsg =>
      'You can also attach it later from the request card.';

  @override
  String get leaveLater => 'Later';

  @override
  String get leaveAttachNow => 'Attach now';

  @override
  String get leaveCancelRequestTitle => 'Cancel this request?';

  @override
  String get leaveKeep => 'Keep';

  @override
  String get leaveCancelRequest => 'Cancel request';

  @override
  String get leaveRequestCancelled => 'Request cancelled.';

  @override
  String get leaveCouldNotCancel => 'Could not cancel the request.';

  @override
  String leaveKindRequests(String kind) {
    return '$kind requests';
  }

  @override
  String get leaveNewRequest => 'New request';

  @override
  String get leaveCouldNotLoadRequests => 'Could not load requests';

  @override
  String leaveNoKindRequests(String kind) {
    return 'No $kind requests';
  }

  @override
  String get leaveNoVacationBalance => 'No vacation balance set for this year.';

  @override
  String leaveRemainingOf(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0 remaining of';
  }

  @override
  String get leaveAttachMedicalReportTooltip => 'Attach medical report';

  @override
  String get leaveAttachmentsTitle => 'Attachments';

  @override
  String get leaveCouldNotLoadAttachments => 'Could not load the attachments.';

  @override
  String get leaveNoAttachments => 'No attachments yet.';

  @override
  String get leaveViewMedicalReport => 'View medical report';

  @override
  String durationHours(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '$count hour',
    );
    return '$_temp0';
  }

  @override
  String durationDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String leaveApprovedBy(String name) {
    return 'Approved by $name';
  }

  @override
  String get leaveDetailTitle => 'Request details';

  @override
  String get leaveDetailCouldNotLoad => 'Could not load the request';

  @override
  String leavePendingWith(String name) {
    return 'Pending with: $name';
  }

  @override
  String get leaveStepsTitle => 'Request history';

  @override
  String leaveStepSubmitted(String name) {
    return '$name submitted the request';
  }

  @override
  String leaveStepForwarded(String from, String to) {
    return '$from forwarded it to $to';
  }

  @override
  String leaveStepApproved(String name) {
    return '$name approved the request';
  }

  @override
  String leaveStepRejected(String name) {
    return '$name rejected the request';
  }

  @override
  String leaveForwardTo(String name) {
    return 'Forward to $name';
  }

  @override
  String get leaveForwardNoteHint => 'Optional note';

  @override
  String get leaveForwardButton => 'Forward';

  @override
  String get leaveForwarded => 'Request forwarded.';

  @override
  String get leaveWithdraw => 'Withdraw';

  @override
  String get leaveWithdrawConfirmTitle => 'Withdraw this request?';

  @override
  String get leaveEditorChooseType => 'Choose a type for this request.';

  @override
  String get leaveEditorEndBeforeStart =>
      'The end date cannot be before the start date.';

  @override
  String get leaveEditorCouldNotSubmit => 'Could not submit the request.';

  @override
  String get leaveEditorFrom => 'From';

  @override
  String get leaveEditorTo => 'To';

  @override
  String get leaveEditorSubmitting => 'Submitting…';

  @override
  String get leaveEditorSubmitRequest => 'Submit request';

  @override
  String get leaveEditorConflictsTitle => 'Teammates off at the same time';

  @override
  String leaveEditorConflictLine(String name, String from, String to) {
    return '$name is off in the same window ($from → $to)';
  }

  @override
  String get leaveEditorSubmitAnyway => 'Submit anyway';

  @override
  String get leaveEditorType => 'Type';

  @override
  String get leaveEditorNoTypesAvailable => 'No types available';

  @override
  String get leaveEditorChooseTypeValidator => 'Choose a type';

  @override
  String get leaveWorkLeavingClientsLabel => 'Which client are you going to?';

  @override
  String get leaveChooseClientRequired => 'Choose the client you\'re going to';
}
