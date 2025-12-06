import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Import the intl package
import '../view_model/health_recs_view_model.dart';
import 'recs_adding_screen.dart';
import 'health_recs_list.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Optionally ensure records are loaded:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HealthRecordViewModel>(context, listen: false).fetchRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Dashboard'),
        backgroundColor: Colors.teal, // A fresh, modern color for the app bar
        elevation: 8.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // You can add a search function here
            },
          ),
        ],
      ),
      body: Consumer<HealthRecordViewModel>(
        builder: (context, vm, child) {
          if (vm.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.records.isEmpty) {
            return const Center(
              child: Text(
                'No records yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // Get the latest record (most recent)
          final latestRecord = vm.records.isNotEmpty ? vm.records.first : null;

          if (latestRecord == null) {
            return const Center(child: Text('No records available.'));
          }

          // Format the date to a more readable format
          final formattedDate = DateFormat(
            'MMM dd, yyyy',
          ).format(DateTime.parse(latestRecord.createdAt));

          // Show the latest record on the dashboard
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 16.0,
            ),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.only(bottom: 16.0),
              elevation: 8.0,
              shadowColor: Colors.black.withOpacity(0.2), // Soft shadow
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title of the Record
                    Text(
                      latestRecord.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Recorded on: $formattedDate',
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    // Data Columns for Steps, Calories, and Water Intake
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDataColumn("Steps 👣", latestRecord.steps),
                        _buildDataColumn("Calories 🔥", latestRecord.calories),
                        _buildDataColumn("Water 💧", latestRecord.waterIntake),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    // Progress Bars for Steps, Calories, and Water
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildProgressBar("Steps", latestRecord.steps, 10000),
                        _buildProgressBar(
                          "Calories",
                          latestRecord.calories,
                          2000,
                        ),
                        _buildProgressBar(
                          "Water",
                          latestRecord.waterIntake,
                          2500,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'all',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HealthRecordListScreen(),
                  ),
                );
              },
              backgroundColor: Colors.teal,
              child: const Icon(Icons.list, color: Colors.white),
            ),
            const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: 'add',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddRecordScreen()),
                );
              },
              backgroundColor: Colors.green,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataColumn(String title, dynamic value) {
    String displayValue = value.toString();
    if (value is double) {
      var formatter = NumberFormat('0.0');
      displayValue = formatter.format(value);
    }

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.blueAccent,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          displayValue,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }

  // Helper function to build progress bars for Steps, Calories, and Water Intake
  Widget _buildProgressBar(String title, dynamic value, double max) {
    // Ensure the value is a double for consistent comparison in progress calculation
    double progress = 0.0;

    // If value is an int (e.g., steps), we need to convert it to a double
    if (value is int) {
      progress = value / max;
    } else if (value is double) {
      progress = value / max;
    }

    // Limit progress to a max of 1.0 (100%)
    progress = progress > 1.0 ? 1.0 : progress;

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.blueAccent,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4.0),
        Container(
          width: 100,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[300],
          ),
          child: LinearProgressIndicator(
            value: progress, // Use the calculated progress
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
          ),
        ),
      ],
    );
  }
}
