typedef RecordData = Map<String, dynamic>;
const projectStages = [
  'ТЗ анкета',
  'Замеры',
  'Планировка',
  'Концепции',
  'Визуализации',
  'Рабочая документация',
];

class Brief {
  final RecordData data;
  Brief(this.data);
  String get id => data['id'] as String;
  String get title => data['title'] as String;
  int get version => data['version'] as int;
  bool get ready => data['status'] == 'ready' || data['submitted_at'] != null;
  RecordData get answers =>
      Map<String, dynamic>.from(data['answers'] as Map? ?? {});
  RecordData get workflow =>
      Map<String, dynamic>.from(data['workflow'] as Map? ?? {});
  RecordData get approvals =>
      Map<String, dynamic>.from(data['client_approvals'] as Map? ?? {});
  List<dynamic> get measurements => workflow['measurements'] as List? ?? [];
  int get stage {
    if (!ready) return 0;
    if (measurements.isEmpty) return 1;
    for (var i = 2; i <= 4; i++) {
      if (!approvals.containsKey('$i')) return i;
    }
    return 5;
  }

  bool stageOpen(int stage) =>
      stage < 2 ||
      (stage == 2
          ? measurements.isNotEmpty
          : approvals.containsKey('${stage - 1}'));
  RecordData patch(RecordData changes) => {
    'title': title,
    'answers': answers,
    'status': data['status'],
    'version': version,
    ...changes,
  };
}
