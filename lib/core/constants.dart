import 'package:flutter/material.dart';

const List<String> moods = ['Happy', 'Sad', 'Angry', 'Neutral'];

class AppColors {
  static const Color primary = Colors.pink;
}

Color moodColor(String mood) {
  switch (mood) {
    case 'Happy':
      return Colors.green;
    case 'Sad':
      return Colors.blue;
    case 'Angry':
      return Colors.red;
    case 'Neutral':
      return Colors.grey;
    default:
      return Colors.black;
  }
}
