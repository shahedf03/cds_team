import '../core/utils/api_formats.dart';

/// What a chat message's attached file is, from its `kind` field — drives
/// how the bubble renders it.
enum ChatFileKind {
  image,
  audio,
  video,
  file;

  static ChatFileKind fromString(String? value) => switch (value) {
    'image' => ChatFileKind.image,
    'audio' => ChatFileKind.audio,
    'video' => ChatFileKind.video,
    _ => ChatFileKind.file,
  };
}

/// One file on a chat message (2026-10-08 part C) — pictures, voice
/// messages, documents, APKs… `GET /api/tasks/chat/files/{fileId}` fetches
/// the bytes (supports Range, so audio/video can stream).
class ChatFile {
  const ChatFile({
    required this.id,
    required this.fileName,
    required this.contentType,
    required this.size,
    required this.kind,
    this.durationSeconds,
  });

  final String id;
  final String fileName;
  final String contentType;
  final int size;
  final ChatFileKind kind;
  final int? durationSeconds;

  factory ChatFile.fromJson(Map<String, dynamic> json) => ChatFile(
    id: Json.str(json['id']),
    fileName: Json.str(json['fileName']),
    contentType: Json.str(json['contentType']),
    size: Json.intVal(json['size']),
    kind: ChatFileKind.fromString(json['kind']?.toString()),
    durationSeconds: json['durationSeconds'] == null
        ? null
        : Json.intVal(json['durationSeconds']),
  );

  String get sizeText {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// One message in a task's chat — `GET /api/tasks/{taskId}/chat` and the
/// body of `POST .../chat` / `POST .../chat/files`.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.sentAt,
    required this.isMine,
    this.files = const <ChatFile>[],
  });

  final int id;
  final String senderId;
  final String senderName;
  final String body;
  final DateTime? sentAt;
  final bool isMine;
  final List<ChatFile> files;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: Json.intVal(json['id']),
    senderId: Json.str(json['senderId']),
    senderName: Json.str(json['senderName']),
    body: Json.str(json['body']),
    sentAt: Json.date(json['sentAt']),
    isMine: Json.boolOrNull(json['isMine']) ?? false,
    files: Json.objects(json['files']).map(ChatFile.fromJson).toList(),
  );

  bool get hasFiles => files.isNotEmpty;
}

/// `GET /api/tasks/{taskId}/chat?afterId=` — the whole thread state, not
/// only new messages: open on `afterId=0`, then poll with the last message's
/// id every ~4s while the screen is on-screen (the call also marks whatever
/// it returns as read).
class ChatThread {
  const ChatThread({
    required this.messages,
    required this.isOpen,
    required this.closesAt,
    required this.unread,
    required this.otherUserId,
    required this.otherUserName,
  });

  final List<ChatMessage> messages;

  /// Open while the task is open, and for 1 hour after Done/Delivered, then
  /// locked (still readable; sending returns 400). Reopens with a reopened
  /// task.
  final bool isOpen;

  /// When it locks, while still open — `null` once already open-ended or
  /// already locked.
  final DateTime? closesAt;
  final int unread;
  final String otherUserId;
  final String otherUserName;

  factory ChatThread.fromJson(Map<String, dynamic> json) => ChatThread(
    messages: Json.objects(json['messages']).map(ChatMessage.fromJson).toList(),
    isOpen: Json.boolOrNull(json['isOpen']) ?? false,
    closesAt: Json.date(json['closesAt']),
    unread: Json.intVal(json['unread']),
    otherUserId: Json.str(json['otherUserId']),
    otherUserName: Json.str(json['otherUserName']),
  );
}
