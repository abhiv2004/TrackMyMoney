import 'package:billtracker/dualexpense/screens/accounts.dart';
import 'package:flutter/material.dart';
import 'groupexpense/screens/grouplistpage.dart';
import 'personalexpense/screens/personalexpense.dart';

class Homepage extends StatefulWidget {
  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND DESIGN
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xffeef2f3),
                  Color(0xffdfe9f3),
                ],
              ),
            ),
          ),

          // TOP SHAPE
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // BOTTOM SHAPE
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              height: 260,
              width: 260,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // MAIN CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DASHBOARD HEADER
                  Text(
                    "Dashboard",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Track & manage your expenses",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // GRID
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 11,
                      mainAxisSpacing: 11,
                      childAspectRatio: 1.5,
                      children: [
                        StyledGridCard(
                          title: "Personal Expenses",
                          icon: Icons.account_balance_wallet,
                          gradient: const LinearGradient(
                            colors: [Color(0xff6a11cb), Color(0xff2575fc)],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => PersonalExpensePage()),
                            );
                          },
                        ),
                        StyledGridCard(
                          title: "Give / Receive",
                          icon: Icons.people_alt_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xff11998e), Color(0xff38ef7d)],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => Accountspage()),
                            );
                          },
                        ),
                        StyledGridCard(
                          title: "Group Expense",
                          icon: Icons.groups_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xffff512f), Color(0xffdd2476)],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => GroupsPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StyledGridCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Gradient gradient;

  const StyledGridCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Stack(
        children: [
          // MAIN CARD
          Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),

          // BACKGROUND CIRCLE DECOR
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // CONTENT
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ICON BADGE
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: Colors.black87,
                  ),
                ),

                const Spacer(),

                // TITLE
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
