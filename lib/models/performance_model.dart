class AssessmentResponse {
  final bool success;
  final Profile profile;
  final CurrentAssessment current;
  final List<History> history;

  AssessmentResponse({
    required this.success, 
    required this.profile, 
    required this.current, 
    required this.history
  });

  factory AssessmentResponse.fromJson(Map<String, dynamic> json) {
    var data = json['data'];
    return AssessmentResponse(
      success: json['success'],
      profile: Profile.fromJson(data['profile']),
      current: CurrentAssessment.fromJson(data['current_assessment']),
      history: (data['history'] as List).map((i) => History.fromJson(i)).toList(),
    );
  }
}

class Profile {
  final String name, nip, initial;
  Profile({required this.name, required this.nip, required this.initial});
  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    name: json['name'], 
    nip: json['nip'], 
    initial: json['avatar_initial']
  );
}

class CurrentAssessment {
  final double avg;
  final String predicate;
  final List<RadarData> radar;

  CurrentAssessment({required this.avg, required this.predicate, required this.radar});

  factory CurrentAssessment.fromJson(Map<String, dynamic> json) => CurrentAssessment(
    avg: (json['average_score'] as num).toDouble(),
    predicate: json['predicate'],
    radar: (json['radar_chart'] as List).map((i) => RadarData.fromJson(i)).toList(),
  );
}

class RadarData {
  final String subject;
  final int score;
  RadarData({required this.subject, required this.score});
  factory RadarData.fromJson(Map<String, dynamic> json) => RadarData(
    subject: json['subject'], 
    score: json['score']
  );
}

class History {
  final int id;
  final String period, predicate, feedback, evaluator, date;
  final double score;

  History({
    required this.id, 
    required this.period, 
    required this.predicate, 
    required this.feedback, 
    required this.evaluator, 
    required this.date, 
    required this.score
  });

  factory History.fromJson(Map<String, dynamic> json) => History(
    id: json['id'],
    period: json['period_name'],
    predicate: json['predicate'],
    feedback: json['feedback'] ?? '',
    evaluator: json['evaluator'],
    date: json['date'],
    score: (json['final_score'] as num).toDouble(),
  );
}