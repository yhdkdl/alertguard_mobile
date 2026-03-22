import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/profile_model.dart';
import '../../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final profileProvider = FutureProvider<ProfileModel>((ref) async {
  final repo = ref.read(profileRepositoryProvider);
  return repo.getProfile();
});
