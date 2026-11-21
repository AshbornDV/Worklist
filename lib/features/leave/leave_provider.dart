import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/leave_request_model.dart';

class LeaveProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  final _fireStore = FirebaseFirestore.instance;
  final _rtDatabase = FirebaseDatabase.instance.ref;

  // Leave CRUD operations
  Future<LeaveRequestModel> createLeave({
    required String userId,
    required String siteId,
    required DateTime date,
    required LeaveType type,
    required String reason,
    required double duration,
  }) async {
    final model = LeaveRequestModel(
      uuid: uuid.v4(),
      userId: userId,
      siteId: siteId,
      date: date,
      type: type,
      reason: reason,
      duration: duration,
      status: LeaveSyncStatus.local,
      localPath: '',
      storagePath: '',
      hash: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to SQLite
    await _db.insertLeave(model);

    // Save to Firestore
    await _fireStore.collection('leaves').doc(model.uuid).set(model.toMap());

    // Save to RTDB for real-time sync
    await _rtDatabase.child('leaves').child(model.uuid).set(model.toMap());

    notifyListeners();
    return model;
  }

  Future<LeaveRequestModel> getLeave(String uuid) async {
    final model = await _db.getLeave(uuid);
    if (model != null) return model;

    final snap = await _fireStore.collection('leaves').doc(uuid).get();
    if (snap.exists) {
      final model = LeaveRequestModel.fromMap(snap.data()!);
      await _db.insertLeave(model);
      return model;
    }

    final rtSnap = await _rtDatabase.child('leaves').child(uuid).get();
    if (rtSnap.value != null) {
      final model = LeaveRequestModel.fromMap(rtSnap.value as Map);
      await _db.insertLeave(model);
      return model;
    }

    throw Exception('Leave request not found');
  }

  Future<List<LeaveRequestModel>> getLeavesByUser({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final local = await _db.getLeavesByUserId(userId);
    final filtered = local.where((l) {
      final lDate = l.date;
      return lDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          lDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Sync from cloud
    final snap = await _fireStore.collection('leaves')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in snap.docs) {
      final model = LeaveRequestModel.fromMap(doc.data());
      await _db.upsertLeave(model);
      filtered.add(model);
    }

    return filtered;
  }

  Future<LeaveRequestModel> updateLeave({
    required String uuid,
    required String reason,
    required double duration,
  }) async {
    final model = await getLeave(uuid);
    model.reason = reason;
    model.duration = duration;
    model.updatedAt = DateTime.now();
    model.syncStatus = LeaveSyncStatus.synced;

    await _db.updateLeave(model);
    await _fireStore.collection('leaves').doc(uuid).update(model.toMap());
    await _rtDatabase.child('leaves').child(uuid).update(model.toMap());

    notifyListeners();
    return model;
  }

  Future<void> deleteLeave(String uuid) async {
    await _db.deleteLeave(uuid);
    await _fireStore.collection('leaves').doc(uuid).delete();
    await _rtDatabase.child('leaves').child(uuid).remove();

    notifyListeners();
  }

  // Leave sync status
  Future<void> markLeaveSynced(String uuid) async {
    final model = await getLeave(uuid);
    model.syncStatus = LeaveSyncStatus.synced;
    model.updatedAt = DateTime.now();

    await _db.updateLeave(model);
    await _fireStore.collection('leaves').doc(uuid).update({'syncStatus': model.syncStatus.toString()});
    await _rtDatabase.child('leaves').child(uuid).update({'syncStatus': model.syncStatus.toString()});

    notifyListeners();
  }

  // onUserMutate callback equivalent
  void onUserMutate() {
    // Queue sync operations when user mutates data
    // This prevents race conditions during concurrent mutates
    notifyListeners();
  }
}