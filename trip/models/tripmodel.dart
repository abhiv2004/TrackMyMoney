class TripModel {
  final int? tripId;
  final String tripName;
  final String? tripImage;
  final DateTime createdDate;
  final DateTime? modifiedDate;
  final int userId;

  TripModel({
    this.tripId,
    required this.tripName,
    this.tripImage,
    required this.createdDate,
    this.modifiedDate,
    required this.userId,

  });

  // Factory method to create a TripModel from a JSON object
  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      tripId: json['tripId'],
      tripName: json['tripName'],
      tripImage: json['tripImage'],
      createdDate: DateTime.parse(json['createdDate']),
      modifiedDate: json['modifiedDate'] != null
          ? DateTime.parse(json['modifiedDate'])
          : null,
      userId: json['userId'],
    );
  }

  // Method to convert TripModel into a Map for API request
  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'tripName': tripName,
      'tripImage': tripImage,
      'createdDate': createdDate.toIso8601String(),
      'modifiedDate': modifiedDate?.toIso8601String(),
      'userId': userId,
    };
  }
}
