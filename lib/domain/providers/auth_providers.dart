import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.idTokenChanges();
});

final authInitializedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.hasValue;
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  final userData = await FirestoreService().getUser(user.uid);

  if (userData != null) {
    if (userData.selectedTopicId != null) {
      ref.read(selectedTopicIdProvider.notifier).state =
          userData.selectedTopicId;
    }
    if (userData.selectedGrade != null) {
      ref.read(selectedGradeProvider.notifier).state = userData.selectedGrade;
    }
    if (userData.selectedTopic != null) {
      ref.read(selectedTopicProvider.notifier).state = userData.selectedTopic;
    }
  }

  return userData;
});

final selectedGradeProvider = StateProvider<String?>((ref) => null);
final selectedTopicProvider = StateProvider<String?>((ref) => null);
final selectedTopicIdProvider = StateProvider<String?>((ref) => null);
final refreshUserDataProvider = StateProvider<bool>((ref) => false);
