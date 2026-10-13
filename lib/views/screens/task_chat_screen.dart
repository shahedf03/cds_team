import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/task_chat.dart';
import '../../models/task_item.dart';
import '../../providers/task_chat_provider.dart';
import '../../services/task_chat_service.dart';
import '../widgets/cds_app_bar.dart';
import '../widgets/common.dart';

/// 2026-10-08 part C — the chat between a task's creator and its assignee.
/// Opens on `afterId=0`, then polls every ~4s while this screen is on
/// screen; closed 1 hour after the task is moved to Done/Delivered.
class TaskChatScreen extends StatelessWidget {
  const TaskChatScreen({super.key, required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TaskChatProvider>(
      create: (BuildContext ctx) => TaskChatProvider(
        service: ctx.read<TaskChatService>(),
        taskId: task.taskId,
      )..start(),
      child: _TaskChatBody(task: task),
    );
  }
}

class _TaskChatBody extends StatefulWidget {
  const _TaskChatBody({required this.task});

  final TaskItem task;

  @override
  State<_TaskChatBody> createState() => _TaskChatBodyState();
}

class _TaskChatBodyState extends State<_TaskChatBody> {
  final ScrollController _scroll = ScrollController();
  int _lastRenderedCount = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final TaskChatProvider chat = context.watch<TaskChatProvider>();

    if (chat.messages.length != _lastRenderedCount) {
      _lastRenderedCount = chat.messages.length;
      _scrollToBottomSoon();
    }

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                CdsAppBar(
                  title: chat.otherUserName.isEmpty
                      ? t.chatTitle
                      : t.chatWith(chat.otherUserName),
                ),
                if (!chat.isOpen) ...<Widget>[
                  _LockedBanner(closesAt: chat.closesAt),
                  const SizedBox(height: 10),
                ],
                Expanded(child: _Messages(chat: chat, scroll: _scroll)),
                _Composer(taskId: widget.task.taskId, locked: !chat.isOpen),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LockedBanner extends StatelessWidget {
  const _LockedBanner({this.closesAt});

  final DateTime? closesAt;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.amberTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.lock_outline_rounded, size: 15, color: AppColors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t.chatLocked,
              style: const TextStyle(fontSize: 11, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _Messages extends StatelessWidget {
  const _Messages({required this.chat, required this.scroll});

  final TaskChatProvider chat;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);

    if (chat.isLoading && chat.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }
    if (chat.error != null && chat.messages.isEmpty) {
      return StateMessage(
        icon: Icons.cloud_off_rounded,
        tone: ToneColor.red,
        title: t.chatCouldNotLoad,
        message: chat.error,
      );
    }
    if (chat.messages.isEmpty) {
      return StateMessage(
        icon: Icons.chat_bubble_outline_rounded,
        title: t.chatEmpty,
        message: t.chatEmptyMsg,
      );
    }

    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: chat.messages.length,
      itemBuilder: (BuildContext context, int index) =>
          _Bubble(message: chat.messages[index]),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool mine = message.isMine;
    final String time = message.sentAt == null
        ? ''
        : DateFormat('HH:mm').format(message.sentAt!);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: mine ? AppColors.green : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.tinyShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (!mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: mine ? Colors.white70 : AppColors.subtleText,
                  ),
                ),
              ),
            for (final ChatFile file in message.files)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _ChatFileBubble(file: file, mine: mine),
              ),
            if (message.body.isNotEmpty)
              Text(
                message.body,
                style: TextStyle(
                  fontSize: 13,
                  color: mine ? Colors.white : AppColors.ink,
                ),
              ),
            const SizedBox(height: 3),
            Text(
              time,
              style: TextStyle(
                fontSize: 9,
                color: mine ? Colors.white70 : AppColors.faintText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatFileBubble extends StatelessWidget {
  const _ChatFileBubble({required this.file, required this.mine});

  final ChatFile file;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    switch (file.kind) {
      case ChatFileKind.image:
        return _ChatImage(file: file);
      case ChatFileKind.audio:
        return _ChatAudio(file: file, mine: mine);
      case ChatFileKind.video:
      case ChatFileKind.file:
        return _ChatFileRow(file: file, mine: mine);
    }
  }
}

class _ChatImage extends StatefulWidget {
  const _ChatImage({required this.file});

  final ChatFile file;

  @override
  State<_ChatImage> createState() => _ChatImageState();
}

class _ChatImageState extends State<_ChatImage> {
  late final Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = context.read<TaskChatService>().fileBytes(widget.file.id);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: FutureBuilder<Uint8List>(
        future: _bytes,
        builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              width: 160,
              height: 120,
              child: ColoredBox(
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
              ),
            );
          }
          final Uint8List? bytes = snapshot.data;
          if (snapshot.hasError || bytes == null) {
            return const SizedBox(
              width: 160,
              height: 120,
              child: ColoredBox(
                color: AppColors.cardSoft,
                child: Icon(Icons.broken_image_outlined, color: AppColors.muted),
              ),
            );
          }
          return GestureDetector(
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => _FullscreenImage(bytes: bytes),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200, maxHeight: 220),
              child: Image.memory(bytes, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}

class _FullscreenImage extends StatelessWidget {
  const _FullscreenImage({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.memory(bytes),
        ),
      ),
    );
  }
}

/// Voice message bubble: downloads the audio once, then plays/pauses from
/// the local temp file.
class _ChatAudio extends StatefulWidget {
  const _ChatAudio({required this.file, required this.mine});

  final ChatFile file;
  final bool mine;

  @override
  State<_ChatAudio> createState() => _ChatAudioState();
}

class _ChatAudioState extends State<_ChatAudio> {
  final AudioPlayer _player = AudioPlayer();
  String? _localPath;
  bool _loading = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((PlayerState state) {
      if (!mounted) return;
      setState(() => _playing = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      return;
    }
    if (_localPath == null) {
      setState(() => _loading = true);
      try {
        final Uint8List bytes = await context
            .read<TaskChatService>()
            .fileBytes(widget.file.id);
        final Directory dir = await getTemporaryDirectory();
        final File file = File('${dir.path}/chat_${widget.file.id}.audio');
        await file.writeAsBytes(bytes, flush: true);
        _localPath = file.path;
      } catch (_) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      if (mounted) setState(() => _loading = false);
    }
    await _player.play(DeviceFileSource(_localPath!));
  }

  @override
  Widget build(BuildContext context) {
    final Color fg = widget.mine ? Colors.white : AppColors.ink;
    final int? seconds = widget.file.durationSeconds;
    final String durationText = seconds == null
        ? ''
        : '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return SizedBox(
      width: 170,
      child: Row(
        children: <Widget>[
          InkWell(
            onTap: _loading ? null : _toggle,
            borderRadius: BorderRadius.circular(99),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: _loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                    )
                  : Icon(
                      _playing
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      size: 28,
                      color: fg,
                    ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.graphic_eq_rounded, size: 16, color: fg.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text(durationText, style: TextStyle(fontSize: 11, color: fg)),
        ],
      ),
    );
  }
}

/// Video / generic file bubble: downloads then opens with the device's own
/// viewer, same pattern as the task attachments list.
class _ChatFileRow extends StatefulWidget {
  const _ChatFileRow({required this.file, required this.mine});

  final ChatFile file;
  final bool mine;

  @override
  State<_ChatFileRow> createState() => _ChatFileRowState();
}

class _ChatFileRowState extends State<_ChatFileRow> {
  bool _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final Uint8List bytes = await context
          .read<TaskChatService>()
          .fileBytes(widget.file.id);
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/${widget.file.fileName}');
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
    final Color fg = widget.mine ? Colors.white : AppColors.ink;
    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 190,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: widget.mine
              ? Colors.white.withValues(alpha: 0.14)
              : AppColors.cardSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              widget.file.kind == ChatFileKind.video
                  ? Icons.videocam_outlined
                  : Icons.insert_drive_file_outlined,
              size: 18,
              color: fg,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.file.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
                  ),
                  Text(
                    widget.file.sizeText,
                    style: TextStyle(fontSize: 9, color: fg.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            if (_opening)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            else
              Icon(Icons.download_rounded, size: 16, color: fg.withValues(alpha: 0.8)),
          ],
        ),
      ),
    );
  }
}

/// Text box + attach + record + Send, disabled with [locked]'s message when
/// the chat isn't open.
class _Composer extends StatefulWidget {
  const _Composer({required this.taskId, required this.locked});

  final String taskId;
  final bool locked;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final TextEditingController _controller = TextEditingController();
  final List<PendingChatFile> _pending = <PendingChatFile>[];
  final AudioRecorder _recorder = AudioRecorder();
  bool _busy = false;
  bool _recording = false;
  int _recordSeconds = 0;
  String? _recordPath;

  @override
  void dispose() {
    _controller.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;
    setState(() {
      for (final PlatformFile f in result.files) {
        final Uint8List? bytes = f.bytes;
        if (bytes != null) {
          _pending.add(PendingChatFile(fileName: f.name, bytes: bytes));
        }
      }
      if (_pending.length > 5) _pending.removeRange(0, _pending.length - 5);
    });
  }

  Future<void> _toggleRecording() async {
    final AppLocalizations t = AppLocalizations.of(context);
    if (_recording) {
      final String? path = await _recorder.stop();
      setState(() => _recording = false);
      if (path == null) return;
      final int seconds = _recordSeconds;
      try {
        final Uint8List bytes = await File(path).readAsBytes();
        if (!mounted) return;
        setState(() => _busy = true);
        final String? error = await context.read<TaskChatProvider>().sendFiles(
          files: <PendingChatFile>[
            PendingChatFile(fileName: 'voice_message.m4a', bytes: bytes),
          ],
          durationSeconds: seconds,
        );
        if (mounted && error != null) showApiSnack(context, error);
      } catch (_) {
        if (mounted) showApiSnack(context, t.chatCouldNotSend);
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) showApiSnack(context, t.chatMicPermissionDenied);
        return;
      }
      final Directory dir = await getTemporaryDirectory();
      _recordPath =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _recordPath!,
      );
      setState(() {
        _recording = true;
        _recordSeconds = 0;
      });
      _tickRecording();
    } catch (_) {
      if (mounted) showApiSnack(context, t.chatCouldNotRecord);
    }
  }

  void _tickRecording() {
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (!mounted || !_recording) return;
      setState(() => _recordSeconds++);
      _tickRecording();
    });
  }

  void _removeFile(int index) => setState(() => _pending.removeAt(index));

  Future<void> _send() async {
    final String text = _controller.text.trim();
    if (text.isEmpty && _pending.isEmpty) return;

    setState(() => _busy = true);
    final TaskChatProvider chat = context.read<TaskChatProvider>();
    final String? error = _pending.isEmpty
        ? await chat.send(text)
        : await chat.sendFiles(
            files: List<PendingChatFile>.of(_pending),
            body: text.isEmpty ? null : text,
          );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      showApiSnack(context, error);
      return;
    }
    _controller.clear();
    setState(_pending.clear);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);

    if (widget.locked) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          t.chatLocked,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.subtleText),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_pending.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    for (final (int i, PendingChatFile f) in _pending.indexed)
                      _PendingFileChip(
                        name: f.fileName,
                        onRemove: () => _removeFile(i),
                      ),
                  ],
                ),
              ),
            if (_recording)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  t.chatRecording(
                    '${_recordSeconds ~/ 60}:${(_recordSeconds % 60).toString().padLeft(2, '0')}',
                  ),
                  style: const TextStyle(fontSize: 11, color: AppColors.red),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                SoftIconButton(
                  icon: Icons.attach_file_rounded,
                  tooltip: t.chatAttach,
                  onPressed: _busy || _recording ? null : _pickFiles,
                ),
                const SizedBox(width: 6),
                SoftIconButton(
                  icon: _recording ? Icons.stop_circle_rounded : Icons.mic_none_rounded,
                  tooltip: _recording ? t.chatStopRecording : t.chatRecordVoice,
                  onPressed: _busy ? null : _toggleRecording,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 40, maxHeight: 110),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.line),
                    ),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      enabled: !_recording,
                      decoration: InputDecoration(
                        hintText: t.chatTypeMessage,
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _busy
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.green,
                          ),
                        ),
                      )
                    : SoftIconButton(
                        icon: Icons.send_rounded,
                        tooltip: t.commonSend,
                        onPressed: _recording ? null : _send,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingFileChip extends StatelessWidget {
  const _PendingFileChip({required this.name, required this.onRemove});

  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.ink),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
