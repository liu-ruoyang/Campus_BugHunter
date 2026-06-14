// This state file defines the Firestore snapshot shape used by helper records.
import 'package:cloud_firestore/cloud_firestore.dart';

// HelperRecordState is reserved for future helper record actions.
class HelperRecordState {
  const HelperRecordState();
}

// HelperBountySnapshot names the Firestore query snapshot for helper history.
typedef HelperBountySnapshot = QuerySnapshot<Map<String, dynamic>>;
