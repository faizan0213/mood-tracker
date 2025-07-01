import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../model/mood_entry.dart';

class MoodService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<bool> hasLoggedToday() async {
    final uid = _auth.currentUser!.uid;
    final doc = await _firestore.collection('users').doc(uid).collection('moods').doc(_dateKey(DateTime.now())).get();
    return doc.exists;
  }

  Future<String?> logMood(String mood, String note) async {
    final uid = _auth.currentUser!.uid;
    final todayDoc = _firestore.collection('users').doc(uid).collection('moods').doc(_dateKey(DateTime.now()));
    final exists = await todayDoc.get();

    if (exists.exists) return 'Mood already logged today.';

    final entry = MoodEntry(mood: mood, note: note, timestamp: DateTime.now());
    await todayDoc.set(entry.toMap());
    return null;
  }

  Future<List<MoodEntry>> getLast7Days() async {
    final uid = _auth.currentUser!.uid;
    final moodsRef = _firestore.collection('users').doc(uid).collection('moods');
    final now = DateTime.now();
    final result = <MoodEntry>[];

    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final doc = await moodsRef.doc(_dateKey(day)).get();
      if (doc.exists) result.add(MoodEntry.fromMap(doc.data()!));
    }

    return result;
  }

  Future<void> updateNote(DateTime date, String note) async {
    final uid = _auth.currentUser!.uid;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('moods')
        .doc(_dateKey(date))
        .update({'note': note});
  }
}
