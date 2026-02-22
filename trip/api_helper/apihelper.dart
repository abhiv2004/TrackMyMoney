import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripexpense/models/expensesplitmodel.dart';
import 'package:tripexpense/models/participantmodel.dart';
import 'package:tripexpense/models/expensesmodel.dart';
import 'package:tripexpense/models/tripdetailsdatamodel.dart';
import 'package:tripexpense/models/tripmodel.dart';



class ApiService {

  late String baseUrl;

  // Constructor to initialize baseUrl based on platformxcm
  ApiService() {
    baseUrl =  _getBaseUrl();
   }

  // Method to determine the base URL based on platform
  String _getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://192.168.129.249:5215/api/';
    } else if (Platform.isIOS) {
      return 'http://localhost:5215/api/';
    } else if(Platform.isWindows) {
      return 'http://localhost:5215/api/';
    }else{
      return 'http://localhost:5215/api/';
    }
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  //--------------------------------------------Users Apis------------------------------------------------------------------

  // Register User
  Future<Map<String, dynamic>> registerUser(String username, String email, String password, String mobile) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}User/register'),
        body: json.encode({
          'UserName': username,
          'Email': email,
          'Password': password,
          'MobileNo': mobile,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Success
        return json.decode(response.body); // Returns the response data as a Map
      } else {
        // Failure

        return {'message': 'Registration failed', 'error': response.body};
      }
    } catch (e) {

      return {'message': 'Error: $e'};
    }
  }

  // Login User
  Future<Map<String, dynamic>> loginUser(String usernameOrEmail, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}User/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userNameOrEmail': usernameOrEmail,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // Success
        return json.decode(response.body);
      } else {

        return {'message': 'Login failed', 'error': response.body , 'code' : response.statusCode};
      }
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  //Delete Account
  Future<bool> deleteAccount(int? userId) async {
    final Uri url = Uri.parse('${baseUrl}User/delete/$userId');
    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        return true;
      } else {
        // Handle non-200 responses
        return false;
      }
    } catch (e) {
      // Handle any errors that occur during the HTTP request

      return false;
    }
  }

  Future<List<Map<String, dynamic>>> findAccount(String usernameOrEmail) async {
    final response = await http.get(Uri.parse("${baseUrl}Account/findaccount/$usernameOrEmail"));

    if (response.statusCode == 200) {
      try {
        var data = json.decode(response.body);

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map<String, dynamic>) {
          return [data]; // Wrap single user object in a list
        } else {
          throw Exception("Unexpected response format");
        }
      } catch (e) {
        throw Exception("Error parsing response: $e");
      }
    } else {
      throw Exception("Failed to fetch account. Status Code: ${response.statusCode}");
    }
  }

  Future<bool> sendOTP(String email) async {
    final response = await http.post(
      Uri.parse("${baseUrl}Account/send-otp"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(email),
    );

    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  Future<bool> verifyOTP(String usernameOrEmail, String otp) async {
    final response = await http.post(
      Uri.parse("${baseUrl}Account/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(otp),
    );

    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  Future<bool> resetPassword(String username, String email, String newPassword) async {
    final response = await http.put(
      Uri.parse("${baseUrl}Account/reset-password"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "UserName": username,
        "Email": email,
        "NewPassword": newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  Future<bool> recoverAccount(int userId, String username, String password) async {
    final response = await http.post(
      Uri.parse("${baseUrl}User/recover"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "userName": username,
        "password": password,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode <= 299  ) {
      return true;
    } else {
      return false;
    }
  }

  //--------------------------------------------Fetch Apis------------------------------------------------------------------

  // Trips By User Id
  Future<List<TripModel>> fetchTripsByUserId(int userId) async {
    // Get the token
    String? token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('${baseUrl}Trip/user/$userId'),
      headers: {
        'Authorization': 'Bearer $token',  // Add JWT token to the header
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((trip) => TripModel.fromJson(trip)).toList();
    } else {
      throw Exception('Failed to load trips: ${response.body}');
    }
  }


  //Trip Details By Trip Id  (includes --> Trips,Participants,Expenses,ExpenseSplit)
  Future<TripDetailsData> fetchTripDetailsData(int tripId) async {
    String? token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('${baseUrl}Trip/trip/$tripId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return TripDetailsData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load trip data');
    }
  }

// Participants By TripId
  Future<List<Participant>> fetchParticipantsByTripId(int tripId) async {
    String? token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    try {
      final response = await http.get(
        Uri.parse('${baseUrl}Participant/getByTripId/$tripId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data as List).map((json) => Participant.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load participants. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching participants: $e');
    }
  }

// Participants DropDown By TripId
  Future<List<Map<String, dynamic>>> fetchParticipantsDropDownByTripId(int tripId) async {

    String? token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final url = Uri.parse('${baseUrl}Participant/getDropDownByTripId/$tripId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((participant) {
          return {
            'participantId': participant['participantId'],
            'participantName': participant['participantName'],
          };
        }).toList();
      } else {
        throw Exception('Failed to load participants. Status code: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error fetching participants: $error');
    }
  }

// Expenses By TripId
  Future<List<Expense>> fetchExpensesByTripId(int tripId) async {

    String? token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    try {
      final response = await http.get(
        Uri.parse('${baseUrl}Expense/getByTripId/$tripId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data as List).map((json) => Expense.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load expenses. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching expenses: $e');
    }
  }

// ExpenseSplit By ExpenseId
  Future<List<ExpenseSplit>> fetchExpensesSplitByExpenseId(int expenseId) async {
    String? token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    try {
      final response = await http.get(
        Uri.parse('${baseUrl}ExpenseSplit/GetByExpenseId/$expenseId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data as List).map((json) => ExpenseSplit.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load expenses. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching expenses: $e');
    }
  }
  /*Future<List<ExpenseWithSplit>> fetchExpensesWithSplitByTripId(int tripId) async {
    try {
      final response = await http.get(Uri.parse('${baseUrl}Expense/getByTripId/$tripId/withSplit'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data as List).map((json) => ExpenseWithSplit.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load expenses. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching expenses: $e');
    }
  }*/

  //--------------------------------------------Insert Apis------------------------------------------------------------------


  //Insert Trip With Participate (both api called toghether.)
    // Insert Trip API
  Future<int?> insertTrip(String tripName, File? tripImage, int userId) async {
    String? token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final Uri url = Uri.parse('${baseUrl}Trip/insert');

    String? base64Image;
    if (tripImage != null) {
      List<int> imageBytes = await tripImage.readAsBytes();
      base64Image = base64Encode(imageBytes);
    }

    final Map<String, dynamic> data = {
      'tripName': tripName,
      'tripImage': base64Image,
      'userId': userId
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['tripId'];
      } else {
        throw Exception('Failed to insert trip');
      }
    } catch (e) {
      print('Error inserting trip: $e');
      return null;
    }
  }

  // Insert Participant API with authentication
  Future<bool> insertParticipant(int tripId, String name, String email, String mobile, File? participantImage) async {
    String? token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final Uri url = Uri.parse('${baseUrl}Participant/insert');

    String? base64Image;
    if (participantImage != null) {
      List<int> imageBytes = await participantImage.readAsBytes();
      base64Image = base64Encode(imageBytes);
    }

    final Map<String, dynamic> data = {
      'tripId': tripId,
      'participantName': name,
      'email': email,
      'mobileNo': mobile,
      'participantImage': base64Image,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        return true;
      } else {
        throw Exception('Failed to insert participant');
      }
    } catch (e) {
      print('Error inserting participant: $e');
      return false;
    }
  }

  // Insert Expense API with authentication
  Future<int?> insertExpense(String expenseName, double amount, int paidBy, String splitType, int tripId, String? description, DateTime expenseDate) async {
    String? token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final Uri url = Uri.parse('${baseUrl}Expense/insert');

    final Map<String, dynamic> data = {
      'expenseName': expenseName,
      'amount': amount,
      'paidBy': paidBy,
      'splitType': splitType,
      'tripId': tripId,
      'description': description,
      'expenseDate': expenseDate.toIso8601String(),
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        final responseData = json.decode(response.body);
        return responseData['expenseId'];
      } else {
        throw Exception('Failed to insert Expense');
      }
    } catch (e) {
      print('Error inserting Expense: $e');
      return null;
    }
  }

  // Insert ExpenseSplit API with authentication
  Future<bool> insertExpenseSplit(int expenseId, int participantId, double amount, int tripId) async {
    String? token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final Uri url = Uri.parse('${baseUrl}ExpenseSplit/insert');

    final Map<String, dynamic> data = {
      'expenseId': expenseId,
      'participantId': participantId,
      'amount': amount,
      'tripId': tripId,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        return true;
      } else {
        throw Exception('Failed to insert Expense Split');
      }
    } catch (e) {
      print('Error inserting Expense Split: $e');
      return false;
    }
  }


  //--------------------------------------------Update Apis------------------------------------------------------------------

  //Update Trip With Participate
  Future<bool> updateTrip(int tripId, String tripName, String? tripImageBase64,int userId) async {
    String? token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }
    final Uri url = Uri.parse('${baseUrl}Trip/update/$tripId');

    final Map<String, dynamic> data = {
      'tripId': tripId,
      'tripName': tripName,
      'tripImage': tripImageBase64,
      'userId' : userId
    };

    try {
      final response = await http.put(
        url,
          headers: {
            'Authorization': 'Bearer $token',  // Add JWT token to the header
            'Content-Type': 'application/json',
          },
        body: json.encode(data),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        return true; // Successfully updated trip
      } else {
        throw Exception('Failed to update trip');
      }
    } catch (e) {
      print('Error updating trip: $e');
      return false;
    }
  }

  Future<bool> updateParticipant(int participantId,int tripId, String name, String email, String mobile, String? participantImageBase64) async {
    String? token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final Uri url = Uri.parse('${baseUrl}Participant/update/$participantId');

    final Map<String, dynamic> data = {
      'participantId': participantId,
      'tripId':tripId,
      'participantName': name,
      'email': email,
      'mobileNo': mobile,
      'participantImage': participantImageBase64,  // Pass the image in base64 format
    };

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299){
        return true; // Successfully updated participant
      } else {
        throw Exception('Failed to update participant');
      }
    } catch (e) {
      print('Error updating participant: $e');
      return false;
    }
  }

  //Update Expenses with ExpenseSpilt with calculated splits for participants in Particular Trip
  //Update Expense
  Future<bool> updateExpense(int expenseId,String expenseName,double amount, int paidBy, String splitType,int tripId,String? description,DateTime expenseDate, ) async {
    String? token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final Uri url = Uri.parse('${baseUrl}Expense/update');

    final Map<String, dynamic> data = {
      'expenseId': expenseId, // Include the expenseId for updating
      'expenseName': expenseName,
      'amount': amount,
      'paidBy': paidBy,
      'splitType': splitType,
      'tripId': tripId,
      'description': description,
      'expenseDate': expenseDate.toIso8601String(),
    };

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        return true; // Indicate success
      } else {
        throw Exception('Failed to update Expense');
      }
    } catch (e) {
      print('Error updating Expense: $e');
      return false;
    }
  }
  //Update ExpenseSplit
  Future<bool> updateExpenseSplit(int splitId,int expenseId,int participantId,double amount,int tripId) async {
    String? token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final Uri url = Uri.parse('${baseUrl}ExpenseSplit/update');

    final Map<String, dynamic> data = {
      'splitId': splitId,
      'expenseId': expenseId,
      'participantId': participantId,
      'amount': amount,
      'tripId': tripId,
    };

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        return true; // Indicate success
      } else {
        throw Exception('Failed to update Expense Split');
      }
    } catch (e) {
      print('Error updating Expense Split: $e');
      return false;
    }
  }



  //--------------------------------------------Delete Apis------------------------------------------------------------------

  //Delete Trip With All Data
  Future<bool> deleteTrip(int? tripId) async {
    String? token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final Uri url = Uri.parse('${baseUrl}Trip/delete/$tripId');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',  // Add JWT token to the header
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        // Assuming 200 status means successful deletion
        return true;
      } else {
        // Handle non-200 responses
        print('Failed to delete trip. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      // Handle any errors that occur during the HTTP request
      print('Error deleting trip: $e');
      return false;
    }
  }
  // Delete Expense With Split
  Future<bool> deleteExpense(int? expenseId) async {
    String? token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final Uri url = Uri.parse('${baseUrl}Expense/delete/$expenseId');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        // Assuming 200 status means successful deletion
        return true;
      } else {
        // Handle non-200 responses
        print('Failed to delete Expense. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      // Handle any errors that occur during the HTTP request
      print('Error deleting Expense: $e');
      return false;
    }
  }
  //Delete ExpenseSplit
  Future<bool> deleteExpenseSplit(int splitId) async {
    String? token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    final Uri url = Uri.parse('${baseUrl}ExpenseSplit/delete/$splitId');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        // Assuming 200 status means successful deletion
        return true;
      } else {
        // Handle non-200 responses
        print('Failed to delete trip. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      // Handle any errors that occur during the HTTP request
      print('Error deleting trip: $e');
      return false;
    }
  }


  }
