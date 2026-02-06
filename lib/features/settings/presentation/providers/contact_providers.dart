import 'package:dose_time/core/database/database_helper.dart';
import 'package:dose_time/features/settings/data/repositories/contact_repository_impl.dart';
import 'package:dose_time/features/settings/domain/models/contact.dart';
import 'package:dose_time/features/settings/domain/repositories/contact_repository.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepositoryImpl(DatabaseHelper.instance);
});

final contactListProvider = FutureProvider.autoDispose<List<Contact>>((ref) async {
  final repository = ref.watch(contactRepositoryProvider);
  return repository.getAllContacts();
});

class ContactController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // nothing to init
  }

  Future<void> addContact(Contact contact) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(contactRepositoryProvider).createContact(contact);
      ref.invalidate(contactListProvider);
    });
  }

  Future<void> updateContact(Contact contact) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(contactRepositoryProvider).updateContact(contact);
      ref.invalidate(contactListProvider);
    });
  }

  Future<void> deleteContact(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(contactRepositoryProvider).deleteContact(id);
      ref.invalidate(contactListProvider);
    });
  }
}

final contactControllerProvider = AsyncNotifierProvider.autoDispose<ContactController, void>(ContactController.new);
