import 'dart:convert';

class TimerConfig {
  final int durationSeconds;
  final bool soundEnabled;

  const TimerConfig({
    required this.durationSeconds,
    required this.soundEnabled,
  });

  factory TimerConfig.initial() => const TimerConfig(
        durationSeconds: 120,
        soundEnabled: true,
      );

  Map<String, dynamic> toJson() => {
        'd': durationSeconds,
        's': soundEnabled,
      };

  factory TimerConfig.fromJson(Map<String, dynamic> json) => TimerConfig(
        durationSeconds: (json['d'] as num?)?.toInt() ?? 120,
        soundEnabled: json['s'] as bool? ?? true,
      );

  String toJsonString() => jsonEncode(toJson());

  factory TimerConfig.fromJsonString(String jsonStr) =>
      TimerConfig.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);

  TimerConfig copyWith({
    int? durationSeconds,
    bool? soundEnabled,
  }) =>
      TimerConfig(
        durationSeconds: durationSeconds ?? this.durationSeconds,
        soundEnabled: soundEnabled ?? this.soundEnabled,
      );
}
