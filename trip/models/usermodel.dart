class UserModel {
  int? userId; // Nullable UserId, similar to the C# model
  String userName;
  String email;
  String mobileNo;
  bool isActive;

  // Constructor to initialize the UserModel with named parameters
  UserModel({
    this.userId,
    required this.userName,
    required this.email,
    required this.mobileNo,
    required this.isActive,
  });

  // Factory constructor to create a UserModel from JSON (useful for API calls)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['UserId'],
      userName: json['UserName'],
      email: json['Email'],
      mobileNo: json['MobileNo'],
      isActive: json['IsActive'],
    );
  }

  // Method to convert UserModel to JSON format (useful for sending data to an API)
  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'UserName': userName,
      'Email': email,
      'MobileNo': mobileNo,
      'IsActive': isActive,
    };
  }
}
