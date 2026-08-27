class DeviceMetadata {
  final String deviceId;
  final String deviceName;
  final String platform;
  final DateTime lastSeenAt;
  final String appVersion;

  const DeviceMetadata({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.lastSeenAt,
    this.appVersion = '1.0.0+1',
  });

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'device_name': deviceName,
        'platform': platform,
        'last_seen_at': lastSeenAt.toUtc().toIso8601String(),
        'app_version': appVersion,
      };

  factory DeviceMetadata.fromJson(Map<String, dynamic> json) => DeviceMetadata(
        deviceId: json['device_id'] as String,
        deviceName: json['device_name'] as String? ?? 'Unknown Device',
        platform: json['platform'] as String? ?? 'other',
        lastSeenAt: json['last_seen_at'] != null
            ? DateTime.parse(json['last_seen_at'] as String)
            : DateTime.now(),
        appVersion: json['app_version'] as String? ?? '1.0.0+1',
      );
}

class SyncChunk {
  final String fileId;
  final String fileName;
  final String deviceId;
  final int sequence;
  final String content;
  final DateTime createdAt;

  const SyncChunk({
    required this.fileId,
    required this.fileName,
    required this.deviceId,
    required this.sequence,
    required this.content,
    required this.createdAt,
  });
}

class SyncStatusState {
  final bool isConnected;
  final bool isSyncing;
  final String? accountEmail;
  final String deviceId;
  final int pendingCount;
  final DateTime? lastSyncTime;
  final String? errorMessage;

  const SyncStatusState({
    this.isConnected = false,
    this.isSyncing = false,
    this.accountEmail,
    this.deviceId = '',
    this.pendingCount = 0,
    this.lastSyncTime,
    this.errorMessage,
  });

  SyncStatusState copyWith({
    bool? isConnected,
    bool? isSyncing,
    String? accountEmail,
    String? deviceId,
    int? pendingCount,
    DateTime? lastSyncTime,
    String? errorMessage,
  }) {
    return SyncStatusState(
      isConnected: isConnected ?? this.isConnected,
      isSyncing: isSyncing ?? this.isSyncing,
      accountEmail: accountEmail ?? this.accountEmail,
      deviceId: deviceId ?? this.deviceId,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage,
    );
  }
}
