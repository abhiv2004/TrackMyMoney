import 'package:billtracker/personalexpense/screens/yearlyreport.dart';
import 'package:flutter/material.dart';
import '../database/personaldatabase.dart';

class HierarchicalReportPage extends StatefulWidget {
  @override
  State<HierarchicalReportPage> createState() =>
      _HierarchicalReportPageState();
}

class _HierarchicalReportPageState extends State<HierarchicalReportPage> {
  /// year -> month -> total
  Map<int, Map<String, double>> data = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  Future<void> loadReport() async {
    final expenses = await MyPersonalExpenseDB.instance.getExpenses();

    Map<int, Map<String, double>> temp = {};

    for (var e in expenses) {
      final date = DateTime.parse(e['date']);
      final year = date.year;
      final month =
          "${date.month.toString().padLeft(2, '0')}";

      temp.putIfAbsent(year, () => {});
      temp[year]![month] =
          (temp[year]![month] ?? 0) + e['amount'];
    }

    setState(() {
      data = temp;
      isLoading = false;
    });
  }

  double getYearlyTotal(Map<String, double> months) {
    return months.values.fold(0.0, (sum, item) => sum + item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xff1f1c2c), Color(0xff928dab)],
              ),
            ),
          ),
          Positioned( top: -100, right: -80, child: Container( height: 240, width: 240, decoration: BoxDecoration( color: Colors.white.withOpacity(0.08), shape: BoxShape.circle, ), ), ),
          SafeArea(
            child: Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: const [
                      Text(
                        "Yearly Report",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // CONTENT
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView(
                      children: data.entries.map((yearEntry) {
                        int year = yearEntry.key;
                        double yearlyTotal =
                        getYearlyTotal(yearEntry.value);

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => YearlyExpenseListPage(year: year),
                              ),
                            ).then((_) {
                              loadReport(); // ✅ Refresh when coming back
                            });
                          },
                          child: Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(
                                vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 20),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "$year",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff1f2937),
                                    ),
                                  ),
                                  Text(
                                    "₹${yearlyTotal.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xff16a34a),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
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
