class Contact {
  final int? id;
  final String name;
  final String type; // 'Doctor' or 'Pharmacy'
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;

  Contact({
    this.id,
    required this.name,
    required this.type,
    this.phone,
    this.email,
    this.address,
    this.notes,
  });

  Contact copyWith({
    int? id,
    String? name,
    String? type,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      notes: map['notes'],
    );
  }
}
