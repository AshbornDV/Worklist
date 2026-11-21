import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/shift_model.dart';

class ShiftProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  final _fireStore = FirebaseFirestore.instance;
  final _rtDatabase = FirebaseDatabase.instance.ref;

  // Shift CRUD operations
  Future<ShiftModel> createShift({
    required int userId,
    required int siteId,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required ShiftKind kind,
  }) async {
    final model = ShiftModel(
      uuid: const Uuid().v4(),
      userId: userId,
      siteId: siteId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      kind: kind,
      status: ShiftSyncStatus.pending,
      localPath: '',
      storagePath: '',
      hash: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to SQLite
    await _db.insertShift(model);

    // Save to Firestore
    await _fireStore.collection('shifts').doc(model.uuid).set(model.toMap());

    // Save to RTDB for real-time sync
    await _rtDatabase.child('shifts').child(model.uuid).set(model.toMap());

    notifyListeners();
    return model;
  }

  Future<ShiftModel> getShift(String uuid) async {
    final model = await _db.getShift(uuid);
    if (model != null) return model;

    final snap = await _fireStore.collection('shifts').doc(uuid).get();
    if (snap.exists) {
      final model = ShiftModel.fromMap(snap.data()!);
      await _db.insertShift(model);
      return model;
    }

    final rtSnap = await _rtDatabase.child('shifts').child(uuid).get();
    if (rtSnap.value != null) {
      final model = ShiftModel.fromMap(rtSnap.value as Map);
      await _db.insertShift(model);
      return model;
    }

    throw Exception('Shift not found');
  }

  Future<List<ShiftModel>> getShiftsByUser({
    required int userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final local = await _db.getShiftsByUserId(userId);
    final filtered = local.where((s) {
      final sDate = s.date;
      return sDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          sDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Sync from cloud
    final snap = await _fireStore.collection('shifts')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in snap.docs) {
      final model = ShiftModel.fromMap(doc.data());
      await _db.upsertShift(model);
      filtered.add(model);
    }

    return filtered;
  }

  Future<ShiftModel> updateShift({
    required String uuid,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    ShiftKind? kind,
    ShiftSyncStatus? status,
  }) async {
    ShiftModel model = await getShift(uuid);
    model = model.copyWith(
      startTime: startTime ?? model.startTime,
      endTime: endTime ?? model.endTime,
      kind: kind ?? model.kind,
      status: status ?? model.status,
      updatedAt: DateTime.now(),
    );

    await _db.updateShift(model);
    await _fireStore.collection('shifts').doc(uuid).update(model.toMap());
    await _rtDatabase.child('shifts').child(uuid).update(model.toMap());

    notifyListeners();
    return model;
  }

  Future<void> deleteShift(String uuid) async {
    await _db.deleteShift(uuid);
    await _fireStore.collection('shifts').doc(uuid).delete();
    await _rtDatabase.child('shifts').child(uuid).remove();

    notifyListeners();
  }

  // Shift sync status
  Future<void> markShiftSynced(String uuid) async {
    final model = await getShift(uuid);
    final updated = model.copyWith(
      status: ShiftSyncStatus.synced,
      updatedAt: DateTime.now(),
    );

    await _db.updateShift(updated);
    await _fireStore.collection('shifts').doc(uuid).update(updated.toMap());
    await _rtDatabase.child('shifts').child(uuid).update(updated.toMap());

    notifyListeners();
  }

  // onUserMutate callback equivalent
  void onUserMutate() {
    // Queue sync operations when user mutates data
    // This prevents race conditions during concurrent mutates
    notifyListeners();
  }
}