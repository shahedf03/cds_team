import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_formats.dart';
import '../../models/transportation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loadable.dart';
import '../../providers/transportation_provider.dart';
import '../../routes/app_routes.dart';
import '../widgets/cds_app_bar.dart';
import '../widgets/common.dart';

/// §4 — list of daily transactions. Create/edit happens in
/// [TransportationEditorScreen]; delete calls the DELETE endpoint.
class TransportationScreen extends StatefulWidget {
  const TransportationScreen({super.key});

  @override
  State<TransportationScreen> createState() => _TransportationScreenState();
}

class _TransportationScreenState extends State<TransportationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransportationProvider>().loadClients();
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final AuthProvider auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    await context.read<TransportationProvider>().load(
      userId: auth.user!.userId,
    );
  }

  Future<void> _pickRange() async {
    final TransportationProvider provider = context
        .read<TransportationProvider>();
    final AuthProvider auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: provider.range.from,
        end: provider.range.to,
      ),
    );
    if (picked == null) return;

    await provider.setRange(
      DateRange(picked.start, picked.end),
      userId: auth.user!.userId,
    );
  }

  Future<void> _openEditor([Transportation? entry]) async {
    final bool? saved = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.transportationEditor,
      arguments: entry,
    );
    if (saved == true && mounted) {
      showApiSnack(context, 'Entry saved.', isError: false);
    }
  }

  /// "Open": fetches the PDF for the open date window and shows it in-app;
  /// Print and Share live inside the viewer.
  Future<void> _openReport() async {
    final AuthProvider auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    final TransportationProvider provider = context
        .read<TransportationProvider>();
    final Uint8List? bytes = await provider.report(
      userId: auth.user!.userId,
      userName: auth.user!.userName,
    );

    if (!mounted) return;
    if (bytes == null) {
      showApiSnack(context, provider.error ?? 'Could not generate the report.');
      return;
    }

    final String filename =
        'transportation_${ApiFormats.toQueryDate(provider.range.from)}'
        '_${ApiFormats.toQueryDate(provider.range.to)}.pdf';
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _ReportViewer(bytes: bytes, filename: filename),
      ),
    );
  }

  Future<void> _confirmDelete(Transportation entry) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete this entry?', style: TextStyle(fontSize: 16)),
        content: Text(
          '${entry.dateLabel} · ${entry.km} km',
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final TransportationProvider provider = context
        .read<TransportationProvider>();
    final bool ok = await provider.delete(entry.trId);

    if (!mounted) return;
    showApiSnack(
      context,
      ok ? 'Entry deleted.' : (provider.error ?? 'Could not delete the entry.'),
      isError: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TransportationProvider provider = context
        .watch<TransportationProvider>();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                CdsAppBar(
                  title: 'Daily expenses',
                  action: provider.isExportingReport
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.green,
                            ),
                          ),
                        )
                      : SoftIconButton(
                          icon: Icons.picture_as_pdf_outlined,
                          tooltip: 'Open report',
                          onPressed: _openReport,
                        ),
                ),
                DateRangePill(
                  fromLabel: ApiFormats.displayDate.format(provider.range.from),
                  toLabel: ApiFormats.displayDate.format(provider.range.to),
                  onTap: _pickRange,
                ),
                const SizedBox(height: 14),
                _Totals(
                  km: provider.totalKm,
                  amount: provider.totalAmount,
                  count: provider.entries.length,
                ),
                const SizedBox(height: 18),
                const ListLabel(label: 'Entries'),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.green,
                    backgroundColor: Colors.white,
                    onRefresh: _refresh,
                    child: _Body(
                      provider: provider,
                      onRetry: _refresh,
                      onEdit: _openEditor,
                      onDelete: _confirmDelete,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

/// In-app PDF viewer; its toolbar carries the Print and Share actions.
class _ReportViewer extends StatelessWidget {
  const _ReportViewer({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: CdsAppBar(title: 'Report'),
              ),
              Expanded(
                child: PdfPreview(
                  build: (_) async => bytes,
                  pdfFileName: filename,
                  allowPrinting: true,
                  allowSharing: true,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({
    required this.km,
    required this.amount,
    required this.count,
  });

  final double km;
  final double amount;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          _Metric(label: 'TOTAL', value: amount.toStringAsFixed(2)),
          const _Divider(),
          _Metric(label: 'DISTANCE', value: '${km.toStringAsFixed(0)} km'),
          const _Divider(),
          _Metric(label: 'ENTRIES', value: '$count'),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
              color: Color(0xFFAEBBB7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8DE1BD),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 28,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: Colors.white24,
  );
}

class _Body extends StatelessWidget {
  const _Body({
    required this.provider,
    required this.onRetry,
    required this.onEdit,
    required this.onDelete,
  });

  final TransportationProvider provider;
  final VoidCallback onRetry;
  final void Function(Transportation) onEdit;
  final void Function(Transportation) onDelete;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.entries.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }

    if (provider.hasError && provider.entries.isEmpty) {
      return ListView(
        children: <Widget>[
          StateMessage(
            icon: Icons.cloud_off_rounded,
            tone: ToneColor.red,
            title: 'Could not load entries',
            message: provider.error,
            actionLabel: 'Try again',
            onAction: onRetry,
          ),
        ],
      );
    }

    if (provider.entries.isEmpty) {
      return ListView(
        children: const <Widget>[
          StateMessage(
            icon: Icons.directions_car_filled_outlined,
            tone: ToneColor.amber,
            title: 'No entries yet',
            message: 'Tap + to log a trip with its KM, clients and total.',
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 100),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: provider.entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final Transportation entry = provider.entries[index];
        return _EntryCard(
          entry: entry,
          onEdit: () => onEdit(entry),
          onDelete: () => onDelete(entry),
        );
      },
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final Transportation entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onEdit,
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.dateLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.km.isEmpty ? '0' : entry.km} km'
                      '${entry.notes.trim().isEmpty ? '' : ' · ${entry.notes.trim()}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF8A9693),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                entry.totalValue.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Delete entry',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
          if (entry.clients.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: entry.clients
                  .map(
                    (TransportationClient c) => StatusChip(
                      label: c.clientName,
                      tone: ToneColor.blue,
                      icon: Icons.business_outlined,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
