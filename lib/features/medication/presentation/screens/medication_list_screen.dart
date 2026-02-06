import 'package:dose_time/core/widgets/three_d_button.dart';
import 'package:dose_time/features/medication/domain/models/medication.dart';
import 'package:dose_time/features/medication/presentation/providers/medication_providers.dart';
import 'package:dose_time/features/medication/presentation/providers/repository_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum SortOption { name, type, stock }
enum FilterOption { all, active, archived }

class MedicationListScreen extends ConsumerStatefulWidget {
  const MedicationListScreen({super.key});

  @override
  ConsumerState<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends ConsumerState<MedicationListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  SortOption _sortBy = SortOption.name;
  FilterOption _filterBy = FilterOption.active;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Medication> _filterAndSort(List<Medication> medications) {
    // Filter by search query
    var filtered = medications.where((med) {
      if (_searchQuery.isEmpty) return true;
      return med.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             med.dosage.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Filter by archive status
    filtered = filtered.where((med) {
      switch (_filterBy) {
        case FilterOption.all:
          return true;
        case FilterOption.active:
          return !med.isArchived;
        case FilterOption.archived:
          return med.isArchived;
      }
    }).toList();

    // Sort
    switch (_sortBy) {
      case SortOption.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.type:
        filtered.sort((a, b) => a.type.name.compareTo(b.type.name));
        break;
      case SortOption.stock:
        filtered.sort((a, b) {
          final aStock = a.stockQuantity ?? double.infinity;
          final bStock = b.stockQuantity ?? double.infinity;
          return aStock.compareTo(bStock);
        });
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final medicationsAsync = ref.watch(medicationListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medications'),
        actions: [
          PopupMenuButton<FilterOption>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onSelected: (val) => setState(() => _filterBy = val),
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: FilterOption.active,
                checked: _filterBy == FilterOption.active,
                child: const Text('Active'),
              ),
              CheckedPopupMenuItem(
                value: FilterOption.archived,
                checked: _filterBy == FilterOption.archived,
                child: const Text('Archived'),
              ),
              CheckedPopupMenuItem(
                value: FilterOption.all,
                checked: _filterBy == FilterOption.all,
                child: const Text('All'),
              ),
            ],
          ),
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: SortOption.name,
                checked: _sortBy == SortOption.name,
                child: const Text('By Name'),
              ),
              CheckedPopupMenuItem(
                value: SortOption.type,
                checked: _sortBy == SortOption.type,
                child: const Text('By Type'),
              ),
              CheckedPopupMenuItem(
                value: SortOption.stock,
                checked: _sortBy == SortOption.stock,
                child: const Text('By Stock'),
              ),
            ],
          ),
        ],
      ),
      body: medicationsAsync.when(
        data: (medications) {
          if (medications.isEmpty) {
            return _buildEmptyState(context);
          }

          final filteredMeds = _filterAndSort(medications);

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search medications...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? Semantics(
                            label: 'Clear search',
                            button: true,
                            child: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                HapticFeedback.selectionClick();
                              },
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              // Results count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filteredMeds.length} medication${filteredMeds.length != 1 ? 's' : ''}',
                      style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                    if (_filterBy == FilterOption.archived)
                      TextButton.icon(
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('Show Active'),
                        onPressed: () => setState(() => _filterBy = FilterOption.active),
                      ),
                  ],
                ),
              ),
              // Medication list
              Expanded(
                child: filteredMeds.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isNotEmpty 
                              ? 'No medications match your search'
                              : 'No ${_filterBy == FilterOption.archived ? 'archived' : 'active'} medications',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredMeds.length,
                        itemBuilder: (context, index) {
                          final med = filteredMeds[index];
                          return _buildMedicationCard(context, ref, med);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: medicationsAsync.hasValue && medicationsAsync.value!.isNotEmpty 
        ? ThreeDButton(
            width: 60,
            height: 60,
            isFloating: true,
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.go('/medications/add');
            },
            child: Semantics(
              label: 'Add new medication',
              button: true,
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          )
        : null,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No medications yet', style: TextStyle(color: Colors.grey[600], fontSize: 18)),
          const SizedBox(height: 24),
          ThreeDButton(
            width: 200,
            onPressed: () => context.go('/medications/add'),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 8),
                Text('Add Medication', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMedicationCard(BuildContext context, WidgetRef ref, Medication med) {
    final isLowStock = med.stockQuantity != null && 
                       med.refillThreshold != null && 
                       med.stockQuantity! <= med.refillThreshold!;

    return Dismissible(
      key: Key('med-${med.id}'),
      background: Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Edit
          context.go('/medications/edit/${med.id}');
          return false;
        } else {
          // Delete - show confirmation
          return await _confirmDelete(context, ref, med);
        }
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: GestureDetector(
            onTap: () {
               HapticFeedback.selectionClick();
               _showMedicationInfo(context, med);
            },
            child: CircleAvatar(
              backgroundColor: Color(med.color).withValues(alpha: 0.2),
              child: Icon(
                med.icon != null ? IconData(med.icon!, fontFamily: 'MaterialIcons') : Icons.medication,
                color: Color(med.color),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  med.name, 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: med.isArchived ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (med.isArchived)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Archived', style: TextStyle(fontSize: 10)),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${med.dosage} • ${med.frequency} • ${med.type.displayName}'),
              if (med.stockQuantity != null)
                Text(
                  'Stock: ${med.stockQuantity!.toInt()} units',
                  style: TextStyle(
                    fontSize: 12,
                    color: isLowStock ? Colors.red : Colors.grey[600],
                    fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.teal),
                onPressed: () => context.go('/medications/edit/${med.id}'),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: Icon(
                  med.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                  color: Colors.grey,
                ),
                onPressed: () => _toggleArchive(ref, med),
                tooltip: med.isArchived ? 'Unarchive' : 'Archive',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, WidgetRef ref, Medication med) async {
    await HapticFeedback.mediumImpact();
    
    if (!context.mounted) return false;

    final result = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Delete Medication?'),
        content: Text('This will delete "${med.name}" and its history. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      ref.read(deleteMedicationProvider)(med.id!);
      return true;
    }
    return false;
  }

  void _toggleArchive(WidgetRef ref, Medication med) async {
    final repository = ref.read(medicationRepositoryProvider);
    final updatedMed = med.copyWith(isArchived: !med.isArchived);
    await repository.updateMedication(updatedMed);
    ref.invalidate(medicationListProvider);
    ref.invalidate(todaysScheduleProvider);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(med.isArchived ? '${med.name} restored' : '${med.name} archived'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _toggleArchive(ref, updatedMed),
          ),
        ),
      );
    }
  }

  void _showMedicationInfo(BuildContext context, Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              medication.icon != null 
                ? IconData(medication.icon!, fontFamily: 'MaterialIcons') 
                : Icons.medication,
              color: Color(medication.color),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(medication.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Type', medication.type.displayName),
            _infoRow('Dosage', medication.dosage),
            _infoRow('Frequency', medication.frequency),
            _infoRow('Times', medication.times.join(", ")),
            if (medication.instructions != null)
              _infoRow('Instructions', medication.instructions!),
            if (medication.stockQuantity != null)
              _infoRow(
                'Stock', 
                '${medication.stockQuantity!.toInt()} units',
                valueColor: (medication.refillThreshold != null && 
                            medication.stockQuantity! <= medication.refillThreshold!) 
                    ? Colors.red : Colors.green,
              ),
            if (medication.refillThreshold != null)
              _infoRow('Refill at', '${medication.refillThreshold!.toInt()} units'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/medications/edit/${medication.id}');
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: valueColor)),
          ),
        ],
      ),
    );
  }
}

