import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'OfferDetailsPage.dart';
import 'package:wave/config.dart';
import 'package:wave/wave.dart';
import 'package:google_fonts/google_fonts.dart';

class MyRidesPage extends StatefulWidget {
  final void Function(int) changeTab;

  const MyRidesPage({Key? key, required this.changeTab}) : super(key: key);

  @override
  _MyRidesPageState createState() => _MyRidesPageState();
}

class WaveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;

  const WaveAppBar({super.key, this.height = kToolbarHeight + 50.0});

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: preferredSize.height,
      child: Stack(
        children: [
          WaveWidget(
            config: CustomConfig(
              gradients: [
                [const Color.fromARGB(255, 255, 124, 1), Colors.orange],
                [
                  const Color.fromARGB(253, 255, 166, 0),
                  const Color.fromARGB(253, 255, 166, 0)
                ],
              ],
              durations: [15000, 9440],
              heightPercentages: [0.10, 0.30],
              gradientBegin: Alignment.bottomLeft,
              gradientEnd: Alignment.topRight,
            ),
            waveAmplitude: 0,
            size: Size(
              double.infinity,
              preferredSize.height,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 5.0),
              child: Text(
                'Мои превози',
                style: GoogleFonts.montserrat(
                  color: const Color.fromARGB(255, 34, 34, 34),
                  fontSize: 40.0,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyRidesPageState extends State<MyRidesPage> {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> _toggleFavorite(String offerId) async {
    var userRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);

    var userSnapshot = await userRef.get();
    if (userSnapshot.exists) {
      List favorites = userSnapshot.data()?['favorites'] ?? [];

      if (favorites.contains(offerId)) {
        favorites.remove(offerId); // Remove from favorites
      } else {
        favorites.add(offerId); // Add to favorites
      }

      await userRef.update({'favorites': favorites});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null || user!.isAnonymous) {
      return Scaffold(
        appBar: const WaveAppBar(),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(253, 255, 166, 0),
                Color.fromARGB(255, 228, 178, 40),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/logoSad.svg',
                      width: 180,
                      height: 180,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ве молиме',
                      style: GoogleFonts.montserrat(
                        color: const Color.fromARGB(255, 34, 34, 34),
                        fontSize: 23.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: Text(
                        'најавете се!',
                        style: GoogleFonts.montserrat(
                          color: const Color.fromARGB(255, 34, 34, 34),
                          fontSize: 23.0,
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const WaveAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(253, 255, 166, 0),
              Color.fromARGB(255, 228, 178, 40),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('offers')
                    .where('userId', isEqualTo: user!.uid)
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/logoTear.svg',
                                width: 180,
                                height: 180,
                              ),
                              Text(
                                'Немате ваши превози.',
                                style: GoogleFonts.montserrat(
                                  color: const Color.fromARGB(255, 34, 34, 34),
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.w900,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  widget.changeTab(2);
                                },
                                style: ElevatedButton.styleFrom(
                                  elevation: 8.0,
                                  foregroundColor: Colors.black,
                                  backgroundColor: Colors.white,
                                ),
                                child: Text(
                                  'Нов Превоз',
                                  style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  } else {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var ride = snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                        var offerId = snapshot.data!.docs[index].id;
                        var rideWithId = {'offer': ride, 'offerId': offerId};

                        // Format the date to show only the day, month, and year
                        var dateTime = ride['date'] != null
                            ? (ride['date'] as Timestamp).toDate().toLocal()
                            : DateTime.now().toLocal();
                        var formattedDate =
                            "${dateTime.day}.${dateTime.month}.${dateTime.year}";

                        // Get the price
                        var price = ride['price'] != null
                            ? "${ride['price']} ден."
                            : "Без цена";

                        return Card(
                          elevation: 8.0,
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            title: Text(
                                "${ride['departureCity']} > ${ride['arrivalCity']}"),
                            subtitle: Text("$formattedDate • $price"),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      OfferDetailsPage(offer: rideWithId),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Омилени',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData ||
                      !(snapshot.data!.data() as Map<String, dynamic>)
                          .containsKey('favorites') ||
                      (snapshot.data!.data()
                              as Map<String, dynamic>)['favorites']
                          .isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Немате омилени превози.',
                          style: GoogleFonts.montserrat(
                            color: const Color.fromARGB(255, 34, 34, 34),
                            fontSize: 20.0,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  } else {
                    var favorites = (snapshot.data!.data()
                        as Map<String, dynamic>)['favorites'] as List;
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        return StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('offers')
                              .doc(favorites[index])
                              .snapshots(),
                          builder: (context, offerSnapshot) {
                            if (offerSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (offerSnapshot.hasError) {
                              return Text('Error: ${offerSnapshot.error}');
                            } else if (!offerSnapshot.hasData ||
                                !offerSnapshot.data!.exists) {
                              return const SizedBox.shrink();
                            } else {
                              var ride = offerSnapshot.data!.data()
                                  as Map<String, dynamic>;
                              var offerId = offerSnapshot.data!.id;
                              var rideWithId = {
                                'offer': ride,
                                'offerId': offerId
                              };

                              // Format the date to show only the day, month, and year
                              var dateTime = ride['date'] != null
                                  ? (ride['date'] as Timestamp)
                                      .toDate()
                                      .toLocal()
                                  : DateTime.now().toLocal();
                              var formattedDate =
                                  "${dateTime.day}.${dateTime.month}.${dateTime.year}";

                              // Get the price
                              var price = ride['price'] != null
                                  ? "${ride['price']} ден."
                                  : "Без цена";

                              return Card(
                                elevation: 8.0,
                                margin: const EdgeInsets.only(bottom: 8.0),
                                child: ListTile(
                                  title: Text(
                                      "${ride['departureCity']} > ${ride['arrivalCity']}"),
                                  subtitle: Text("$formattedDate • $price"),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.favorite,
                                        color: Colors.red),
                                    onPressed: () {
                                      _toggleFavorite(offerId);
                                    },
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            OfferDetailsPage(offer: rideWithId),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
