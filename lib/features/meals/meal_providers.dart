import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'meal_model.dart';
import 'meal_repository.dart';

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository();
});

final mealLogsStreamProvider = StreamProvider<List<MealLog>>((ref) {
  final repo = ref.watch(mealRepositoryProvider);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(const []);
  }
  return repo.watchMeals(user.uid);
});

final mealControllerProvider = Provider<MealController>((ref) {
  return MealController(ref.watch(mealRepositoryProvider));
});

class MealController {
  MealController(this._repo);

  final MealRepository _repo;

  Future<String> addMeal(MealLog meal) => _repo.addMeal(meal);

  Future<void> updateMeal(MealLog meal) => _repo.updateMeal(meal);

  Future<void> deleteMeal(MealLog meal) => _repo.deleteMeal(meal);

  Future<MealImageUpload> uploadPhoto({
    required String userId,
    required XFile file,
  }) =>
      _repo.uploadMealPhoto(userId: userId, file: file);

  Future<void> deleteStorageAtPath(String? path) =>
      _repo.deleteStorageObjectAtPath(path);
}
