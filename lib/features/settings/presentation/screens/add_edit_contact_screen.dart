import 'package:dose_time/core/widgets/three_d_button.dart';
import 'package:dose_time/features/settings/domain/models/contact.dart';
import 'package:dose_time/features/settings/presentation/providers/contact_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AddEditContactScreen extends ConsumerStatefulWidget {
  final int? contactId;

  const AddEditContactScreen({super.key, this.contactId});

  @override
  ConsumerState<AddEditContactScreen> createState() => _AddEditContactScreenState();
}

class _AddEditContactScreenState extends ConsumerState<AddEditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedType = 'Doctor';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.contactId != null) {
      _loadContact();
    }
  }

  Future<void> _loadContact() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(contactRepositoryProvider);
      final contact = await repository.getContact(widget.contactId!);
      
      _nameController.text = contact.name;
      _phoneController.text = contact.phone ?? '';
      _emailController.text = contact.email ?? '';
      _addressController.text = contact.address ?? '';
      _notesController.text = contact.notes ?? '';
      setState(() {
        _selectedType = contact.type;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error loading contact: $e')),
        );
      }
    }
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
    final email = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
    final address = _addressController.text.trim().isEmpty ? null : _addressController.text.trim();
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

    final contact = Contact(
      id: widget.contactId,
      name: name,
      type: _selectedType,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
    );

    final controller = ref.read(contactControllerProvider.notifier);
    
    if (widget.contactId == null) {
      await controller.addContact(contact);
    } else {
      await controller.updateContact(contact);
    }

    if (mounted) {
      context.pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contactId == null ? 'Add Contact' : 'Edit Contact'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                   TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) => 
                        value == null || value.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: ['Doctor', 'Pharmacy', 'Other'].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedType = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ThreeDButton(
                      onPressed: _saveContact,
                      color: Theme.of(context).primaryColor,
                      child: const Text(
                        'Save Contact',
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 16, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
