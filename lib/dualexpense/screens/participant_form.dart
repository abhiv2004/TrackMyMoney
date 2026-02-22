import 'package:flutter/material.dart';
import '../database/database.dart';

class ParticipantForm extends StatelessWidget {
  final Map? participant;

  const ParticipantForm({super.key, this.participant});

  @override
  Widget build(BuildContext context) {
    TextEditingController nameC =
    TextEditingController(text: participant?["name"] ?? "");
    TextEditingController mobileC =
    TextEditingController(text: participant?["mobile"] ?? "");

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              participant == null ? "Add Participant" : "Update Participant",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: nameC,
              decoration: InputDecoration(
                labelText: "Name",
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: mobileC,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Mobile",
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel")),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () async {
                    if (nameC.text.isEmpty) return;

                    if (participant != null) {
                      await DualExpenseDB.instance.updateParticipant(
                        participant!["id"],
                        nameC.text,
                        mobile:
                        mobileC.text.isNotEmpty ? mobileC.text : null,
                      );
                    } else {
                      await DualExpenseDB.instance.addParticipant(
                        nameC.text,
                        mobile:
                        mobileC.text.isNotEmpty ? mobileC.text : null,
                      );
                    }

                    Navigator.pop(context, true);
                  },
                  child: const Text("Save"),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}