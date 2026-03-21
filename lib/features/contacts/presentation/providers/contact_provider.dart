import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/contact_model.dart';
import '../../data/contact_repository.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository();
});

// Loads and holds the list of contacts
class ContactsNotifier extends AsyncNotifier<List<ContactModel>> {
  late ContactRepository _repo;

  @override
  Future<List<ContactModel>> build() async {
    _repo = ref.read(contactRepositoryProvider);
    return _repo.getContacts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getContacts());
  }

  Future<void> addContact({
    required String name,
    required String phoneNumber,
    required String relationship,
  }) async {
    final newContact = await _repo.addContact(
      name: name,
      phoneNumber: phoneNumber,
      relationship: relationship,
    );

    // Add to local list immediately — no need to refetch
    final current = state.value ?? [];
    state = AsyncData([...current, newContact]);
  }

  Future<void> deleteContact(int id) async {
    await _repo.deleteContact(id);
    final current = state.value ?? [];
    state = AsyncData(current.where((c) => c.id != id).toList());
  }
}

final contactsProvider =
    AsyncNotifierProvider<ContactsNotifier, List<ContactModel>>(
      ContactsNotifier.new,
    );
