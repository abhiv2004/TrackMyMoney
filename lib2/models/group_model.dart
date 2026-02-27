class GroupModel {
  int? groupId;
  String name;
  String? date;

  GroupModel({
    this.groupId,
    required this.name,
    this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'group_id': groupId,
      'group_name': name,
      'date': date,
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      groupId: map['group_id'],
      name: map['group_name'],
      date: map['date'],
    );
  }
}
