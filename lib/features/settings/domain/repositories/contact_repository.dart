import 'package:dose_time/features/settings/domain/models/contact.dart';

abstract class ContactRepository {
  Future<List<Contact>> getAllContacts();
  Future<Contact> getContact(int id);
  Future<Contact> createContact(Contact contact);
  Future<int> updateContact(Contact contact);
  Future<int> deleteContact(int id);
}
