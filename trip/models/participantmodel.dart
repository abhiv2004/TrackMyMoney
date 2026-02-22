class Participant {
  int? participantId;
  int tripId;
  String participantName;
  String? participantImage;
  String mobileNo;
  String email;


  Participant({
    this.participantId,
    required this.tripId,
    required this.participantName,
    this.participantImage,
    required this.mobileNo,
    required this.email,

  });

  // From JSON
  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      participantId: json['participantId'] as int,
      tripId: json['tripId'] as int,
      participantName: json['participantName'] as String,
      participantImage: json['participantImage'] as String,
      mobileNo: json['mobileNo'] as String,
      email: json['email'] as String,

    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'participantId': participantId,
      'tripId': tripId,
      'participantName': participantName,
      'participantImage': participantImage,
      'mobileNo': mobileNo,
      'email': email,

    };
  }
}
