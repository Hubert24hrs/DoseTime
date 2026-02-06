import 'package:dose_time/core/database/database_helper.dart';
import 'package:dose_time/features/settings/domain/models/contact.dart';
import 'package:dose_time/features/settings/domain/repositories/contact_repository.dart';

class ContactRepositoryImpl implements ContactRepository {
  final DatabaseHelper _dbHelper;

  ContactRepositoryImpl(this._dbHelper);

  @override
  Future<List<Contact>> getAllContacts() async {
    final db = await _dbHelper.database;
    final result = await db.query('contacts', orderBy: 'name ASC');
    return result.map((map) => Contact.fromMap(map)).toList();
  }

  @override
  Future<Contact> getContact(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query('contacts', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Contact.fromMap(result.first);
    } else {
      throw Exception('Contact not found');
    }
  }

  @override
  Future<Contact> createContact(Contact contact) async {
    final db = await _dbHelper.database;
    final id = await db.insert('contacts', contact.toMap());
    return contact.copyWith(id: id);
  }

  @override
  Future<int> updateContact(Contact contact) async {
    final db = await _dbHelper.database;
    return await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  @override
  Future<int> deleteContact(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
