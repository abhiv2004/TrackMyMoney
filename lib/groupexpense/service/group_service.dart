// lib/services/group_service.dart
import '../database/groupdatabase.dart';

import '../model/participant_model.dart';

class GroupService {
  final db = GroupExpenseDB.instance;

  /// Create group and participants. Returns groupId.
  Future<int> createGroupWithParticipants({
    required String groupName,
    required List<ParticipantModel> participants,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final groupId = await db.addGroup(groupName, nowIso);

    for (final p in participants) {
      await db.addParticipant(
        groupId: groupId,
        name: p.participantName,
        imagePath: p.imagePath,
        mobile: p.mobile,
      );
    }

    return groupId;
  }

  /// Update group name and replace participants (simple strategy: delete existing participants then insert new)
  Future<void> updateGroupWithParticipants({
    required int groupId,
    required String newGroupName,
    required List<ParticipantModel> participants,
  }) async {
    await db.updateGroup(groupId, newGroupName);

    // delete existing participants for group
    final existing = await db.getParticipantsByGroup(groupId);
    for (final p in existing) {
      await db.deleteParticipant(p['participant_id'] as int);
    }

    // insert new participants
    for (final p in participants) {
      await db.addParticipant(
        groupId: groupId,
        name: p.participantName,
        imagePath: p.imagePath,
        mobile: p.mobile,
      );
    }
  }

  Future<Map<String, dynamic>?> getGroupWithParticipants(int groupId) async {
    final group = await db.getGroupById(groupId);
    if (group == null) return null;
    final participants = await db.getParticipantsByGroup(groupId);
    return {
      'group': group,
      'participants': participants,
    };
  }

  Future<List<Map<String, dynamic>>> getAllGroups() => db.getAllGroups();

  Future<void> deleteGroup(int groupId) => db.deleteGroup(groupId);
}
