import 'dart:convert';

class GameEvent {
  final DateTime ts;
  final String msg;

  GameEvent({required this.ts, required this.msg});

  Map<String, dynamic> toJson() => {
        'ts': ts.toIso8601String(),
        'msg': msg,
      };

  factory GameEvent.fromJson(Map<String, dynamic> json) => GameEvent(
        ts: DateTime.parse(json['ts'] as String),
        msg: json['msg'] as String,
      );
}

class GameState {
  List<String> players;
  List<List<String>> rounds;
  int currIdx;
  int? editingIdx;
  bool locked;
  bool started;
  Map<String, List<int>> tileDetails;
  Map<int, int> roundWinners;
  int turnIdx;
  String timeRule;
  bool turnAutoRotate;
  bool confirmExpiry;
  Map<int, Map<int, int>> roundPenalties;
  List<GameEvent> events;

  GameState({
    required this.players,
    required this.rounds,
    required this.currIdx,
    this.editingIdx,
    required this.locked,
    required this.started,
    required this.tileDetails,
    required this.roundWinners,
    required this.turnIdx,
    required this.timeRule,
    required this.turnAutoRotate,
    required this.confirmExpiry,
    required this.roundPenalties,
    required this.events,
  });

  factory GameState.initial() => GameState(
        players: [],
        rounds: [],
        currIdx: 0,
        editingIdx: null,
        locked: false,
        started: false,
        tileDetails: {},
        roundWinners: {},
        turnIdx: 0,
        timeRule: 'official',
        turnAutoRotate: false,
        confirmExpiry: false,
        roundPenalties: {},
        events: [],
      );

  Map<String, dynamic> toJson() => {
        'players': players,
        'rounds': rounds,
        'currIdx': currIdx,
        'editingIdx': editingIdx,
        'locked': locked,
        'started': started,
        'tileDetails': tileDetails.map((k, v) => MapEntry(k, v)),
        'roundWinners':
            roundWinners.map((k, v) => MapEntry(k.toString(), v)),
        'turnIdx': turnIdx,
        'timeRule': timeRule,
        'turnAutoRotate': turnAutoRotate,
        'confirmExpiry': confirmExpiry,
        'roundPenalties': roundPenalties.map(
          (rIdx, pMap) => MapEntry(
            rIdx.toString(),
            pMap.map((pIdx, cnt) => MapEntry(pIdx.toString(), cnt)),
          ),
        ),
        'events': events.map((e) => e.toJson()).toList(),
      };

  factory GameState.fromJson(Map<String, dynamic> json) {
    final playersRaw = json['players'] as List<dynamic>? ?? [];
    final roundsRaw = json['rounds'] as List<dynamic>? ?? [];
    final tileDetailsRaw =
        json['tileDetails'] as Map<String, dynamic>? ?? {};
    final roundWinnersRaw =
        json['roundWinners'] as Map<String, dynamic>? ?? {};
    final roundPenaltiesRaw =
        json['roundPenalties'] as Map<String, dynamic>? ?? {};
    final eventsRaw = json['events'] as List<dynamic>? ?? [];

    return GameState(
      players: playersRaw.map((e) => e.toString()).toList(),
      rounds: roundsRaw
          .map((r) => (r as List<dynamic>).map((s) => s.toString()).toList())
          .toList(),
      currIdx: (json['currIdx'] as num?)?.toInt() ?? 0,
      editingIdx: json['editingIdx'] != null
          ? (json['editingIdx'] as num).toInt()
          : null,
      locked: json['locked'] as bool? ?? false,
      started: json['started'] as bool? ?? false,
      tileDetails: tileDetailsRaw.map(
        (k, v) => MapEntry(
          k,
          (v as List<dynamic>).map((e) => (e as num).toInt()).toList(),
        ),
      ),
      roundWinners: roundWinnersRaw.map(
        (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
      ),
      turnIdx: (json['turnIdx'] as num?)?.toInt() ?? 0,
      timeRule: json['timeRule'] as String? ?? 'official',
      turnAutoRotate: json['turnAutoRotate'] as bool? ?? false,
      confirmExpiry: json['confirmExpiry'] as bool? ?? false,
      roundPenalties: roundPenaltiesRaw.map(
        (rIdx, pMap) => MapEntry(
          int.parse(rIdx),
          (pMap as Map<String, dynamic>).map(
            (pIdx, cnt) => MapEntry(int.parse(pIdx), (cnt as num).toInt()),
          ),
        ),
      ),
      events: eventsRaw
          .map((e) => GameEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory GameState.fromJsonString(String jsonStr) =>
      GameState.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);

  GameState copyWith({
    List<String>? players,
    List<List<String>>? rounds,
    int? currIdx,
    Object? editingIdx = _sentinel,
    bool? locked,
    bool? started,
    Map<String, List<int>>? tileDetails,
    Map<int, int>? roundWinners,
    int? turnIdx,
    String? timeRule,
    bool? turnAutoRotate,
    bool? confirmExpiry,
    Map<int, Map<int, int>>? roundPenalties,
    List<GameEvent>? events,
  }) {
    return GameState(
      players: players ?? List<String>.from(this.players),
      rounds: rounds ??
          this.rounds.map((r) => List<String>.from(r)).toList(),
      currIdx: currIdx ?? this.currIdx,
      editingIdx:
          editingIdx == _sentinel ? this.editingIdx : editingIdx as int?,
      locked: locked ?? this.locked,
      started: started ?? this.started,
      tileDetails: tileDetails ??
          Map<String, List<int>>.from(
            this.tileDetails.map((k, v) => MapEntry(k, List<int>.from(v))),
          ),
      roundWinners: roundWinners ?? Map<int, int>.from(this.roundWinners),
      turnIdx: turnIdx ?? this.turnIdx,
      timeRule: timeRule ?? this.timeRule,
      turnAutoRotate: turnAutoRotate ?? this.turnAutoRotate,
      confirmExpiry: confirmExpiry ?? this.confirmExpiry,
      roundPenalties: roundPenalties ??
          Map<int, Map<int, int>>.from(
            this.roundPenalties.map(
                  (k, v) => MapEntry(k, Map<int, int>.from(v)),
                ),
          ),
      events: events ?? List<GameEvent>.from(this.events),
    );
  }
}

const _sentinel = Object();
