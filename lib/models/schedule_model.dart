class Schedule {
  final String startTime;
  final String endTime;
  final String day;
  final String subjectName;
  final String classroomName;

  Schedule({
    required this.startTime,
    required this.endTime,
    required this.day,
    required this.subjectName,
    required this.classroomName,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      startTime: json['start_time'],
      endTime: json['end_time'],
      day: json['day'],
      subjectName: json['subject']['name'],
      classroomName: json['classroom']['name'],
    );
  }
}