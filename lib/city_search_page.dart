import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Make sure this path is correct

class CitySearchPage extends StatefulWidget {
  final List<String> cities;

  const CitySearchPage({Key? key, required this.cities}) : super(key: key);

  @override
  _CitySearchPageState createState() => _CitySearchPageState();
}

class _CitySearchPageState extends State<CitySearchPage> {
  String filter = "";

  @override
  Widget build(BuildContext context) {
    List<String> filteredCities = widget.cities
        .where((city) => city.toLowerCase().contains(filter.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize:
            const Size.fromHeight(kToolbarHeight), // Standard AppBar height
        child: AppBar(
          backgroundColor: const Color.fromARGB(253, 255, 166, 0),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: Colors.black), // Set the back button color here
            onPressed: () => Navigator.of(context)
                .pop(), // This will pop the current screen off the navigation stack
          ),
          centerTitle: true,
          title: Text(
            'Одберете град', // Translated to Macedonian
            style: GoogleFonts.montserrat(
              color: const Color.fromARGB(255, 34, 34, 34),
              fontSize: 25.0,
              fontWeight: FontWeight.w900,
            ),
          ),
          elevation: 0.0, // Customize as needed
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Пребарај', // Translated to Macedonian
                labelStyle: GoogleFonts.montserrat(
                  // Applying Montserrat font to the search label
                  fontSize: 18.0,
                  color: Colors.black, // You can customize the color if needed
                ),
                suffixIcon: const Icon(Icons.search),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (value) {
                setState(() {
                  filter = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredCities.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    filteredCities[index],
                    style: GoogleFonts.montserrat(
                      // Applying Montserrat font to city names
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing:
                      const Icon(Icons.location_city), // Icon for each city
                  onTap: () {
                    Navigator.pop(context, filteredCities[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
