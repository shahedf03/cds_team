import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/project.dart';
import '../../models/task_item.dart';
import '../../services/projects_service.dart';
import '../widgets/brand_logo.dart';
import '../widgets/cds_app_bar.dart';
import '../widgets/common.dart';
import 'tasks_screen.dart' show showTaskDetails;

/// 2026-10-08 part D — projects split into sprints. Read-only: creating,
/// editing and deleting a sprint (`canManage`) isn't built here yet.
class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  late Future<List<ProjectSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ProjectsService>().list();
  }

  Future<void> _refresh() async {
    final Future<List<ProjectSummary>> next = context.read<ProjectsService>().list();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                CdsAppBar(title: t.projectsTitle),
                const SizedBox(height: 10),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.green,
                    backgroundColor: Colors.white,
                    onRefresh: _refresh,
                    child: FutureBuilder<List<ProjectSummary>>(
                      future: _future,
                      builder: (BuildContext context, AsyncSnapshot<List<ProjectSummary>> snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.green));
                        }
                        if (snap.hasError) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: <Widget>[
                              StateMessage(
                                icon: Icons.cloud_off_rounded,
                                tone: ToneColor.red,
                                title: t.projectsCouldNotLoad,
                                message: snap.error.toString(),
                                actionLabel: t.commonTryAgain,
                                onAction: _refresh,
                              ),
                            ],
                          );
                        }
                        final List<ProjectSummary> projects = snap.data ?? const <ProjectSummary>[];
                        if (projects.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: <Widget>[StateMessage(icon: Icons.folder_open_outlined, title: t.projectsEmpty)],
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 100),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: projects.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (BuildContext context, int i) => _ProjectCard(project: projects[i]),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project});

  final ProjectSummary project;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final double rate = (project.progress.clamp(0, 100)) / 100;
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => ProjectDetailScreen(code: project.code, name: project.name)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  project.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
              SizedBox(
                width: 34,
                height: 34,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    CircularProgressIndicator(
                      value: rate,
                      strokeWidth: 4,
                      backgroundColor: AppColors.line,
                      color: AppColors.green,
                    ),
                    Text('${project.progress}%', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              _MiniStat(label: t.projectsDone, value: project.doneCount, color: AppColors.green),
              _MiniStat(label: t.projectsWorking, value: project.workingCount, color: AppColors.amber),
              _MiniStat(label: t.projectsOpen, value: project.openCount, color: AppColors.blue),
              if (project.overdueCount > 0)
                _MiniStat(label: t.projectsOverdue, value: project.overdueCount, color: AppColors.red),
            ],
          ),
          if (project.activeSprint != null) ...<Widget>[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: AppColors.greenTint, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.bolt_rounded, size: 14, color: AppColors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      project.activeSprint!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                  ),
                  if (project.activeSprint!.daysLeft != null)
                    Text(
                      t.projectsDaysLeft(project.activeSprint!.daysLeft!),
                      style: const TextStyle(fontSize: 10, color: AppColors.subtleText),
                    ),
                ],
              ),
            ),
          ],
          if (project.team.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            SizedBox(
              height: 26,
              child: Stack(
                children: <Widget>[
                  for (final (int i, ProjectTeamMember m) in project.team.take(6).indexed)
                    Positioned(
                      left: i * 18.0,
                      child: UserAvatar(initials: _initialsOf(m.name), size: 26),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _initialsOf(String name) =>
      name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase();
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$value $label', style: const TextStyle(fontSize: 9, color: AppColors.subtleText)),
      ],
    );
  }
}

/// A project's sprints (newest first, Active one open) and the tasks with
/// no sprint. Tap a task to open the usual details sheet.
class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.code, required this.name});

  final String code;
  final String name;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Future<ProjectDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ProjectsService>().detail(widget.code);
  }

  Future<void> _refresh() async {
    final Future<ProjectDetail> next = context.read<ProjectsService>().detail(widget.code);
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                CdsAppBar(title: widget.name),
                const SizedBox(height: 6),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.green,
                    backgroundColor: Colors.white,
                    onRefresh: _refresh,
                    child: FutureBuilder<ProjectDetail>(
                      future: _future,
                      builder: (BuildContext context, AsyncSnapshot<ProjectDetail> snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.green));
                        }
                        if (snap.hasError) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: <Widget>[
                              StateMessage(
                                icon: Icons.cloud_off_rounded,
                                tone: ToneColor.red,
                                title: t.projectsCouldNotLoad,
                                message: snap.error.toString(),
                                actionLabel: t.commonTryAgain,
                                onAction: _refresh,
                              ),
                            ],
                          );
                        }
                        final ProjectDetail detail = snap.data!;
                        return ListView(
                          padding: const EdgeInsets.only(bottom: 100),
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: <Widget>[
                            for (final Sprint sprint in detail.sprints)
                              _SprintSection(sprint: sprint, initiallyExpanded: sprint.isActive),
                            if (detail.noSprintTasks.isNotEmpty)
                              _SprintSection(
                                sprint: Sprint(id: 0, name: t.projectsNoSprint, tasks: detail.noSprintTasks),
                                initiallyExpanded: detail.sprints.isEmpty,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SprintSection extends StatelessWidget {
  const _SprintSection({required this.sprint, required this.initiallyExpanded});

  final Sprint sprint;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final String dates = sprint.startDate == null || sprint.endDate == null
        ? ''
        : '${DateFormat('d MMM').format(sprint.startDate!)} – ${DateFormat('d MMM').format(sprint.endDate!)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xCAFFFFFF),
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            title: Text(sprint.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            subtitle: dates.isEmpty && sprint.state.isEmpty
                ? null
                : Text(
                    <String>[sprint.state, dates].where((String s) => s.isNotEmpty).join(' · '),
                    style: const TextStyle(fontSize: 9, color: AppColors.subtleText),
                  ),
            trailing: Text('${sprint.progress}%', style: const TextStyle(fontSize: 11, color: AppColors.green)),
            children: sprint.tasks.isEmpty
                ? <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(t.projectsSprintEmpty, style: const TextStyle(fontSize: 11, color: AppColors.subtleText)),
                    ),
                  ]
                : sprint.tasks
                    .map(
                      (TaskItem task) => ListTile(
                        dense: true,
                        onTap: () => showTaskDetails(context, task),
                        title: Text(task.taskTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                        subtitle: Text(task.taskStatusName, style: const TextStyle(fontSize: 9)),
                        trailing: Icon(
                          task.isDone ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                          size: 16,
                          color: task.isDone ? AppColors.green : AppColors.muted,
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
    );
  }
}
