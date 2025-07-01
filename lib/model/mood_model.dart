import 'package:cloud_firestore/cloud_firestore.dart';

class MoodEntry {
  final String mood;
  final String note;
  final DateTime timestamp;

  MoodEntry({required this.mood, required this.note, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {'mood': mood, 'note': note, 'timestamp': timestamp};
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      mood: map['mood'],
      note: map['note'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
