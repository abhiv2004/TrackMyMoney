import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tripexpense/screens/tripdetailsscreen.dart';
import '../api_helper/apihelper.dart';
import '../models/tripdetailsdatamodel.dart';
import '../models/tripmodel.dart';
import '../utils/colors.dart';
import '../utils/strings.dart';
import '../widgets/customsweetalert.dart';
import '../widgets/navigateWithAnimation.dart';
import 'forms/loginform.dart';
import 'forms/tripformscreen.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';


class HomeScreen extends StatefulWidget {

  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TripModel> _trips = [];
  List<TripModel> _filteredTrips = [];
  Map<int, double> _totalSpentMap = {};
  bool _isLoadingTrip = true;
  bool _isLoading = false;
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  int userId =0 ;
  String username = '';
  String email = '';
  String token = '';
  double _totalAmount = 0.0;


  @override
  void initState() {
    super.initState();
    _loadUserDataAndFetchTrips();
  }

  void _loadUserDataAndFetchTrips() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    username = prefs.getString('username') ?? '';
    email = prefs.getString('email') ?? '';
    token = prefs.getString('token') ?? '';

    if (userId != 0 && token != null) {
      try {
        List<TripModel> trips = await ApiService().fetchTripsByUserId(userId);
        Map<int, double> totalSpentMap = {};

        for (var trip in trips) {
          final expenses = await ApiService().fetchExpensesByTripId(trip.tripId!);
          _totalAmount = 0.0;

          for (var expense in expenses) {
            if(expense.expenseName != "Settlement"){
              _totalAmount += expense.amount;
            }
          }
          double totalAmount = _totalAmount;
          totalSpentMap[trip.tripId!] = totalAmount;
        }

        setState(() {
          _trips = trips;
          _filteredTrips = trips;
          _totalSpentMap = totalSpentMap;  // Store total spent separately
          _isLoadingTrip = false;
        });
      } catch (e) {
        setState(() {
          _isLoadingTrip = false;
        });
      }
    } else {
      setState(() {
        _isLoadingTrip = false;
      });
    }
  }

  void _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    showCustomSweetAlert(context, "Logout Successed.", "success", () {
      navigateWithAnimation(context, LoginScreen());
    });
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Account"),
          content: const Text("Are you sure you want to delete your account? This action cannot be undone."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final success = await ApiService().deleteAccount(userId); // Call the delete method with the userId
                if (success) {
                  showCustomSweetAlert(context, "Delete Account!.", "warning", () {
                    Navigator.pop(context);
                  });
                  _logout(context); // Log out the user after account deletion
                } else {
                  Navigator.pop(context); // Close the dialog
                  _showErrorMessage(context); // Show an error message if deletion failed
                }
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }


  void _showErrorMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to delete the account. Please try again.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _openSearch() {
    setState(() {
      _isSearching = !_isSearching; // Toggle search bar
      if (!_isSearching) {
        _searchController.clear(); // Clear search when closing
        _filteredTrips = _trips; // Reset trip list
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.teal,
            iconTheme: IconThemeData(color: Colors.white),
            title: Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Trip',
                      style: TextStyle(
                        fontFamily: 'Cursiv',  // Applying cursive font
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: ' Tally',
                      style: TextStyle(
                        fontFamily: 'Cursiv',
                        color: Colors.orangeAccent,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadUserDataAndFetchTrips,
              ),
            ],
          ),
          drawer: _buildDrawer(),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.only(left: 15, right: 15, top: 30),
                  child: _isLoadingTrip
                      ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                      : _buildTripList(),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              setState(() => _isLoading = true);
              rippleEffect(context, AddEditTripForm(tripDetails: null), Offset.zero);
              setState(() => _isLoading = false);
            },
            icon: Icon(Icons.add, color: Colors.white),
            label: Text(
              AppStrings.addtrip,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.teal,
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54, // Semi-transparent background
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                backgroundColor: Colors.grey,
                strokeWidth: 5.0,
              ),
            ),
          ),
      ],
    );
  }

// --- Search Bar ---
  Widget _buildSearchBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Your Trips",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _isSearching ? 230 : 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isSearching ? 1.0 : 0.0,
            child: _isSearching
                ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search Trips...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close,color: Colors.teal,),
                  onPressed: _openSearch,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(10),
              ),
              onChanged: (query) {
                setState(() {
                  _filteredTrips = _trips
                      .where((trip) =>
                      trip.tripName.toLowerCase().contains(query.toLowerCase()))
                      .toList();
                });
              },
            )
                : null,
          ),
        ),
        if (!_isSearching)
          IconButton(
            icon: Icon(Icons.search, color: Colors.teal),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredTrips = _trips;
                }
              });
            },
          ),
      ],
    );
  }

// --- Trip List ---
  Widget _buildTripList() {
    return _filteredTrips.isEmpty
        ? const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'No trips available!!',
            style: TextStyle(fontSize: 16 ,fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          Text(
            'use \"+ Add Trip\" button to add new trip.',
            style: TextStyle(fontSize: 16 ,fontWeight: FontWeight.bold, color: Colors.teal),
          ),
        ],
      ),
    )
        : ListView.builder(
      itemCount: _filteredTrips.length,
      itemBuilder: (context, index) {
        TripModel trip = _filteredTrips[index];
        double totalSpent = _totalSpentMap[trip.tripId!] ?? 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(5),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(5),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: displayImage(trip.tripImage),
            ),
            title: Text(
              trip.tripName,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            subtitle: Text(
              'Total Spent: \$${totalSpent.toStringAsFixed(2)}\n'
                  'Created on: ${DateFormat('dd-MM-yyyy').format(trip.createdDate)}',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: GestureDetector(
              onTapDown: (TapDownDetails details) async {
                if (totalSpent > 0.0) {
                  showCustomAlert(context);
                } else {
                  setState(() => _isLoading = true);
                  TripDetailsData? tripsdetail = await ApiService().fetchTripDetailsData(trip.tripId!);
                  rippleEffect(context, AddEditTripForm(tripDetails: tripsdetail), details.globalPosition);
                  setState(() => _isLoading = false);
                }
              },
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.edit, color: Colors.white),
              ),
            ),
            onTap: () async {
              final result = await navigateWithAnimation(
                context,
                TripDetailsPage(tripId: trip.tripId!, tripName: trip.tripName),
              );

              if (result == true) {  // Check if something was changed in TripDetailsPage
                setState(() {
                  _isLoading = true;
                });

                _loadUserDataAndFetchTrips();


                setState(() {
                  _isLoading = false;
                });
              }
            },

            onLongPress: () {
              _confirmDelete(context, trip.tripId);
            },
          ),
        );
      },
    );
  }


  Widget displayImage(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(30), // Circular shape
        child: Image.asset(
          'assets/images/splash.png',
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      );
    }
    try {
      Uint8List imageBytes = base64Decode(base64Image);
      return ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.memory(
          imageBytes,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      );
    } catch (e) {
      return const Icon(Icons.error, size: 50);
    }
  }

  void _confirmDelete(BuildContext context, int? tripId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Trip'),
          content: const Text('Are you sure you want to delete this trip?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                bool success = await ApiService().deleteTrip(tripId);
                if (success) {
                  setState(() {
                    _trips.removeWhere((trip) => trip.tripId == tripId);
                    _filteredTrips = _trips;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trip deleted successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete trip')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void showCustomAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            "Information",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info, color: Colors.blue, size: 50),
              SizedBox(height: 10),
              Text(
                "Hello User,\n You can not update this trip\n because your expense is started.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Colors.teal,
            ),
            accountName: Text(username),
            accountEmail: Text(email),
            currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.person, size: 40),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  title: const Text("Delete Account"),
                  leading: const Icon(Icons.delete),
                  onTap: () {
                    _confirmDeleteAccount(context);
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text("Log Out"),
            leading: const Icon(Icons.exit_to_app),
            onTap: () {
              _logout(context);
            },
          ),
        ],
      ),
    );
  }

}
