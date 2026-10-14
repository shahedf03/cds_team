import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
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
import '../widgets/brand_logo.dart';
import '../widgets/common.dart';
import '../widgets/skeleton.dart';

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

String _initials(String name) {
  final List<String> parts = name.trim().split(RegExp(r'\s+')).where((String s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
}

bool _sameDay(DateTime? a, DateTime? b) =>
    a != null && b != null && a.year == b.year && a.month == b.month && a.day == b.day;

class _TaskChatBody extends StatefulWidget {
  const _TaskChatBody({required this.task});

  final TaskItem task;

  @override
  State<_TaskChatBody> createState() => _TaskChatBodyState();
}

class _TaskChatBodyState extends State<_TaskChatBody> {
  final ScrollController _scroll = ScrollController();
  int _lastRenderedCount = 0;
  bool _showJump = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final bool away = _scroll.position.maxScrollExtent - _scroll.offset > 320;
    if (away != _showJump) setState(() => _showJump = away);
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final double target = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(target, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
      } else {
        _scroll.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final TaskChatProvider chat = context.watch<TaskChatProvider>();

    if (chat.messages.length != _lastRenderedCount) {
      // First paint jumps straight to the latest message; later ones glide.
      final bool first = _lastRenderedCount == 0;
      _lastRenderedCount = chat.messages.length;
      _scrollToBottom(animate: !first);
    }

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _ChatHeader(chat: chat, task: widget.task),
              Expanded(
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(child: _Messages(chat: chat, scroll: _scroll)),
                    PositionedDirectional(
                      end: 16,
                      bottom: 12,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        scale: _showJump ? 1 : 0,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
                          elevation: 3,
                          shadowColor: const Color(0x3325333B),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _scrollToBottom(),
                            child: const SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.ink),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _Composer(locked: !chat.isOpen, onSent: _scrollToBottom),
            ],
          ),
        ),
      ),
    );
  }
}

/// Back · avatar with presence dot · name and task title.
class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.chat, required this.task});

  final TaskChatProvider chat;
  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final String name = chat.otherUserName.isEmpty ? t.chatTitle : chat.otherUserName;
    final DateTime? closesAt = chat.closesAt;

    final (String subtitle, Color subtitleColor) = !chat.isOpen
        ? (t.chatLocked, AppColors.amber)
        : closesAt != null
            ? (t.chatLocksAt(DateFormat('HH:mm').format(closesAt)), AppColors.amber)
            : (task.taskTitle, AppColors.subtleText);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x80E4ECE9))),
      ),
      child: Row(
        children: <Widget>[
          SoftIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: t.commonBack,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              UserAvatar(initials: _initials(name), size: 40),
              PositionedDirectional(
                end: -1,
                bottom: -1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: chat.isOpen ? AppColors.green : AppColors.faintText,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    if (!chat.isOpen || closesAt != null) ...<Widget>[
                      Icon(
                        chat.isOpen ? Icons.timer_outlined : Icons.lock_outline_rounded,
                        size: 12,
                        color: subtitleColor,
                      ),
                      const SizedBox(width: 3),
                    ],
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subtitleColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Messages extends StatefulWidget {
  const _Messages({required this.chat, required this.scroll});

  final TaskChatProvider chat;
  final ScrollController scroll;

  @override
  State<_Messages> createState() => _MessagesState();
}

class _MessagesState extends State<_Messages> {
  /// Ids already on screen once — only messages that arrive later animate in.
  final Set<int> _seen = <int>{};
  bool _primed = false;

  static const Duration _groupGap = Duration(minutes: 3);

  bool _grouped(ChatMessage a, ChatMessage b) {
    if (a.isMine != b.isMine || !_sameDay(a.sentAt, b.sentAt)) return false;
    final DateTime? x = a.sentAt;
    final DateTime? y = b.sentAt;
    return x != null && y != null && y.difference(x).abs() <= _groupGap;
  }

  String _dayLabel(AppLocalizations t, String locale, DateTime d) {
    final DateTime now = DateTime.now();
    if (_sameDay(d, now)) return t.calendarToday;
    if (_sameDay(d, DateTime(now.year, now.month, now.day - 1))) return t.chatYesterday;
    return DateFormat(d.year == now.year ? 'EEEE, d MMMM' : 'd MMMM yyyy', locale).format(d);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final TaskChatProvider chat = widget.chat;
    final List<ChatMessage> messages = chat.messages;

    if (chat.isLoading && messages.isEmpty) return const SkeletonChat();
    if (chat.error != null && messages.isEmpty) {
      return StateMessage(
        icon: Icons.cloud_off_rounded,
        tone: ToneColor.red,
        title: t.chatCouldNotLoad,
        message: chat.error,
      );
    }
    if (messages.isEmpty) {
      return StateMessage(
        icon: Icons.forum_outlined,
        title: t.chatEmpty,
        message: t.chatEmptyMsg,
      );
    }

    if (!_primed) {
      _seen.addAll(messages.map((ChatMessage m) => m.id));
      _primed = true;
    }

    // Flatten into day separators + messages.
    final List<Object> rows = <Object>[];
    for (int i = 0; i < messages.length; i++) {
      final ChatMessage m = messages[i];
      final DateTime? d = m.sentAt;
      if (d != null && (i == 0 || !_sameDay(messages[i - 1].sentAt, d))) rows.add(d);
      rows.add(i);
    }

    return ListView.builder(
      controller: widget.scroll,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: rows.length,
      itemBuilder: (BuildContext context, int index) {
        final Object row = rows[index];
        if (row is DateTime) return _DaySeparator(label: _dayLabel(t, locale, row));

        final int i = row as int;
        final ChatMessage m = messages[i];
        final bool groupedPrev = i > 0 && _grouped(messages[i - 1], m);
        final bool groupedNext = i < messages.length - 1 && _grouped(m, messages[i + 1]);
        final bool isNew = _seen.add(m.id);

        final Widget bubble = Padding(
          padding: EdgeInsets.only(top: groupedPrev ? 2 : 10),
          child: _Bubble(message: m, groupedPrev: groupedPrev, groupedNext: groupedNext),
        );
        if (!isNew) return bubble;
        return TweenAnimationBuilder<double>(
          key: ValueKey<int>(m.id),
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, double v, Widget? child) => Opacity(
            opacity: v,
            child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child),
          ),
          child: bubble,
        );
      },
    );
  }
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.line),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.subtleText),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.groupedPrev, required this.groupedNext});

  final ChatMessage message;
  final bool groupedPrev;
  final bool groupedNext;

  void _copy(BuildContext context) {
    if (message.body.isEmpty) return;
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: message.body));
    showApiSnack(context, AppLocalizations.of(context).chatCopied, isError: false);
  }

  @override
  Widget build(BuildContext context) {
    final bool mine = message.isMine;
    final String time = message.sentAt == null ? '' : DateFormat('HH:mm').format(message.sentAt!);
    final bool imageOnly = message.body.isEmpty &&
        message.files.isNotEmpty &&
        message.files.every((ChatFile f) => f.kind == ChatFileKind.image);

    // Corners on the sender's side tighten where messages stack; the last
    // one in a run gets the small "tail" corner.
    const Radius big = Radius.circular(18);
    const Radius joined = Radius.circular(6);
    const Radius tail = Radius.circular(4);
    final BorderRadiusDirectional radius = mine
        ? BorderRadiusDirectional.only(
            topStart: big,
            bottomStart: big,
            topEnd: groupedPrev ? joined : big,
            bottomEnd: groupedNext ? joined : tail,
          )
        : BorderRadiusDirectional.only(
            topEnd: big,
            bottomEnd: big,
            topStart: groupedPrev ? joined : big,
            bottomStart: groupedNext ? joined : tail,
          );
    final BorderRadius resolved = radius.resolve(Directionality.of(context));

    final Color fg = mine ? Colors.white : AppColors.ink;
    final Color meta = mine ? Colors.white.withValues(alpha: 0.75) : AppColors.faintText;

    Widget content;
    if (imageOnly) {
      content = Stack(
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final ChatFile f in message.files)
                Padding(
                  padding: EdgeInsets.only(bottom: f == message.files.last ? 0 : 3),
                  child: _ChatImage(file: f),
                ),
            ],
          ),
          PositionedDirectional(
            end: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: const Color(0x8C000000), borderRadius: BorderRadius.circular(99)),
              child: Text(time, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final ChatFile file in message.files)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: switch (file.kind) {
                  ChatFileKind.image => ClipRRect(borderRadius: BorderRadius.circular(12), child: _ChatImage(file: file)),
                  ChatFileKind.audio => _ChatAudio(file: file, mine: mine),
                  ChatFileKind.video || ChatFileKind.file => _ChatFileRow(file: file, mine: mine),
                },
              ),
            if (message.files.isEmpty)
              // Time sits on the last line's trailing edge when it fits.
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 8,
                children: <Widget>[
                  Text(message.body, style: TextStyle(fontSize: 14, height: 1.35, color: fg)),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(time, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: meta)),
                  ),
                ],
              )
            else ...<Widget>[
              if (message.body.isNotEmpty)
                Text(message.body, style: TextStyle(fontSize: 14, height: 1.35, color: fg)),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(time, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: meta)),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Align(
      alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: GestureDetector(
          onLongPress: () => _copy(context),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: mine ? AppColors.green : Colors.white,
              borderRadius: resolved,
              border: mine ? null : Border.all(color: AppColors.line),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: Color(0x0F25333B), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: content,
          ),
        ),
      ),
    );
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
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Shimmer(child: Bone(width: 220, height: 180, radius: 0));
        }
        final Uint8List? bytes = snapshot.data;
        if (snapshot.hasError || bytes == null) {
          return const SizedBox(
            width: 220,
            height: 140,
            child: ColoredBox(
              color: AppColors.cream,
              child: Icon(Icons.broken_image_outlined, color: AppColors.muted),
            ),
          );
        }
        return GestureDetector(
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: (_) => _FullscreenImage(bytes: bytes)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240, maxHeight: 280, minWidth: 140),
            child: Image.memory(bytes, fit: BoxFit.cover),
          ),
        );
      },
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

/// Voice message: play button + waveform that fills as it plays. Downloads
/// once, then plays from a temp file.
class _ChatAudio extends StatefulWidget {
  const _ChatAudio({required this.file, required this.mine});

  final ChatFile file;
  final bool mine;

  @override
  State<_ChatAudio> createState() => _ChatAudioState();
}

class _ChatAudioState extends State<_ChatAudio> {
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subs = <StreamSubscription<dynamic>>[];
  String? _localPath;
  bool _loading = false;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration? _duration;

  @override
  void initState() {
    super.initState();
    _subs
      ..add(_player.onPlayerStateChanged.listen((PlayerState s) {
        if (!mounted) return;
        setState(() {
          _playing = s == PlayerState.playing;
          if (s == PlayerState.completed) _position = Duration.zero;
        });
      }))
      ..add(_player.onPositionChanged.listen((Duration p) {
        if (mounted) setState(() => _position = p);
      }))
      ..add(_player.onDurationChanged.listen((Duration d) {
        if (mounted) setState(() => _duration = d);
      }));
  }

  @override
  void dispose() {
    for (final StreamSubscription<dynamic> s in _subs) {
      s.cancel();
    }
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
        final Uint8List bytes = await context.read<TaskChatService>().fileBytes(widget.file.id);
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

  static String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final bool mine = widget.mine;
    final Duration total = _duration ??
        (widget.file.durationSeconds == null ? Duration.zero : Duration(seconds: widget.file.durationSeconds!));
    final double progress =
        total.inMilliseconds == 0 ? 0 : (_position.inMilliseconds / total.inMilliseconds).clamp(0, 1);
    final Color played = mine ? Colors.white : AppColors.green;
    final Color rest = mine ? Colors.white.withValues(alpha: 0.4) : AppColors.line;

    // Stable pseudo-waveform per file.
    final int seed = widget.file.id.hashCode;
    const int bars = 26;

    return SizedBox(
      width: 210,
      child: Row(
        children: <Widget>[
          Material(
            color: mine ? Colors.white : AppColors.green,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _loading ? null : _toggle,
              child: SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: _loading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: mine ? AppColors.green : Colors.white,
                          ),
                        )
                      : Icon(
                          _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 22,
                          color: mine ? AppColors.green : Colors.white,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  height: 24,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      for (int i = 0; i < bars; i++)
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 2.5,
                              height: 5 + ((seed >> (i % 16)) ^ (i * 7)).abs() % 17,
                              decoration: BoxDecoration(
                                color: (i + 0.5) / bars <= progress ? played : rest,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _fmt(_playing || _position > Duration.zero ? _position : total),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: mine ? Colors.white.withValues(alpha: 0.85) : AppColors.subtleText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Video / generic file: opens with the device's own viewer.
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
      final Uint8List bytes = await context.read<TaskChatService>().fileBytes(widget.file.id);
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/${widget.file.fileName}');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFilex.open(file.path);
    } catch (_) {
      if (mounted) {
        showApiSnack(context, AppLocalizations.of(context).tasksCouldNotOpenAttachment);
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool mine = widget.mine;
    final Color fg = mine ? Colors.white : AppColors.ink;
    final String name = widget.file.fileName;
    final int dot = name.lastIndexOf('.');
    final String ext = dot > 0 && dot < name.length - 1 ? name.substring(dot + 1).toUpperCase() : '';
    final bool video = widget.file.kind == ChatFileKind.video;

    return Material(
      color: mine ? Colors.white.withValues(alpha: 0.16) : AppColors.cream,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: mine ? Colors.white : (video ? AppColors.purpleTint : AppColors.blueTint),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: video || ext.isEmpty || ext.length > 4
                      ? Icon(
                          video ? Icons.play_circle_outline_rounded : Icons.insert_drive_file_outlined,
                          size: 20,
                          color: mine ? AppColors.green : (video ? AppColors.purple : AppColors.blue),
                        )
                      : Text(
                          ext,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: mine ? AppColors.green : AppColors.blue,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.file.sizeText,
                      style: TextStyle(fontSize: 10, color: fg.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (_opening)
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
              else
                Icon(Icons.download_rounded, size: 18, color: fg.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Input pill (attach · text) + one round action button that is Mic when
/// empty and Send once there's something to send; recording swaps the pill
/// for a live recording bar with cancel.
class _Composer extends StatefulWidget {
  const _Composer({required this.locked, required this.onSent});

  final bool locked;
  final VoidCallback onSent;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final TextEditingController _controller = TextEditingController();
  final List<PendingChatFile> _pending = <PendingChatFile>[];
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _ticker;
  bool _busy = false;
  bool _recording = false;
  int _recordSeconds = 0;

  bool get _hasContent => _controller.text.trim().isNotEmpty || _pending.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final FilePickerResult? result = await FilePicker.pickFiles(allowMultiple: true, withData: true);
    if (result == null) return;
    setState(() {
      for (final PlatformFile f in result.files) {
        final Uint8List? bytes = f.bytes;
        if (bytes != null) _pending.add(PendingChatFile(fileName: f.name, bytes: bytes));
      }
      if (_pending.length > 5) _pending.removeRange(0, _pending.length - 5);
    });
  }

  Future<void> _startRecording() async {
    final AppLocalizations t = AppLocalizations.of(context);
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) showApiSnack(context, t.chatMicPermissionDenied);
        return;
      }
      final Directory dir = await getTemporaryDirectory();
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
      unawaited(HapticFeedback.mediumImpact());
      setState(() {
        _recording = true;
        _recordSeconds = 0;
      });
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordSeconds++);
      });
    } catch (_) {
      if (mounted) showApiSnack(context, t.chatCouldNotRecord);
    }
  }

  Future<void> _cancelRecording() async {
    _ticker?.cancel();
    await _recorder.cancel();
    unawaited(HapticFeedback.lightImpact());
    if (mounted) setState(() => _recording = false);
  }

  Future<void> _sendRecording() async {
    final AppLocalizations t = AppLocalizations.of(context);
    _ticker?.cancel();
    final String? path = await _recorder.stop();
    final int seconds = _recordSeconds;
    setState(() => _recording = false);
    if (path == null) return;
    try {
      final Uint8List bytes = await File(path).readAsBytes();
      if (!mounted) return;
      setState(() => _busy = true);
      final String? error = await context.read<TaskChatProvider>().sendFiles(
        files: <PendingChatFile>[PendingChatFile(fileName: 'voice_message.m4a', bytes: bytes)],
        durationSeconds: seconds,
      );
      if (!mounted) return;
      if (error != null) {
        showApiSnack(context, error);
      } else {
        widget.onSent();
      }
    } catch (_) {
      if (mounted) showApiSnack(context, t.chatCouldNotSend);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final String text = _controller.text.trim();
    if (text.isEmpty && _pending.isEmpty) return;

    setState(() => _busy = true);
    final TaskChatProvider chat = context.read<TaskChatProvider>();
    final String? error = _pending.isEmpty
        ? await chat.send(text)
        : await chat.sendFiles(files: List<PendingChatFile>.of(_pending), body: text.isEmpty ? null : text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      showApiSnack(context, error);
      return;
    }
    _controller.clear();
    setState(_pending.clear);
    widget.onSent();
  }

  void _onAction() {
    if (_busy) return;
    if (_recording) {
      _sendRecording();
    } else if (_hasContent) {
      _send();
    } else {
      _startRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);

    if (widget.locked) {
      return Container(
        decoration: const BoxDecoration(
          color: Color(0xF2FFFFFF),
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.amber),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    t.chatLocked,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.subtleText),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final IconData actionIcon = _recording || _hasContent ? Icons.send_rounded : Icons.mic_rounded;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF2FFFFFF),
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: _pending.isEmpty
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _pending.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 6),
                            itemBuilder: (_, int i) => _PendingFileChip(
                              name: _pending[i].fileName,
                              tooltip: t.chatRemoveFile,
                              onRemove: () => setState(() => _pending.removeAt(i)),
                            ),
                          ),
                        ),
                      ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (Widget child, Animation<double> a) =>
                          FadeTransition(opacity: a, child: SizeTransition(sizeFactor: a, axis: Axis.horizontal, child: child)),
                      child: _recording
                          ? _RecordingBar(
                              key: const ValueKey<String>('rec'),
                              seconds: _recordSeconds,
                              label: t.chatRecording(''),
                              cancelTooltip: t.commonCancel,
                              onCancel: _cancelRecording,
                            )
                          : _InputPill(
                              key: const ValueKey<String>('input'),
                              controller: _controller,
                              hint: t.chatTypeMessage,
                              attachTooltip: t.chatAttach,
                              onAttach: _busy ? null : _pickFiles,
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: _recording
                        ? t.chatStopRecording
                        : _hasContent
                            ? t.commonSend
                            : t.chatRecordVoice,
                    child: Material(
                      color: AppColors.green,
                      shape: const CircleBorder(),
                      elevation: 0,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _onAction,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    transitionBuilder: (Widget c, Animation<double> a) =>
                                        ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
                                    child: Icon(
                                      actionIcon,
                                      key: ValueKey<IconData>(actionIcon),
                                      size: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputPill extends StatelessWidget {
  const _InputPill({
    super.key,
    required this.controller,
    required this.hint,
    required this.attachTooltip,
    required this.onAttach,
  });

  final TextEditingController controller;
  final String hint;
  final String attachTooltip;
  final VoidCallback? onAttach;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          IconButton(
            onPressed: onAttach,
            tooltip: attachTooltip,
            icon: Transform.rotate(
              angle: 0.6,
              child: const Icon(Icons.attach_file_rounded, size: 21, color: AppColors.subtleText),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 14, height: 1.35, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 14, color: AppColors.faintText),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsetsDirectional.fromSTEB(0, 14, 14, 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingBar extends StatelessWidget {
  const _RecordingBar({
    super.key,
    required this.seconds,
    required this.label,
    required this.cancelTooltip,
    required this.onCancel,
  });

  final int seconds;
  final String label;
  final String cancelTooltip;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final String time = '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.redTint.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.redTint),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onCancel,
            tooltip: cancelTooltip,
            icon: const Icon(Icons.delete_outline_rounded, size: 21, color: AppColors.red),
          ),
          const _PulsingDot(),
          const SizedBox(width: 8),
          Text(
            time,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.subtleText),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.25, end: 1).animate(_c),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
      ),
    );
  }
}

class _PendingFileChip extends StatelessWidget {
  const _PendingFileChip({required this.name, required this.tooltip, required this.onRemove});

  final String name;
  final String tooltip;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final String lower = name.toLowerCase();
    final bool image = <String>['.png', '.jpg', '.jpeg', '.gif', '.webp', '.heic'].any(lower.endsWith);
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsetsDirectional.fromSTEB(6, 4, 4, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconWell(
            icon: image ? Icons.image_outlined : Icons.insert_drive_file_outlined,
            tone: image ? ToneColor.purple : ToneColor.blue,
            size: 28,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: tooltip,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(Icons.close_rounded, size: 15, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
