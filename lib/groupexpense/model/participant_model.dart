// lib/models/participant_model.dart
class ParticipantModel {
  int? participantId;
  int groupId;
  String participantName;
  String mobile;
  String? imagePath; // store file path

  ParticipantModel({
    this.participantId,
    required this.groupId,
    required this.participantName,
    required this.mobile,
    this.imagePath,
  });

  factory ParticipantModel.fromMap(Map<String, dynamic> m) => ParticipantModel(
    participantId: m['participant_id'] as int?,
    groupId: m['group_id'] as int,
    participantName: m['participant_name'] as String,
    mobile: m['mobile'] as String,
    imagePath: m['image'] as String?,
  );

  Map<String, dynamic> toMap() => {
    if (participantId != null) 'participant_id': participantId,
    'group_id': groupId,
    'participant_name': participantName,
    'mobile': mobile,
    'image': imagePath,
  };
}
