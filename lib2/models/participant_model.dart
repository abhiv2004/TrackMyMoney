import 'dart:io';

class ParticipantModel {
  int? participantId;
  int? groupId;
  String name;
  String? mobile;
  String? imagePath;

  ParticipantModel({
    this.participantId,
    this.groupId,
    required this.name,
    this.mobile,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'participant_id': participantId,
      'group_id': groupId,
      'participant_name': name,
      'mobile': mobile,
      'image': imagePath,
    };
  }

  factory ParticipantModel.fromMap(Map<String, dynamic> map) {
    return ParticipantModel(
      participantId: map['participant_id'],
      groupId: map['group_id'],
      name: map['participant_name'],
      mobile: map['mobile'],
      imagePath: map['image'],
    );
  }
}
