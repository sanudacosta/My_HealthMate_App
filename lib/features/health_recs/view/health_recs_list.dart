import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/health_recs_view_model.dart';
import 'package:my_healthmate_app/features/health_recs/model/health_recs_db.dart';

/// ---- Color palette (inline to avoid imports). Replace with your AppColors if you prefer. ----
const kPrimary = Color.fromARGB(255, 0, 150, 136); // Fresh Teal
const kAccent = Color.fromARGB(255, 255, 99, 56); // Vibrant Coral
const kBg = Color.fromARGB(255, 245, 245, 245); // Soft Ivory
const kCard = Color.fromARGB(255, 224, 242, 241); // Mint Green
const kText = Color.fromARGB(255, 33, 33, 33); // Charcoal

class HealthRecordListScreen extends StatefulWidget {
  const HealthRecordListScreen({super.key});

  @override
  State<HealthRecordListScreen> createState() => _HealthRecordListScreenState();
}

class _HealthRecordListScreenState extends State<HealthRecordListScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HealthRecordViewModel>(context, listen: false).fetchRecords();
    });
  }

  /// --- Date helpers: sanitize, parse, format, and range check ---

  /// Fixes strings like "2025-12-06-TO8:59:24:75842" into valid ISO8601.
  /// 1) Replace "-TO" with "T"
  /// 2) If fractional seconds are separated by ":" (invalid), change last ":" to "."
  String _sanitizeIso(String s) {
    var t = s.trim().replaceAll('-TO', 'T');
    // If there are 4 colons, last one likely precedes fractional seconds
    final colonCount = ':'.allMatches(t).length;
    if (colonCount >= 4) {
      final last = t.lastIndexOf(':');
      if (last != -1) {
        t = '${t.substring(0, last)}.${t.substring(last + 1)}';
      }
    }
    return t;
  }

  DateTime _parseCreatedAt(String createdAt) {
    final fixed = _sanitizeIso(createdAt);
    return DateTime.parse(fixed);
  }

  /// Format as "yyyy-MM-dd" without intl.
  String _formatYMD(DateTime dt) {
    String mm = dt.month.toString().padLeft(2, '0');
    String dd = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$mm-$dd';
  }

  /// Compare by date-only (inclusive).
  bool _isWithinDateRange(DateTime dt, DateTime start, DateTime end) {
    final d = DateTime(dt.year, dt.month, dt.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  // Method to show dialog for updating record
  void _showUpdateDialog(HealthRecord record) {
    final titleController = TextEditingController(text: record.title);
    final waterController = TextEditingController(
      text: record.waterIntake.toString(),
    );
    final stepsController = TextEditingController(
      text: record.steps.toString(),
    );
    final caloriesController = TextEditingController(
      text: record.calories.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Health Record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Record Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: waterController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Water Intake (ml)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: stepsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Steps'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: caloriesController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Calories'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final updatedRecord = HealthRecord(
                  id: record.id,
                  title: titleController.text,
                  createdAt: record.createdAt, // keep original createdAt
                  waterIntake:
                      int.tryParse(waterController.text) ?? record.waterIntake,
                  steps: int.tryParse(stepsController.text) ?? record.steps,
                  calories:
                      double.tryParse(caloriesController.text) ??
                      record.calories,
                );
                Provider.of<HealthRecordViewModel>(
                  context,
                  listen: false,
                ).updateRecordInDatabase(updatedRecord);
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Date Pickers
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _startDate) {
      setState(() => _startDate = pickedDate);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _endDate) {
      setState(() => _endDate = pickedDate);
    }
  }

  // Filter records based on the selected date range (date-only, inclusive)
  List<HealthRecord> _filterRecords(List<HealthRecord> records) {
    if (_startDate == null || _endDate == null) return records;
    return records.where((record) {
      final recordDT = _parseCreatedAt(record.createdAt);
      return _isWithinDateRange(recordDT, _startDate!, _endDate!);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kCard,
        foregroundColor: kText,
        title: const Text('All Health Records'),
      ),
      body: Consumer<HealthRecordViewModel>(
        builder: (context, vm, child) {
          if (vm.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.records.isEmpty) {
            return _buildEmptyState(
              onAdd: () {
                // TODO: Navigate to add record screen
              },
            );
          }

          final filteredRecords = _filterRecords(vm.records);

          return Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, index) {
                    final record = filteredRecords[index];
                    return RecordCard(
                      record: record,
                      dateText: _formatYMD(_parseCreatedAt(record.createdAt)),
                      onEdit: () => _showUpdateDialog(record),
                      onDelete: () async {
                        await vm.deleteRecordFromDatabase(record);
                        if (mounted) setState(() {});
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Filter bar UI
  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: kCard, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _selectStartDate(context),
              icon: const Icon(Icons.calendar_today, color: kPrimary, size: 18),
              label: Text(
                _startDate == null
                    ? 'Select Start Date'
                    : 'Start: ${_formatYMD(_startDate!)}',
                style: const TextStyle(color: kText),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _selectEndDate(context),
              icon: const Icon(Icons.event, color: kPrimary, size: 18),
              label: Text(
                _endDate == null
                    ? 'Select End Date'
                    : 'End: ${_formatYMD(_endDate!)}',
                style: const TextStyle(color: kText),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Clear range',
            child: Ink(
              decoration: ShapeDecoration(
                color: kAccent.withOpacity(0.1),
                shape: const CircleBorder(),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: kAccent),
                onPressed: () => setState(() {
                  _startDate = null;
                  _endDate = null;
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state widget
  Widget _buildEmptyState({VoidCallback? onAdd}) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kCard, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📭', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text(
              'No records yet',
              style: TextStyle(
                color: kText,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start tracking your health by adding a record.',
              style: TextStyle(color: kText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Record'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---- Record Card ----
class RecordCard extends StatelessWidget {
  final HealthRecord record;
  final String dateText;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RecordCard({
    super.key,
    required this.record,
    required this.dateText,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [kCard, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Accent bar
          Container(
            width: 6,
            height: 120,
            decoration: const BoxDecoration(
              color: kAccent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Date + Actions
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: kPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateText, // Only yyyy-MM-dd
                        style: const TextStyle(
                          color: kText,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      _roundedIconButton(
                        icon: Icons.edit,
                        color: kAccent,
                        onPressed: onEdit,
                        tooltip: 'Edit',
                      ),
                      const SizedBox(width: 6),
                      _roundedIconButton(
                        icon: Icons.delete,
                        color: kAccent,
                        onPressed: onDelete,
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    record.title,
                    style: const TextStyle(
                      color: kText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _metricChip(
                        icon: Icons.directions_walk,
                        label: 'Steps',
                        value: '${record.steps}',
                      ),
                      _metricChip(
                        icon: Icons.local_fire_department,
                        label: 'Calories',
                        value: '${record.calories}',
                      ),
                      _metricChip(
                        icon: Icons.water_drop,
                        label: 'Water',
                        value: '${record.waterIntake} ml',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: kPrimary),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(color: kText, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _roundedIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Ink(
        decoration: ShapeDecoration(
          color: color.withOpacity(0.12),
          shape: const CircleBorder(),
        ),
        child: IconButton(
          icon: Icon(icon, color: color),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
