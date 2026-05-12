import 'package:cloud_firestore/cloud_firestore.dart';

const urgencyLevels = ['1 Day', '3 Days', '7 Days'];
const difficultyLevels = ['Simple', 'Difficult', 'Super Difficult', 'Epic'];

int urgencyDays(String urgencyLevel) {
  switch (urgencyLevel) {
    case '1 Day':
      return 1;
    case '3 Days':
      return 3;
    case '7 Days':
      return 7;
    default:
      return 7;
  }
}

int urgencyScore(String urgencyLevel) {
  switch (urgencyLevel) {
    case '1 Day':
      return 3;
    case '3 Days':
      return 2;
    case '7 Days':
      return 1;
    default:
      return 1;
  }
}

int difficultyScore(String difficulty) {
  switch (difficulty) {
    case 'Epic':
      return 4;
    case 'Super Difficult':
    case 'Very Difficult':
      return 3;
    case 'Difficult':
      return 2;
    case 'Simple':
      return 1;
    default:
      return 1;
  }
}

double minimumBounty(String urgencyLevel, String difficulty) {
  final score = urgencyScore(urgencyLevel) + difficultyScore(difficulty);
  if (score < 3) return 5;
  if (score <= 5) return 10;
  return 15;
}

DateTime? timestampDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

bool isExpired(Map<String, dynamic> data, DateTime now) {
  final expiresAt = timestampDate(data['expiresAt']);
  if (expiresAt == null) return false;
  return !expiresAt.isAfter(now);
}
