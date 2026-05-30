// This cubit file provides the current hunter's help history stream.
// It reads bounty records assigned to the signed-in user as hunter.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'helper_record_state.dart';

// HelperRecordCubit connects the helper record screen to Firestore bounty data.
class HelperRecordCubit extends Cubit<HelperRecordState> {
  HelperRecordCubit({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance,
      super(const HelperRecordState());

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // This stream watches bounties claimed by the current hunter.
  Stream<HelperBountySnapshot> watchHelperRecords() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('bounties')
        .where('hunterId', isEqualTo: uid)
        .snapshots();
  }
}
