class Exam {
  String course;
  DateTime timestamp;
  double latitude;
  double longitude;

  Exam({required this.course, required this.timestamp, this.latitude = 0.0, this.longitude = 0.0});
}
