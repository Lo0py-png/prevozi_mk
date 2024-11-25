import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'EditOfferPage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart'; // Import the login page
import 'package:permission_handler/permission_handler.dart';

class OfferDetailsPage extends StatelessWidget {
  final Map<String, dynamic> offerData;
  final String offerId;

  OfferDetailsPage({Key? key, required Map<String, dynamic> offer})
      : offerData = offer['offer'],
        offerId = offer['offerId'],
        super(key: key);

  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<String> getUserName(String userId) async {
    var userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userSnapshot.exists) {
      return userSnapshot.data()!['name'] ?? 'No name';
    } else {
      return 'No name';
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      status = await Permission.phone.request();
    }

    if (status.isGranted) {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        print('Could not launch $launchUri');
      }
    } else {
      print('Phone permission denied');
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      status = await Permission.sms.request();
    }

    if (status.isGranted) {
      final Uri launchUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
      );
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        print('Could not launch $launchUri');
      }
    } else {
      print('SMS permission denied');
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Потврди бришење'),
          content: const Text(
              'Дали сте сигурни дека сакате да ја избришете оваа понуда?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Откажи'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true);

                // Delete the document from Firestore
                await FirebaseFirestore.instance
                    .collection('offers')
                    .doc(offerId)
                    .delete();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Огласот е успешно избришан.')),
                );

                Navigator.of(context).pop(); // Go back to the previous screen
              },
              child: const Text('Избриши'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(offerId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Огласот е успешно избришан')),
      );

      Navigator.of(context).pop(); // Go back to the previous screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeString = offerData['time'] != null
        ? DateFormat('HH:mm').format(offerData['time'].toDate())
        : 'Not specified';

    // Format the date in Macedonian locale and use Montserrat font
    final String formattedDate = offerData['date'] != null
        ? DateFormat('EEEE, dd.MM.', 'mk').format(offerData['date'].toDate())
        : 'Date not specified';

    return Scaffold(
      appBar: PreferredSize(
        preferredSize:
            const Size.fromHeight(kToolbarHeight), // Standard AppBar height
        child: AppBar(
          backgroundColor: const Color.fromARGB(253, 255, 166, 0),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: Colors.black), // Set the back button color here
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: Text(
            formattedDate,
            style: GoogleFonts.montserrat(
              color: const Color.fromARGB(255, 34, 34, 34),
              fontSize: 25.0,
              fontWeight: FontWeight.w900,
            ),
          ),
          elevation: 0.0, // Customize as needed
        ),
      ),
      body: FutureBuilder<String>(
        future: getUserName(offerData['userId']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching driver name'));
          }

          String driverName = snapshot.data ?? 'Unavailable';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Од',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          Text(
                            '${offerData['departureCity']}',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(width: 75),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'До',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            Text(
                              '${offerData['arrivalCity']}',
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.visible,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Час',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.grey)),
                            Row(
                              children: [
                                const Icon(Icons.access_time,
                                    color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(timeString,
                                    style: const TextStyle(fontSize: 18)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('Слободни места',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.grey)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.group, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text('${offerData['seats']}',
                                    style: const TextStyle(fontSize: 18)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Цена',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.grey)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Icon(Icons.payments, color: Colors.grey),
                                const SizedBox(width: 2),
                                Text('${offerData['price']}den.',
                                    style: const TextStyle(fontSize: 18)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.grey),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Возач',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey)),
                            Row(
                              children: [
                                const Icon(Icons.person, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(driverName,
                                    style: const TextStyle(fontSize: 18)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Возило',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey)),
                            Row(
                              children: [
                                const Icon(Icons.directions_car,
                                    color: Colors.grey),
                                const SizedBox(width: 8),
                                Text('${offerData['carModel']}',
                                    style: const TextStyle(fontSize: 18)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPhoneNumberSection(context),
                  const SizedBox(height: 10),
                  const Divider(
                    color: Colors.grey,
                    thickness: 1,
                    height: 1,
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('Додатен опис',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ),
                      Icon(Icons.comment, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    offerData['description'] ?? 'No Description',
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.justify,
                  ),
                  const Divider(
                    color: Colors.grey,
                    thickness: 1,
                    height: 1,
                  ),
                  const SizedBox(height: 10),
                  _buildActionButtons(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhoneNumberSection(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      // User is not logged in, show the message with login link
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Телефон:',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 10),
          Row(
            children: [
              // This ensures that the text wraps to a new line if necessary
              Flexible(
                child: Text(
                  'Најавете се за да го видете телефонскиот број ',
                  style: GoogleFonts.montserrat(),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to the login page
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: Text(
                  'Најавете се',
                  style: GoogleFonts.montserrat(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // User is logged in, show the phone number
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Телефонски бр.',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          Row(
            children: [
              const Icon(Icons.phone, color: Colors.grey),
              const SizedBox(width: 8),
              Text(offerData['phoneNumber'] ?? 'Unavailable',
                  style: const TextStyle(fontSize: 18)),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;

    if (currentUserId == offerData['userId']) {
      // User is the owner of the offer, show Edit and Delete buttons
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditOfferPage(
                      offerData: offerData,
                      offerId: offerId,
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.blue),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Измени',
                    style: GoogleFonts.montserrat(
                        color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit, color: Colors.blue),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _confirmDelete(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Избриши',
                    style: GoogleFonts.montserrat(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.delete, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (isLoggedIn) {
      // User is logged in but not the owner, show the Call and SMS buttons
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _makePhoneCall(offerData['phoneNumber'] ?? ''),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.green),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Јави се',
                    style: GoogleFonts.montserrat(
                        color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.phone, color: Colors.green),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _sendSMS(offerData['phoneNumber'] ?? ''),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Прати SMS',
                    style: GoogleFonts.montserrat(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chat, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // User is not logged in, hide the buttons and show no extra text
      return const SizedBox.shrink();
    }
  }
}
