import 'package:flutter/material.dart';
import '../model/health_recs_db.dart';
import '../repo/health_recs_repo.dart';

class HealthRecordViewModel extends ChangeNotifier {
  final HealthRecordRepository _repo = HealthRecordRepository();

  List<HealthRecord> records = [];
  bool loading = false;

  // Fetch all records from DB and notify listeners
  Future<void> fetchRecords() async {
    try {
      loading = true;
      notifyListeners();
      final fetched = await _repo.getAll(); // ensure repository has getAll()
      records = fetched;
    } catch (e) {
      // handle/log error if needed
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Save record to DB and update the in-memory list so UI refreshes immediately
  Future<void> saveRecordToDatabase(HealthRecord record) async {
    try {
      loading = true;
      notifyListeners();
      await _repo.save(record); // ensure repo.save returns id or void
      // If repository returns id or saved item, handle accordingly.
      // Insert at start so dashboard shows most recent first
      records.insert(0, record);
      // Optionally: if repo provides id, set it: record.id = savedId;
      // If you prefer full DB truth, you can call await fetchRecords(); instead of insert.
    } catch (e) {
      // handle/log
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Delete record both in DB and in-memory list
  Future<void> deleteRecordFromDatabase(HealthRecord record) async {
    try {
      loading = true;
      notifyListeners();
      await _repo.delete(record);
      records.removeWhere((r) => r.id == record.id);
    } catch (e) {
      // handle/log
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> updateRecordInDatabase(HealthRecord record) async {
    try {
      loading = true;
      notifyListeners();
      await _repo.update(record); // Ensure repo has an update method
      // Update the record in-memory as well
      int index = records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        records[index] = record; // Replace the old record with the updated one
      }
    } catch (e) {
      // handle/log
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
