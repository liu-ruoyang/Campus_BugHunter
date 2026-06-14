// This utility file stores shared bounty business rules for urgency, difficulty, expiration, and minimum reward checks.
// Post, edit, board, request record, and active screens use these helpers to keep bounty behavior consistent.
import 'package:cloud_firestore/cloud_firestore.dart';

// These constants define the selectable urgency and difficulty labels used by the request forms.
const urgencyLevels = ['1 Day', '3 Days', '7 Days'];
const difficultyLevels = ['Simple', 'Difficult', 'Super Difficult', 'Epic'];

// This helper converts the displayed urgency label into the number of days stored on a bounty.
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

// This helper assigns the score used by the minimum bounty calculation for urgency.
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

// This helper assigns the score used by the minimum bounty calculation for estimated difficulty.
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

// This helper combines urgency and difficulty scores to return the required minimum bounty amount.
double minimumBounty(String urgencyLevel, String difficulty) {
  final score = urgencyScore(urgencyLevel) + difficultyScore(difficulty);
  if (score < 3) return 5;
  if (score <= 5) return 10;
  return 15;
}

// This helper safely converts Firestore timestamps or DateTime values into a DateTime object.
DateTime? timestampDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

// This helper checks whether a bounty has reached its stored expiration time.
bool isExpired(Map<String, dynamic> data, DateTime now) {
  final expiresAt = timestampDate(data['expiresAt']);
  if (expiresAt == null) return false;
  return !expiresAt.isAfter(now);
}
