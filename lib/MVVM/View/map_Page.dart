import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class OpenStreetMapScreen extends StatefulWidget {
  @override
  _OpenStreetMapScreenState createState() => _OpenStreetMapScreenState();
}

class _OpenStreetMapScreenState extends State<OpenStreetMapScreen> {
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();

  LatLng? fromLocation;
  LatLng? toLocation;
  double? distance;

  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  title: Text("Map"),
                  centerTitle: true,
                  expandedHeight: 250,
                  floating: true,
                  pinned: true,
                 
                  snap: true,
                  flexibleSpace: FlexibleSpaceBar(
                   titlePadding: EdgeInsets.all(23),
                    
                    background: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                
                          TextField(
                            controller: fromController,
                            decoration: InputDecoration(
                              labelText: "From (Enter Place Name)",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          TextField(
                            controller: toController,
                            decoration: InputDecoration(
                              labelText: "To (Enter Place Name)",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          SizedBox(
                            width: 150,
                            height: 45,
                            child: ElevatedButton(
                              style: ButtonStyle(backgroundColor:WidgetStatePropertyAll(Colors.blue)),
                              onPressed: (){
                                  FocusScope.of(context).unfocus();
                                  _updateRoute();
                              },
                              child: Text("Show Distance",style:TextStyle(color: Colors.white),),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: Column(
              children: [
                if (distance != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Distance: ${distance!.toStringAsFixed(2)} km",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                   Container(
                    height: 5,
                    width: 20,
                  decoration: BoxDecoration(color: Colors.grey,borderRadius: BorderRadius.circular(2)),
                  ),
                  SizedBox(height: 5),
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      onTap: (tapPosition, latLng) {
                        print("Map tapped at: $latLng");
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: ['a', 'b', 'c'],
                      ),
                      if (fromLocation != null && toLocation != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [fromLocation!, toLocation!],
                              strokeWidth: 4.0,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      if (fromLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: fromLocation!,
                              width: 80,
                              height: 80,
                              child: Icon(Icons.location_pin, color: Colors.green, size: 40),
                            ),
                          ],
                        ),
                      if (toLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: toLocation!,
                              width: 80,
                              height: 80,
                              child: Icon(Icons.location_pin, color: Colors.red, size: 40),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateRoute() async {
    String fromPlace = fromController.text.trim();
    String toPlace = toController.text.trim();

    if (fromPlace.isEmpty || toPlace.isEmpty) {
      _showError("Please enter both locations.");
      return;
    }

    LatLng? fromLatLng = await _getCoordinates(fromPlace);
    LatLng? toLatLng = await _getCoordinates(toPlace);

    if (fromLatLng == null || toLatLng == null) {
      _showError("Could not find locations. Try again.");
      return;
    }

    final Distance distanceCalculator = Distance();
    double calculatedDistance =
        distanceCalculator.as(LengthUnit.Kilometer, fromLatLng, toLatLng);

    setState(() {
      fromLocation = fromLatLng;
      toLocation = toLatLng;
      distance = calculatedDistance;
      _mapController.move(fromLocation!, 6.0);
    });
  }

  Future<LatLng?> _getCoordinates(String placeName) async {
    final url = "https://nominatim.openstreetmap.org/search?q=$placeName&format=json&limit=1";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        double lat = double.parse(data[0]["lat"]);
        double lon = double.parse(data[0]["lon"]);
        return LatLng(lat, lon);
      }
    }
    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
