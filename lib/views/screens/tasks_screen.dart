import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/task_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/tasks_service.dart';
import '../widgets/cds_app_bar.dart';
import '../widgets/cds_dialogs.dart';
import '../widgets/cds_refresh_indicator.dart';
import '../widgets/common.dart';
import '../widgets/skeleton.dart';
import 'task_chat_screen.dart';

/// §6 — "CDS Teams Tasks", grouped by project (OSFA, CMMS, ...).
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, this.embedded = false, this.initialTaskId});

  final bool embedded;

  /// Deep-linked here from a `task_done`/`task_new` push or notification tap
  /// (`additionalData.taskId`) — opens that task's details once loaded.
  final String? initialTaskId;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool _openedInitial = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTaskId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openInitialTask());
    }
  }

  Future<void> _openInitialTask() async {
    if (_openedInitial || !mounted) return;
    _openedInitial = true;
    final TasksProvider provider = context.read<TasksProvider>();
    final AuthProvider auth = context.read<AuthProvider>();
    final String? userId = auth.user?.userId;
    if (userId == null) return;
    if (!provider.hasLoadedOnce) {
      await provider.load(userId: userId);
    }
    if (!mounted) return;
    for (final TaskItem task in provider.tasks) {
      if (task.taskId == widget.initialTaskId) {
        showTaskDetails(context, task);
        return;
      }
    }
  }

  Future<void> _refresh(BuildContext context) async {
    final AuthProvider auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    await context.read<TasksProvider>().load(userId: auth.user!.userId);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final TasksProvider provider = context.watch<TasksProvider>();

    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!widget.embedded)
          CdsAppBar(
            title: t.tasksTitle,
            action: PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded, color: AppColors.ink),
              onSelected: (String route) => Navigator.of(context).pushNamed(route),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: AppRoutes.calendar,
                  child: Row(children: <Widget>[
                    const Icon(Icons.calendar_month_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(t.calendarTitle),
                  ]),
                ),
                PopupMenuItem<String>(
                  value: AppRoutes.projects,
                  child: Row(children: <Widget>[
                    const Icon(Icons.folder_open_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(t.projectsTitle),
                  ]),
                ),
              ],
            ),
          ),
        TaskSummary(done: provider.doneCount, total: provider.tasks.length),
        if (provider.statuses.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          _StatusFilterChips(provider: provider),
        ],
        if (provider.categories.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          _CategoryFilterChips(provider: provider),
        ],
        if (provider.creators.length > 1) ...<Widget>[
          const SizedBox(height: 10),
          _CreatedByFilterChips(provider: provider),
        ],
        const SizedBox(height: 22),
        ListLabel(label: t.tasksProjects),
        Expanded(
          child: CdsRefreshIndicator(
            onRefresh: () => _refresh(context),
            child: _Body(provider: provider, onRetry: () => _refresh(context)),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: body,
      );
    }

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: body,
          ),
        ),
      ),
    );
  }
}

class TaskSummary extends StatelessWidget {
  const TaskSummary({super.key, required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  t.tasksThisWeek,
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFAEBBB7),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  t.tasksKeepMomentum,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '$done',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8DE1BD),
                ),
              ),
              Text(
                t.tasksDoneOfTotal(total),
                style: const TextStyle(fontSize: 9, color: Color(0xFFAFBDBA)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Multi-select status chips from `GET /api/tasks/lookups` (2026-10-05).
/// Tapping a status toggles it, so several can be active together; "الكل"
/// clears the selection. Counts come from the already-loaded list, not a
/// fresh call per chip.
class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({required this.provider});

  final TasksProvider provider;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          _FilterChipPill(
            label: '${t.filterAll} (${provider.countFor(null)})',
            selected: provider.selectedStatuses.isEmpty,
            onTap: provider.clearStatusFilter,
          ),
          for (final Lookup status in provider.statuses)
            if (status.intCode != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: _FilterChipPill(
                  label: '${status.name} (${provider.countFor(status.intCode)})',
                  selected: provider.selectedStatuses.contains(
                    status.intCode,
                  ),
                  onTap: () => provider.toggleStatus(status.intCode!),
                ),
              ),
        ],
      ),
    );
  }
}

/// 2026-10-08 part B — one category at a time, filtered locally over
/// whatever's already loaded (the Portal does it the same way).
class _CategoryFilterChips extends StatelessWidget {
  const _CategoryFilterChips({required this.provider});

  final TasksProvider provider;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          _FilterChipPill(
            label: '${t.filterAll} (${provider.countForCategory(null)})',
            selected: provider.selectedCategory == null,
            onTap: () {
              if (provider.selectedCategory != null) {
                provider.toggleCategory(provider.selectedCategory!);
              }
            },
          ),
          for (final Lookup category in provider.categories)
            if (category.intCode != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: _FilterChipPill(
                  label:
                      '${category.name} (${provider.countForCategory(category.intCode)})',
                  selected: provider.selectedCategory == category.intCode,
                  onTap: () => provider.toggleCategory(category.intCode!),
                ),
              ),
        ],
      ),
    );
  }
}

/// Optional "Created by" filter (2026-10-08 part C), filtered locally over
/// whatever's already loaded, same as status/category.
class _CreatedByFilterChips extends StatelessWidget {
  const _CreatedByFilterChips({required this.provider});

  final TasksProvider provider;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          _FilterChipPill(
            label: '${t.filterAll} (${provider.countForCreatedBy(null)})',
            selected: provider.selectedCreatedBy == null,
            onTap: () {
              if (provider.selectedCreatedBy != null) {
                provider.toggleCreatedBy(provider.selectedCreatedBy!);
              }
            },
          ),
          for (final (String id, String name) in provider.creators)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: _FilterChipPill(
                label: '$name (${provider.countForCreatedBy(id)})',
                selected: provider.selectedCreatedBy == id,
                onTap: () => provider.toggleCreatedBy(id),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  const _FilterChipPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.green : const Color(0xCAFFFFFF),
          border: Border.all(
            color: selected ? AppColors.green : Colors.white,
          ),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.provider, required this.onRetry});

  final TasksProvider provider;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    if (provider.isLoading && provider.tasks.isEmpty) {
      return SkeletonList(
        itemCount: 3,
        spacing: 12,
        itemBuilder: (_, int i) => SkeletonGroupCard(seed: i, rows: 3 - (i % 2)),
      );
    }

    if (provider.hasError && provider.tasks.isEmpty) {
      return ListView(
        children: <Widget>[
          StateMessage(
            icon: Icons.cloud_off_rounded,
            tone: ToneColor.red,
            title: t.tasksCouldNotLoad,
            message: provider.error,
            actionLabel: t.commonTryAgain,
            onAction: onRetry,
          ),
        ],
      );
    }

    final List<TaskProject> projects = provider.projects;

    if (projects.isEmpty) {
      return ListView(
        children: <Widget>[
          StateMessage(
            icon: Icons.task_alt_rounded,
            title: t.tasksNoneAssigned,
            message: t.tasksNoneAssignedMsg,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 100),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: projects.length,
      separatorBuilder: (_, _) => const SizedBox(height: 9),
      itemBuilder: (BuildContext context, int index) => TaskProjectCard(
        project: projects[index],
        initiallyExpanded: index == 0,
        tone: index.isEven ? ToneColor.green : ToneColor.amber,
      ),
    );
  }
}

class TaskProjectCard extends StatelessWidget {
  const TaskProjectCard({
    super.key,
    required this.project,
    required this.initiallyExpanded,
    required this.tone,
  });

  final TaskProject project;
  final bool initiallyExpanded;
  final ToneColor tone;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xCAFFFFFF),
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.tinyShadow,
      ),
      clipBehavior: Clip.antiAlias,
      // ListTile paints on the nearest Material; without this one it would
      // be the page's, hidden behind this card's background.
      child: Material(
        type: MaterialType.transparency,
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
          ),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.symmetric(horizontal: 13),
            childrenPadding: const EdgeInsets.fromLTRB(13, 0, 13, 6),
            iconColor: const Color(0xFF899591),
            collapsedIconColor: const Color(0xFF899591),
            leading: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tone.background,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                project.initial,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: tone.foreground,
                ),
              ),
            ),
            title: Text(
              project.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            subtitle: project.clientName.isEmpty
                ? null
                : Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      project.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF929D9A),
                      ),
                    ),
                  ),
            trailing: Text(
              t.tasksCount(project.tasks.length),
              style: const TextStyle(fontSize: 9, color: Color(0xFF899591)),
            ),
            children: project.tasks
                .map((TaskItem task) => _TaskRow(task: task))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final int unread = context.watch<TasksProvider>().unreadChatFor(task.taskId);
    return InkWell(
      onTap: () => showTaskDetails(context, task),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 3),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFEEE5DE))),
        ),
        child: Row(
          children: <Widget>[
            _StatusDot(task: task),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    task.taskTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  if (task.hasCategory) ...<Widget>[
                    const SizedBox(height: 4),
                    _CategoryPill(task: task),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${task.deadlineLabel} · ${task.taskStatusName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      color: task.isOverdue
                          ? AppColors.red
                          : const Color(0xFF929D9A),
                      fontWeight: task.isOverdue
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                  if (task.createdByName.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      t.tasksCreatedBy(task.createdByName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF929D9A),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (task.hasAttachments) ...<Widget>[
              const Icon(
                Icons.attach_file_rounded,
                size: 13,
                color: Color(0xFF929D9A),
              ),
              Text(
                '${task.attachmentCount}',
                style: const TextStyle(fontSize: 9, color: Color(0xFF929D9A)),
              ),
              const SizedBox(width: 6),
            ],
            if (unread > 0) ...<Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$unread',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (task.canRemind) ...<Widget>[
              _RemindButton(task: task, compact: true),
              const SizedBox(width: 2),
            ],
            Icon(
              task.isDone ? Icons.check_rounded : Icons.chevron_right_rounded,
              size: 16,
              color: task.isDone ? AppColors.green : const Color(0xFFAAB2AF),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bell icon (task card) that sends `POST /api/tasks/{taskId}/remind` — only
/// shown when [TaskItem.canRemind]. Shared by the row and the compact form
/// used there; the details sheet instead drives [_RemindButtonState.send]
/// from its own full-width button.
class _RemindButton extends StatefulWidget {
  const _RemindButton({required this.task, this.compact = false});

  final TaskItem task;
  final bool compact;

  @override
  State<_RemindButton> createState() => _RemindButtonState();
}

class _RemindButtonState extends State<_RemindButton> {
  bool _busy = false;

  /// Sends the reminder and shows the result as a snack — used both by this
  /// button and by the task-details sheet's full-width one.
  static Future<void> send(BuildContext context, TaskItem task) async {
    final AppLocalizations t = AppLocalizations.of(context);
    try {
      final List<String> sentTo = await context
          .read<TasksService>()
          .remind(task.taskId);
      if (!context.mounted) return;
      showApiSnack(
        context,
        t.tasksReminderSent(sentTo.join(t.commonAnd)),
        isError: false,
      );
    } on ApiException catch (e) {
      if (context.mounted) showApiSnack(context, e.message);
    } catch (e) {
      if (context.mounted) showApiSnack(context, e.toString());
    }
  }

  Future<void> _press() async {
    setState(() => _busy = true);
    await _RemindButtonState.send(context, widget.task);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.compact) return const SizedBox.shrink();
    return InkWell(
      onTap: _busy ? null : _press,
      borderRadius: BorderRadius.circular(99),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: _busy
            ? const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  color: AppColors.blue,
                ),
              )
            : const Icon(
                Icons.notifications_active_outlined,
                size: 15,
                color: AppColors.blue,
              ),
      ),
    );
  }
}

/// Opens the task-details sheet — shared by tapping a row and by deep-linking
/// here from a `task_done`/`task_new` push or notification tap.
void showTaskDetails(BuildContext context, TaskItem task) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.cream,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (BuildContext context) => _TaskDetailsSheet(task: task),
  );
}

/// The task-details bottom sheet: fields, status/deadline chips, and (added
/// 2026-10-04) the task's attachments — images as a tap-to-zoom grid, other
/// files as a download-and-open list. View-only, there's no upload/delete.
class _TaskDetailsSheet extends StatefulWidget {
  const _TaskDetailsSheet({required this.task});

  final TaskItem task;

  @override
  State<_TaskDetailsSheet> createState() => _TaskDetailsSheetState();
}

class _TaskDetailsSheetState extends State<_TaskDetailsSheet> {
  late final Future<List<TaskAttachment>> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = widget.task.hasAttachments
        ? context.read<TasksService>().attachments(widget.task.taskId)
        : Future<List<TaskAttachment>>.value(const <TaskAttachment>[]);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final TaskItem task = widget.task;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              task.taskProjectName.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
                color: AppColors.subtleText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              task.taskTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (task.hasCategory)
                  StatusChip(
                    label: task.taskPageName.isEmpty
                        ? task.taskCategoryName
                        : '${task.taskCategoryName} · ${task.taskPageName}',
                    tone: _CategoryPill._toneFor(task.taskCategory),
                  ),
                StatusChip(
                  label: task.taskStatusName,
                  tone: task.isDone
                      ? ToneColor.green
                      : task.isInProgress
                      ? ToneColor.amber
                      : ToneColor.blue,
                ),
                StatusChip(
                  label: task.deadlineLabel,
                  tone: task.isOverdue ? ToneColor.red : ToneColor.blue,
                  icon: Icons.schedule_rounded,
                ),
              ],
            ),
            if (task.createdByName.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              Text(
                t.tasksCreatedBy(task.createdByName),
                style: const TextStyle(fontSize: 11, color: AppColors.subtleText),
              ),
            ],
            if (task.clientName.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              _DetailLine(label: t.tasksClient, value: task.clientName),
            ],
            if (task.taskDescription.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              _DetailLine(label: t.tasksDescription, value: task.taskDescription),
            ],
            if (task.hasAttachments) ...<Widget>[
              const SizedBox(height: 16),
              Text(
                t.tasksAttachments.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.faintText,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<TaskAttachment>>(
                future: _future,
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<TaskAttachment>> snapshot,
                    ) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const SkeletonThumbs(count: 3, size: 76);
                      }
                      final List<TaskAttachment>? items = snapshot.data;
                      if (snapshot.hasError || items == null) {
                        return Text(
                          t.tasksCouldNotLoadAttachments,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.red,
                          ),
                        );
                      }
                      final List<TaskAttachment> images = items
                          .where((TaskAttachment a) => a.isImage)
                          .toList();
                      final List<TaskAttachment> files = items
                          .where((TaskAttachment a) => !a.isImage)
                          .toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (images.isNotEmpty)
                            GridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.78,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: <Widget>[
                                for (final (int i, TaskAttachment a)
                                    in images.indexed)
                                  _ImageAttachmentTile(
                                    attachment: a,
                                    onTap: () => Navigator.of(context).push<void>(
                                      MaterialPageRoute<void>(
                                        builder: (_) => _TaskImagePager(
                                          images: images,
                                          initialIndex: i,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          if (files.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(
                                top: images.isNotEmpty ? 10 : 0,
                              ),
                              child: Column(
                                children: <Widget>[
                                  for (final TaskAttachment f in files)
                                    _FileAttachmentRow(attachment: f),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
              ),
            ],
            if (task.canEdit && !task.isDone) ...<Widget>[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _markDone,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(t.tasksMarkDone),
                ),
              ),
            ],
            if (_canChat(context)) ...<Widget>[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => TaskChatScreen(task: task),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.green,
                    side: const BorderSide(color: AppColors.green),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: Text(t.chatTitle),
                ),
              ),
            ],
            if (task.canRemind) ...<Widget>[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _remind,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blue,
                    side: const BorderSide(color: AppColors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                  ),
                  label: Text(t.tasksRemind),
                ),
              ),
            ],
            if (task.canDelete) ...<Widget>[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _confirmDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: AppColors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(t.tasksDelete),
                ),
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// The chat is only between the task's creator and its assignee
  /// (2026-10-08 part C) — both fields were already on the row.
  bool _canChat(BuildContext context) {
    final String? userId = context.read<AuthProvider>().user?.userId;
    if (userId == null) return false;
    final TaskItem task = widget.task;
    return userId == task.createdBy || userId == task.responsibleUser;
  }

  Future<void> _remind() async {
    setState(() => _busy = true);
    await _RemindButtonState.send(context, widget.task);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _markDone() async {
    setState(() => _busy = true);
    final String? error = await context.read<TasksProvider>().updateStatus(
      widget.task.taskId,
      3,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      showApiSnack(context, error);
    }
  }

  Future<void> _confirmDelete() async {
    final AppLocalizations t = AppLocalizations.of(context);
    final bool confirmed = await showCdsConfirm(
      context,
      icon: Icons.delete_outline_rounded,
      tone: ToneColor.red,
      title: t.tasksDeleteConfirmTitle,
      message: t.tasksDeleteConfirmMsg,
      details: <String>[widget.task.taskTitle],
      confirmLabel: t.tasksDelete,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    final String? error = await context.read<TasksProvider>().delete(
      widget.task.taskId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      showApiSnack(context, error);
    }
  }
}

/// One image tile in the attachments grid: thumbnail, file name, size and
/// uploader. Tap opens the full-screen swipeable pager.
class _ImageAttachmentTile extends StatefulWidget {
  const _ImageAttachmentTile({required this.attachment, required this.onTap});

  final TaskAttachment attachment;
  final VoidCallback onTap;

  @override
  State<_ImageAttachmentTile> createState() => _ImageAttachmentTileState();
}

class _ImageAttachmentTileState extends State<_ImageAttachmentTile> {
  late final Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = context.read<TasksService>().attachmentBytes(
      widget.attachment.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 4 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FutureBuilder<Uint8List>(
              future: _bytes,
              builder:
                  (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const ColoredBox(
                        color: AppColors.cardSoft,
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                      );
                    }
                    final Uint8List? bytes = snapshot.data;
                    if (snapshot.hasError || bytes == null) {
                      return const ColoredBox(
                        color: AppColors.cardSoft,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.muted,
                        ),
                      );
                    }
                    return GestureDetector(
                      onTap: widget.onTap,
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    );
                  },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.attachment.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        Text(
          '${widget.attachment.sizeText} · ${widget.attachment.uploadedByName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 9, color: AppColors.subtleText),
        ),
      ],
    );
  }
}

/// Full-screen pinch-to-zoom pager over every image attachment on a task,
/// starting at the tapped one.
class _TaskImagePager extends StatelessWidget {
  const _TaskImagePager({required this.images, required this.initialIndex});

  final List<TaskAttachment> images;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: images.length,
        itemBuilder: (BuildContext context, int index) =>
            _TaskImagePage(attachment: images[index]),
      ),
    );
  }
}

class _TaskImagePage extends StatefulWidget {
  const _TaskImagePage({required this.attachment});

  final TaskAttachment attachment;

  @override
  State<_TaskImagePage> createState() => _TaskImagePageState();
}

class _TaskImagePageState extends State<_TaskImagePage> {
  late final Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = context.read<TasksService>().attachmentBytes(
      widget.attachment.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        final Uint8List? bytes = snapshot.data;
        if (snapshot.hasError || bytes == null) {
          return const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 40,
            ),
          );
        }
        return Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Image.memory(bytes),
          ),
        );
      },
    );
  }
}

/// One non-image attachment row: downloads the file and opens it with the
/// device's own viewer on tap.
class _FileAttachmentRow extends StatefulWidget {
  const _FileAttachmentRow({required this.attachment});

  final TaskAttachment attachment;

  @override
  State<_FileAttachmentRow> createState() => _FileAttachmentRowState();
}

class _FileAttachmentRowState extends State<_FileAttachmentRow> {
  bool _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final Uint8List bytes = await context
          .read<TasksService>()
          .attachmentBytes(widget.attachment.id);
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/${widget.attachment.fileName}');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFilex.open(file.path);
    } catch (_) {
      if (mounted) {
        showApiSnack(
          context,
          AppLocalizations.of(context).tasksCouldNotOpenAttachment,
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TaskAttachment attachment = widget.attachment;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cardSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.insert_drive_file_outlined,
                size: 20,
                color: AppColors.blue,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      attachment.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '${attachment.sizeText} · ${attachment.uploadedByName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.subtleText,
                      ),
                    ),
                  ],
                ),
              ),
              if (_opening)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.green,
                  ),
                )
              else
                const Icon(
                  Icons.download_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            letterSpacing: 1,
            fontWeight: FontWeight.w800,
            color: AppColors.faintText,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

/// Small coloured pill for [TaskItem.taskCategoryName], with the page name
/// appended for a Page Task (category `3`). Set from the Portal — the app
/// only shows it (2026-10-08 part B).
class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.task});

  final TaskItem task;

  static ToneColor _toneFor(int code) => switch (code) {
    1 => ToneColor.red, // Bug
    2 => ToneColor.green, // New Feature
    3 => ToneColor.blue, // Page Task
    4 => ToneColor.amber, // Improvement
    5 => ToneColor.purple, // Support
    _ => ToneColor.blue,
  };

  @override
  Widget build(BuildContext context) {
    final ToneColor tone = _toneFor(task.taskCategory);
    final String label = task.taskPageName.isEmpty
        ? task.taskCategoryName
        : '${task.taskCategoryName} · ${task.taskPageName}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: tone.foreground,
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    if (task.isDone) {
      return Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: AppColors.green,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.check_rounded, size: 8, color: Colors.white),
      );
    }

    final Color color = task.isOverdue
        ? AppColors.red
        : task.isInProgress
        ? AppColors.amber
        : AppColors.blue;

    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(color: color.withValues(alpha: 0.15), spreadRadius: 4),
        ],
      ),
    );
  }
}
