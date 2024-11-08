import 'dart:async';
import 'dart:convert';

import 'package:android_ios_passenger/Constants/Apikey.dart';
import 'package:android_ios_passenger/Constants/Colours.dart';
import 'package:android_ios_passenger/Presentation/Screens/Homepage.dart';
import 'package:android_ios_passenger/Presentation/Screens/Onboardedpage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

class Onboard extends StatefulWidget {
  final String RouteId;
  final String? routeDrop;
  final String? routePickup;
  final String? Stop;
  final double Latitude;
  final double Lonitude;
  final String Vehicle;
  final int AttendanceId;
  final bool onboard;

  const Onboard({
    Key? key,
    required this.RouteId,
    required this.routeDrop,
    required this.routePickup,
    required this.Stop,
    required this.Latitude,
    required this.Lonitude,
    required this.Vehicle,
    required this.AttendanceId,
    required this.onboard
  }) : super(key: key);

  @override
  State<Onboard> createState() => _OnboardState();
}

class _OnboardState extends State<Onboard> {
  LatLng? _startLatLng;
  LatLng? _endLatLng;
  LatLng? _stopLatLng;
  LatLng? LiveData;
  List<LatLng> _routePoints = [];
  Timer? _timer;
  Timer? _timers;
  final String mapboxApiKey = "${ApiKey.Key}";
  final String mapboxGeocodingUrl = "https://api.mapbox.com/geocoding/v5/mapbox.places/";
  late bool isOnboarded;
  bool isTripend = false;
  final _feedbackController = TextEditingController();
  double? _estimatedTimeInSeconds;


  @override
  void initState() {
    isOnboarded =widget.onboard;
    LiveData = LatLng(widget.Latitude, widget.Lonitude);
    super.initState();
    _getCoordinatesFromAddresses();
    _fetchTimepickup();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      FetchTrip();
      _fetchJobCards();
      FetchTripstatus();
      _fetchTimepickup();
      checkpassengerAttendance();
    });
    _timers = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchJobCards();
    });
  }


  Future<void> checkpassengerAttendance() async {

    print("Check Passenger Attendance Function");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    int? id = prefs.getInt("attendanceId");
    print(token);
    print(id);
    var headers = {'Authorization': 'Bearer $token'};
    final Dio _dio = Dio();
    print(widget.RouteId);
    try {
      String apiUrl = '${ApiKey.baseUrl}/CheckPassengerAttendance?attendanceid=$id';
      final response = await _dio.get(
          apiUrl,
          options: Options(
              headers: headers
          )
      );

      if (response.statusCode == 200) {
        print(response.data);
        if (mounted) {  // Check if the widget is still mounted
          setState(() {
            isOnboarded = true; // Corrected assignment operator
          });
        }
      }
    } catch (e) {

      print(e);
    }
  }

  void _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    int? Passid = prefs.getInt('passenger_id');
    String Pickup = prefs.getString('pickup').toString();
    String Drop = prefs.getString('drop').toString();
    String Name = prefs.getString('name').toString();
    int Phone = int.parse(prefs.getInt('phone').toString());

    String Location = prefs.getString('location').toString();
    String Company = prefs.getString('company').toString();
    await prefs.remove('attendanceId');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Homepage(
          Pickup: Pickup,
          Drop: Drop,
          Name: Name,
          Number: Phone,

          Location: Location,
          PassengerId: Passid!,
          CompanyName: Company,
          Token: token!,
        ),
      ),
    );
  }

  Future<void> _sendFeedback() async {
    final Dio _dio = Dio();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    int? id = prefs.getInt("attendanceId");
    var headers = {'Authorization': 'Bearer $token'};
    try {
      String apiUrl = '${ApiKey.baseUrl}/PassengerFeedback';
      final response = await _dio.post(
        apiUrl,
        data: {
          'attendanceId': id,
          'feedback': _feedbackController.text,
        },
        options: Options(
          headers: headers,
        ),
      );
      if (response.statusCode == 200) {
        print(response.data);
        Navigator.of(context).pop();
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.flatColored,
          title: Text("Thank you"),
          description: Text("Feedback Sent Successfully"),
          alignment: Alignment.center,
          autoCloseDuration: const Duration(seconds: 5),
          showProgressBar: true,
          dragToClose: true,
          applyBlurEffect: true,
        );
        _feedbackController.clear();

      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> FetchTrip() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    var headers = {'Authorization': 'Bearer $token'};
    final Dio _dio = Dio();
    print(widget.RouteId);
    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      String apiUrl = '${ApiKey.baseUrl}/GetTripDetailsBasedRouteId?routeId=${widget.RouteId}&date=$formattedDate';
      final response = await _dio.get(
        apiUrl,
        options: Options(
          headers: headers,
        ),
      );
      if (response.statusCode == 200) {
        print(response.data);
        print(response.data['latitude']);
        print(response.data['longitude']);
        final double LiveLat = response.data['latitude'];
        final double LiveLong = response.data['longitude'];
        print("Live Lat :$LiveLat");
        print("Live Long : $LiveLong");
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('lat', LiveLat);
        await prefs.setDouble("long", LiveLong);

        setState(() {
          LiveData = LatLng(LiveLat, LiveLong);
        });

      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> onBoard() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    int? id = prefs.getInt("attendanceId");
    await prefs.setString('Onboard', "OnBoarded");

    print("pass_id:$id");
    var headers = {'Authorization': 'Bearer $token'};
    final Dio _dio = Dio();
    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      String apiUrl = '${ApiKey.baseUrl}/PassengerOnboarded';
      final response = await _dio.post(
        apiUrl,
        data: {
          "id": id,
          'status': 'Onboarded',
        },
        options: Options(
          headers: headers,
        ),
      );
      if (response.statusCode == 200) {
        print(response.data);
        setState(() {
          isOnboarded = true;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> isOnboardeds() async{


  }

  Future<void> _fetchJobCards() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    var headers = {'Authorization': 'Bearer $token'};
    final Dio _dio = Dio();
    try {
      String apiUrl = '${ApiKey.baseUrl}/EmergencyMessage?attendanceId=${widget.AttendanceId}'; // Format current date
      final response = await _dio.get(
          apiUrl,
          options: Options(
              headers: headers
          )
      );

      if (response.statusCode == 200) {
        _timers!.cancel();
        toastification.show(
          context: context,
          type: ToastificationType.info,
          style: ToastificationStyle.flatColored,
          description: Text("${response.data}"),
          alignment: Alignment.topRight,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: highModeShadow,
          dragToClose: true,
        );
      }
    } catch (e) {
      print(e);
    }
  }

  void _showFeedbackForm() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.orange[200]!, // Border color
                  width: 2.0, // Border width
                ),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                  Center(
                    child: Text(
                      "Feedback",
                      style: TextStyle(fontWeight: FontWeight.bold,fontSize: 25),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child:  SingleChildScrollView(
                      child: Form(
                        child: Material(
                          child: Container(
                            padding: EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _feedbackController,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8.0),
                                            borderSide: BorderSide(color: Colors.orange[200]!),

                                          ),
                                          contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                                        ),
                                        maxLines: 5, // Make the feedback field big
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your feedback';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 21),
                                ElevatedButton(
                                  onPressed: () {
                                    _sendFeedback();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colours.orange,
                                  ),
                                  child: const Text(
                                    'Send',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white,fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _getCoordinatesFromAddresses() async {
    final pickup = widget.routePickup;
    final drop = widget.routeDrop;
    final stop = widget.Stop;

    try {
      String startAddressUrl = "$mapboxGeocodingUrl${Uri.encodeComponent(pickup!)}.json?access_token=$mapboxApiKey";
      String endAddressUrl = "$mapboxGeocodingUrl${Uri.encodeComponent(drop!)}.json?access_token=$mapboxApiKey";
      String StopAddressUrl = "$mapboxGeocodingUrl${Uri.encodeComponent(stop!)}.json?access_token=$mapboxApiKey";

      var startResponse = await http.get(Uri.parse(startAddressUrl));
      var endResponse = await http.get(Uri.parse(endAddressUrl));
      var StopResponse = await http.get(Uri.parse(StopAddressUrl));

      if (startResponse.statusCode == 200 && endResponse.statusCode == 200 && StopResponse.statusCode == 200) {
        var startData = jsonDecode(startResponse.body);
        var endData = jsonDecode(endResponse.body);
        var StopData = jsonDecode(StopResponse.body);

        if (startData['features'].isNotEmpty && endData['features'].isNotEmpty && StopData['features'].isNotEmpty) {
          double startLatitude = startData['features'][0]['center'][1];
          double startLongitude = startData['features'][0]['center'][0];

          double endLatitude = endData['features'][0]['center'][1];
          double endLongitude = endData['features'][0]['center'][0];

          double stopLatitude = StopData['features'][0]['center'][1];
          double stopLongtitude = StopData['features'][0]['center'][0];

          _startLatLng = LatLng(startLatitude, startLongitude);
          _endLatLng = LatLng(endLatitude, endLongitude);
          _stopLatLng = LatLng(stopLatitude, stopLongtitude);

          await _fetchRoute();

          setState(() {});
        }
      } else {
        print('Error getting coordinates: ${startResponse.statusCode} ${endResponse.statusCode} ${startResponse.statusCode}');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _fetchRoute() async {
    if (_startLatLng == null || _endLatLng == null) return;

    String directionsUrl =
        'https://api.mapbox.com/directions/v5/mapbox/driving/${_startLatLng!.longitude},${_startLatLng!.latitude};${_endLatLng!.longitude},${_endLatLng!.latitude}?geometries=geojson&overview=full&access_token=$mapboxApiKey';
    try {
      final response = await http.get(Uri.parse(directionsUrl));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var route = data['routes'][0]['geometry']['coordinates'] as List;
        var polylinePoints = route.map((point) => LatLng(point[1], point[0])).toList();
        setState(() {
          _routePoints = polylinePoints;
          _estimatedTimeInSeconds = data['routes'][0]['duration'];
        });
        _formatDuration(_estimatedTimeInSeconds);
      } else {
        print('Error fetching route: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
  }

  Future<void> _fetchTimepickup() async {
    if (_startLatLng == null || _endLatLng == null) return;
    String directionsUrl;

    if(LiveData == _stopLatLng){
      directionsUrl = 'https://api.mapbox.com/directions/v5/mapbox/driving/${LiveData!.longitude},${LiveData!.latitude};${_endLatLng!.longitude},${_endLatLng!.latitude}?geometries=geojson&overview=full&access_token=$mapboxApiKey';
    }else{
       directionsUrl = 'https://api.mapbox.com/directions/v5/mapbox/driving/${_stopLatLng!.longitude},${_stopLatLng!.latitude};${LiveData!.longitude},${LiveData!.latitude}?geometries=geojson&overview=full&access_token=$mapboxApiKey';
    }

    try {
      final response = await http.get(Uri.parse(directionsUrl));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var route = data['routes'][0]['geometry']['coordinates'] as List;
        setState(() {
          _estimatedTimeInSeconds = data['routes'][0]['duration'];
        });
        _formatDuration(_estimatedTimeInSeconds);
      } else {
        print('Error fetching route: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
  }

  Future<void> _fetchTimeArrival() async {
    if (_startLatLng == null || _endLatLng == null) return;

    String directionsUrl =
        'https://api.mapbox.com/directions/v5/mapbox/driving/${LiveData!.longitude},${LiveData!.latitude};${_endLatLng!.longitude},${_endLatLng!.latitude}?geometries=geojson&overview=full&access_token=$mapboxApiKey';
    try {
      final response = await http.get(Uri.parse(directionsUrl));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var route = data['routes'][0]['geometry']['coordinates'] as List;
        setState(() {
          _estimatedTimeInSeconds = data['routes'][0]['duration'];
        });
        _formatDuration(_estimatedTimeInSeconds);
      } else {
        print('Error fetching route: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
  }

  Widget _buildInputField(
      {TextEditingController? controller,
        String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: "Your Message",
        hintStyle: TextStyle(color: Colours.grey),
        contentPadding: EdgeInsets.symmetric(vertical: 50.0, horizontal: 12.0), // Adjust these values to increase the size of the text box
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.orange[200]!),

        ),
      ),
      minLines: 1,
      maxLines: 4,
      validator: validator,
    );
  }

  String _formatDuration(double? durationInSeconds) {
    if (durationInSeconds == null) return 'N/A';

    int hours = (durationInSeconds ~/ 3600);
    int minutes = ((durationInSeconds % 3600) ~/ 60);

    if (hours > 0) {
      return '$hours hr $minutes min';
    } else {
      return '$minutes min';
    }
  }


  Future<void> FetchTripstatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    var headers = {'Authorization': 'Bearer $token'};
    final Dio _dio = Dio();
    print(widget.RouteId);
    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      String apiUrl = '${ApiKey.baseUrl}/GetTripDetailsBasedRouteId?routeId=${widget.RouteId}&date=$formattedDate';
      final response = await _dio.get(
          apiUrl,
          options: Options(
              headers: headers
          )
      );

      if (response.statusCode == 200) {

        print(response.data);
        print(response.data['vehicle_id']['vehicle_number']);
        print(response.data['latitude']);
        print(response.data['longitude']);
        final double LiveLat = response.data['latitude'];
        final double LiveLong = response.data['longitude'];
        final String Vehicle = response.data['vehicle_id']['vehicle_number'];
        final String Status = response.data['trip_status'];
        print(LiveLat);
        print(LiveLong);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('lat', LiveLat);
        await prefs.setDouble("long", LiveLong);
        await prefs.setString('vehicle', Vehicle);
        print(Status);
      }
    } catch (e) {
      _timer!.cancel();
      setState(() {
        isTripend =true;
      });
      print(e);
    }
  }


  @override
  void dispose() {
    super.dispose();
    _timer!.cancel();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              FetchTripstatus();
              FetchTrip();
              _fetchJobCards();
              _fetchTimeArrival();
            },
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_startLatLng != null && _endLatLng != null)
            FlutterMap(
              options: MapOptions(
                initialZoom: 10.0,
                center: LiveData,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=$mapboxApiKey',
                  additionalOptions: {
                    'accessToken': mapboxApiKey,
                    'id': 'mapbox.streets',
                  },
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.0,
                      color: Colors.black,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: _startLatLng!,
                      child: Container(
                        child: Icon(Icons.location_on, color: Colors.red),
                      ),
                    ),
                    Marker(
                      point: _stopLatLng!,
                      child: Container(
                        child: Icon(Icons.location_on, color: Colors.blue),
                      ),
                    ),
                    Marker(
                      width: 180.0,
                      height: 180.0,
                      point: _endLatLng!,
                      child: Container(
                        height: 100,
                        child: Icon(Icons.location_on, color: Colors.green),
                      ),
                    ),
                    Marker(
                      width: 50.0,
                      height: 50.0,
                      point: LiveData!,
                      child: Image.asset(
                        "assets/bus_icon.png",
                        height: MediaQuery.of(context).size.height * 0.2,
                        width: MediaQuery.of(context).size.width * 0.1,
                      ),
                    ),

                  ],
                ),
              ],
            ),
          Positioned(
            left: MediaQuery.of(context).size.width * 0.055,
            bottom: MediaQuery.of(context).size.height * 0.05,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.89,
              height: MediaQuery.of(context).size.height * 0.23,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colours.white,
                border: Border.all(color: Colours.black),
              ),
              child: Column(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.95,
                    height: MediaQuery.of(context).size.height * 0.10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          child: Image.asset(
                            "assets/bus.png",
                            height: MediaQuery.of(context).size.height * 0.4,
                            width: MediaQuery.of(context).size.width * 0.2,
                          ),
                        ),
                        Positioned(
                          bottom: MediaQuery.of(context).size.height * 0.05,
                          left: MediaQuery.of(context).size.width * 0.195,
                          child: Column(
                            children: [
                              Text(
                                widget.Vehicle,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: MediaQuery.of(context).size.height * 0.03,
                          left: MediaQuery.of(context).size.width * 0.195,
                          child: Column(
                            children: [
                              Text(
                                "Vehicle Number",
                                style: TextStyle(fontSize: 10),
                              )
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: MediaQuery.of(context).size.height * 0.05,
                          left: MediaQuery.of(context).size.width * 0.58,
                          child: Column(
                            children: [
                              Text(
                                "${widget.RouteId}",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: MediaQuery.of(context).size.height * 0.03,
                          left: MediaQuery.of(context).size.width * 0.63,
                          child: Column(
                            children: [
                              Text(
                                "RouteID",
                                style: TextStyle(fontSize: 10),
                              )
                            ],
                          ),
                        ),
                        Positioned(
                            bottom: MediaQuery.of(context).size.height * 0.001,
                            left: MediaQuery.of(context).size.width * 0.20,
                            child: Text("Estimated Time : ${_formatDuration(_estimatedTimeInSeconds)}",
                              style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),))
                      ],
                    ),
                  ),
                  isOnboarded
                      ? isTripend ?
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Center(
                      child: Column(
                        children: [
                          Text("Hope You Enjoyed !!",
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colours.orange)),
                          Text("Your valuable feedback would be greatly appreciated.",
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colours.black)),
                        ],
                      ),
                    ),
                  )
                      :Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Center(
                      child: Column(
                        children: [
                          TextButton(
                            onPressed: () {
                              if(LiveData == _endLatLng){
                                setState(() {
                                  isTripend = true;
                                });
                              }else{
                                Fluttertoast.showToast(
                                  msg: "You Haven't Reach your Destination",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.TOP,
                                );
                              }

                            },
                            child: Text("Your ride is starting",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colours.orange)),
                          )
                        ],
                      ),
                    ),
                  ): Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            "Hit 'OK' Once you are Boarded",
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  ),
                  isOnboarded
                      ? isTripend
                      ? Padding(
                    padding: const EdgeInsets.only(top: 11.0),
                    child: ElevatedButton(
                      onPressed: () {
                        _checkLoginStatus();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colours.orange,
                        foregroundColor: Colours.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        minimumSize: Size(MediaQuery.of(context).size.width * 0.02, 0),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        child: Text(
                          "Back to Home",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ): Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            "Have a safe journey!",
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  ) : Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: ElevatedButton(
                      onPressed: () {
                        onBoard();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colours.orange,
                        foregroundColor: Colours.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        minimumSize: Size(MediaQuery.of(context).size.width * 0.02, 0),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        child: Text(
                          "ok",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isTripend?Colours.orange:Colours.grey,
        onPressed: isTripend?_showFeedbackForm:null,
        child: Column(
          children: [
            Icon(CupertinoIcons.chat_bubble_2_fill),
            Text("Feedback",style: TextStyle(color: Colors.black,fontSize: 10,),maxLines: 4,)
          ],
        ),
      ),
    );
  }
}
