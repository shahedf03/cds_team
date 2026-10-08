import '../core/utils/api_formats.dart';

/// `GET /api/system-codes` → dropdown values, grouped client-side by
/// `sysCodeTypeId` exactly like the legacy screen did.
class SystemCode {
  const SystemCode({
    required this.sysCodeTypeId,
    required this.sysCode,
    required this.name,
  });

  final String sysCodeTypeId;
  final String sysCode;
  final String name;

  factory SystemCode.fromJson(Map<String, dynamic> json) => SystemCode(
    sysCodeTypeId: Json.str(json['sysCodeTypeId']),
    sysCode: Json.str(json['sysCode']),
    name: Json.str(json['name']),
  );

  @override
  bool operator ==(Object other) =>
      other is SystemCode &&
      other.sysCodeTypeId == sysCodeTypeId &&
      other.sysCode == sysCode;

  @override
  int get hashCode => Object.hash(sysCodeTypeId, sysCode);
}

/// The `sysCodeTypeId` buckets the Leave screen's Type dropdown reads from.
class SysCodeType {
  const SysCodeType._();

  /// Types offered when the segmented control is on "Leaving".
  static const String leaving = 'LeaveType';

  /// Types offered when the segmented control is on "Vacation".
  static const String vacation = 'VacationType';
}
