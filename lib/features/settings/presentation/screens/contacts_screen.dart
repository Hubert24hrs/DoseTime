import 'package:dose_time/features/settings/presentation/providers/contact_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/settings/contacts/add'),
        child: const Icon(Icons.add),
      ),
      body: contactsAsync.when(
        data: (contacts) {
          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.contact_phone_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No contacts yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  const Text('Add your doctors and pharmacies here.'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: contacts.length,
            // padding bottom to avoid FAB overlap
            padding: const EdgeInsets.only(bottom: 80, top: 8), 
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Dismissible(
                key: Key('contact-${contact.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Contact?'),
                      content: Text('Are you sure you want to delete ${contact.name}?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  ref.read(contactControllerProvider.notifier).deleteContact(contact.id!);
                },
                child: Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: contact.type == 'Doctor' ? Colors.blue[100] : Colors.green[100],
                      child: Icon(
                        contact.type == 'Doctor' ? Icons.medical_services : Icons.local_pharmacy,
                        color: contact.type == 'Doctor' ? Colors.blue : Colors.green,
                      ),
                    ),
                    title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(contact.type, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        if (contact.phone != null) ...[
                          const SizedBox(height: 2),
                           Row(
                             children: [
                               const Icon(Icons.phone, size: 14, color: Colors.grey),
                               const SizedBox(width: 4),
                               Text(contact.phone!, style: const TextStyle(fontSize: 13)),
                             ],
                           ),
                        ],
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () => context.go('/settings/contacts/edit/${contact.id}'),
                    trailing: contact.phone != null 
                        ? IconButton(
                            icon: const Icon(Icons.call, color: Colors.green),
                            onPressed: () => _makeCall(contact.phone!),
                          )
                        : null,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
