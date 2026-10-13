import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/task_item.dart';
import '../../services/tasks_service.dart';
import '../widgets/cds_app_bar.dart';
import '../widgets/common.dart';
import 'tasks_screen.dart' show TaskProjectCard;

/// 2026-10-08 part B — the list behind the dashboard's "منجزة هذا الشهر"
/// card: `GET /api/tasks/finished` (my tasks moved to Done/Delivered this
/// month, even if opened earlier), grouped by project and rendered with the
/// same row widget as the main Tasks screen.
class FinishedTasksScreen extends StatefulWidget {
  const FinishedTasksScreen({super.key});

  @override
  State<FinishedTasksScreen> createState() => _FinishedTasksScreenState();
}

class _FinishedTasksScreenState extends State<FinishedTasksScreen> {
  late Future<List<TaskItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<TasksService>().finished();
  }

  Future<void> _refresh() async {
    final Future<List<TaskItem>> next = context.read<TasksService>().finished();
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
                CdsAppBar(title: t.tasksFinishedTitle),
                const SizedBox(height: 14),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.green,
                    backgroundColor: Colors.white,
                    onRefresh: _refresh,
                    child: FutureBuilder<List<TaskItem>>(
                      future: _future,
                      builder:
                          (
                            BuildContext context,
                            AsyncSnapshot<List<TaskItem>> snapshot,
                          ) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.green,
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: <Widget>[
                                  StateMessage(
                                    icon: Icons.cloud_off_rounded,
                                    tone: ToneColor.red,
                                    title: t.tasksCouldNotLoad,
                                    message: snapshot.error.toString(),
                                    actionLabel: t.commonTryAgain,
                                    onAction: _refresh,
                                  ),
                                ],
                              );
                            }

                            final List<TaskProject> projects =
                                TaskProject.groupByProject(
                                  snapshot.data ?? const <TaskItem>[],
                                );
                            if (projects.isEmpty) {
                              return ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: <Widget>[
                                  StateMessage(
                                    icon: Icons.task_alt_rounded,
                                    title: t.tasksFinishedEmpty,
                                    message: t.tasksFinishedEmptyMsg,
                                  ),
                                ],
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.only(bottom: 100),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: projects.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 9),
                              itemBuilder:
                                  (BuildContext context, int index) =>
                                      TaskProjectCard(
                                        project: projects[index],
                                        initiallyExpanded: index == 0,
                                        tone: index.isEven
                                            ? ToneColor.green
                                            : ToneColor.amber,
                                      ),
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
