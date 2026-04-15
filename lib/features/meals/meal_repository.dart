import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import 'meal_model.dart';

class MealImageUpload {
  const MealImageUpload({
    required this.downloadUrl,
    required this.storagePath,
  });

  final String downloadUrl;
  final String storagePath;
}

class MealRepository {
  MealRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const String collection = 'meal_logs';

  Future<MealImageUpload> uploadMealPhoto({
    required String userId,
    required XFile file,
  }) async {
    final bytes = await file.readAsBytes();
    var ext = p.extension(file.name).toLowerCase();
    if (ext.isEmpty) {
      ext = '.jpg';
    }
    final safeExt = ext.length > 8 ? '.jpg' : ext;
    final storagePath =
        'meal_images/$userId/${DateTime.now().millisecondsSinceEpoch}$safeExt';
    final ref = _storage.ref(storagePath);
    final mime = lookupMimeType(file.name, headerBytes: bytes) ?? 'image/jpeg';
    await ref.putData(bytes, SettableMetadata(contentType: mime));
    final url = await ref.getDownloadURL();
    return MealImageUpload(downloadUrl: url, storagePath: storagePath);
  }

  Future<void> deleteStorageObjectAtPath(String? storagePath) async {
    if (storagePath == null || storagePath.isEmpty) return;
    try {
      await _storage.ref(storagePath).delete();
    } catch (_) {}
  }

  Future<String> addMeal(MealLog meal) async {
    final doc = await _firestore.collection(collection).add(meal.toMap());
    return doc.id;
  }

  Future<void> updateMeal(MealLog meal) async {
    await _firestore.collection(collection).doc(meal.id).update(meal.toMap());
  }

  Future<void> deleteMeal(MealLog meal) async {
    await deleteStorageObjectAtPath(meal.imageStoragePath);
    await _firestore.collection(collection).doc(meal.id).delete();
  }

  Stream<List<MealLog>> watchMeals(String userId) {
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => MealLog.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      return list;
    });
  }
}
