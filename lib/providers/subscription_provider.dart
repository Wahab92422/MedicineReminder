import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live `users/{uid}.isPremium` from Firestore.
final subscriptionProvider = StreamProvider<bool>((ref) {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return Stream.value(false);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
    final v = doc.data()?['isPremium'];
    if (v is bool) return v;
    return false;
  });
});
