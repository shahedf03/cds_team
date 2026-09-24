import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/task_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tasks_provider.dart';
import '../widgets/cds_app_bar.dart';
import '../widgets/common.dart';

/// §6 — "CDS Teams Tasks", grouped by project (OSFA, CMMS, ...).
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key, this.embedded = false});

  final bool embedded;

  Future<void> _refresh(BuildContext context) async {
    final AuthProvider auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    await context.read<TasksProvider>().load(userId: auth.user!.userId);
  }

  @override
  Widget build(BuildContext context) {
    final TasksProvider provider = context.watch<TasksProvider>();

    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!embedded) const CdsAppBar(title: 'My tasks'),
        _Summary(done: provider.doneCount, total: provider.tasks.length),
        const SizedBox(height: 22),
        const ListLabel(label: 'Projects'),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.green,
            backgroundColor: Colors.white,
            onRefresh: () => _refresh(context),
            child: _Body(provider: provider, onRetry: () => _refresh(context)),
          ),
        ),
      ],
    );

    if (embedded) {
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

class _Summary extends StatelessWidget {
  const _Summary({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'THIS WEEK',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFAEBBB7),
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Keep the momentum',
                  style: TextStyle(
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
                '/ $total done',
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFFAFBDBA),
                ),
              ),
            ],
          ),
        ],
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
    if (provider.isLoading && provider.tasks.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }

    if (provider.hasError && provider.tasks.isEmpty) {
      return ListView(
        children: <Widget>[
          StateMessage(
            icon: Icons.cloud_off_rounded,
            tone: ToneColor.red,
            title: 'Could not load tasks',
            message: provider.error,
            actionLabel: 'Try again',
            onAction: onRetry,
          ),
        ],
      );
    }

    final List<TaskProject> projects = provider.projects;

    if (projects.isEmpty) {
      return ListView(
        children: const <Widget>[
          StateMessage(
            icon: Icons.task_alt_rounded,
            title: 'No tasks assigned',
            message: 'New work assigned to you will show up here.',
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 100),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: projects.length,
      separatorBuilder: (_, _) => const SizedBox(height: 9),
      itemBuilder: (BuildContext context, int index) => _ProjectCard(
        project: projects[index],
        initiallyExpanded: index == 0,
        tone: index.isEven ? ToneColor.green : ToneColor.amber,
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.initiallyExpanded,
    required this.tone,
  });

  final TaskProject project;
  final bool initiallyExpanded;
  final ToneColor tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xCAFFFFFF),
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.tinyShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(
          context,
        ).copyWith(dividerColor: Colors.transparent, splashColor: Colors.transparent),
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
            '${project.tasks.length} '
            '${project.tasks.length == 1 ? 'task' : 'tasks'}',
            style: const TextStyle(fontSize: 9, color: Color(0xFF899591)),
          ),
          children: project.tasks
              .map((TaskItem task) => _TaskRow(task: task))
              .toList(),
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
    return InkWell(
      onTap: () => _showDetails(context, task),
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
                ],
              ),
            ),
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

  static void _showDetails(BuildContext context, TaskItem task) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (BuildContext context) => SafeArea(
        child: Padding(
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
              Row(
                children: <Widget>[
                  StatusChip(
                    label: task.taskStatusName,
                    tone: task.isDone
                        ? ToneColor.green
                        : task.isInProgress
                        ? ToneColor.amber
                        : ToneColor.blue,
                  ),
                  const SizedBox(width: 8),
                  StatusChip(
                    label: task.deadlineLabel,
                    tone: task.isOverdue ? ToneColor.red : ToneColor.blue,
                    icon: Icons.schedule_rounded,
                  ),
                ],
              ),
              if (task.clientName.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                _DetailLine(label: 'Client', value: task.clientName),
              ],
              if (task.taskDescription.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _DetailLine(label: 'Description', value: task.taskDescription),
              ],
              const SizedBox(height: 10),
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
