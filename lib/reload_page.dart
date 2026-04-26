import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReloadPage extends StatefulWidget {
  @override
  _ReloadPageState createState() => _ReloadPageState();
}

class _ReloadPageState extends State<ReloadPage> {
  // We use this controller to read the amount the user types into the text field or to automatically fill it when they tap a quick option.
  final amountController = TextEditingController();
  // This variable helps us show a loading indicator on the button so the user doesn't press it multiple times while waiting for the database.
  bool isLoading = false;

  // This function handles the core logic of increasing the user's wallet balance directly in the database.
  Future<void> processReload() async {
    // First, we extract the text from the input field and remove any empty spaces around it.
    String inputAmount = amountController.text.trim();
    
    if (inputAmount.isEmpty) {
      showMessage("Please enter an amount to reload.");
      return;
    }

    // We attempt to convert the text into a decimal number. If the user typed letters or invalid symbols, this becomes null.
    double? amountToAdd = double.tryParse(inputAmount);
    
    if (amountToAdd == null || amountToAdd <= 0) {
      showMessage("Please enter a valid positive number.");
      return;
    }

    // We turn on the loading state to show the user that we are processing their request.
    setState(() => isLoading = true);

    try {
      // We grab the unique ID of the currently logged in user from Firebase Authentication.
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // We directly update the 'users' collection in Firestore. 
      // Using FieldValue.increment is the safest way to add money because it mathematically adds to the current value safely on the server.
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'wallet': FieldValue.increment(amountToAdd),
      });

      // We also save a record of this transaction in the 'transactions' collection so it will appear in their history later.
      await FirebaseFirestore.instance.collection('transactions').add({
        'userId': uid,
        'amount': amountToAdd,
        'type': 'topup',
        'createdAt': Timestamp.now(),
      });

      // After successfully updating everything, we show a success message.
      await showMessage("Reload successful! RM ${amountToAdd.toStringAsFixed(2)} added.");
      
      // Finally, we close the reload page and automatically return the user to the profile page.
      Navigator.pop(context);

    } catch (e) {
      // If the database encounters any error (like a network drop), we catch it here and inform the user.
      showMessage("Something went wrong. Please try again.");
    }

    // We make sure to turn off the loading indicator no matter if the operation succeeded or failed.
    setState(() => isLoading = false);
  }

  // This helper function changes the text inside the input box when the user taps one of the preset value buttons.
  void setAmount(double amount) {
    // We format the amount to two decimal places (like 50.00) and place it in the text field.
    amountController.text = amount.toStringAsFixed(2);
    // This part moves the blinking typing cursor to the very end of the text so the user doesn't get confused.
    amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: amountController.text.length),
    );
  }

  // A standardized helper function to display simple pop-up alert dialogs with messages.
  Future<void> showMessage(String msg) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Message"),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("OK"))
        ],
      ),
    );
  }

  // This widget builder helps us generate the uniform buttons for the quick preset amounts without writing the same style code repeatedly.
  Widget buildQuickOption(double amount) {
    return ElevatedButton(
      onPressed: () => setAmount(amount),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text("RM ${amount.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The Scaffold sets up the basic visual structure of our page with a dark background.
    return Scaffold(
      backgroundColor: Color(0xFF020617),
      
      // The AppBar sits at the top providing a title and a back button. We make it transparent to blend with the background.
      appBar: AppBar(
        title: Text("Reload Wallet"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // This is the instructional label above the text input field.
            Text(
              "Enter amount to reload",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            
            SizedBox(height: 12),
            
            // This container holds our main text input field. It has a slightly lighter dark grey background to make it visible.
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFF111827),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: amountController,
                // We bring up a number keyboard that allows typing decimal points.
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  // We place 'RM' as a permanent prefix inside the text box so the user knows what currency they are typing.
                  prefixText: "RM ",
                  prefixStyle: TextStyle(color: Colors.blueAccent, fontSize: 28, fontWeight: FontWeight.bold),
                  border: InputBorder.none,
                  hintText: "0.00",
                  hintStyle: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ),
            
            SizedBox(height: 40),
            
            // This label introduces the section for our pre-filled quick options.
            Text(
              "Quick Select",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            
            SizedBox(height: 16),
            
            // The Wrap widget acts like a row, but if it runs out of horizontal space on the phone screen, it pushes the remaining items to a new line automatically.
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                buildQuickOption(50),
                buildQuickOption(100),
                buildQuickOption(200),
                buildQuickOption(500),
                buildQuickOption(1000),
              ],
            ),
            
            SizedBox(height: 50),
            
            // This is the primary action button located at the bottom of the page. It stretches across the full width.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // If the app is currently talking to the database, we disable the button so it can't be clicked again.
                onPressed: isLoading ? null : processReload,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                // We swap the text out for a circular progress spinner if the system is busy loading.
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Confirm Reload",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}