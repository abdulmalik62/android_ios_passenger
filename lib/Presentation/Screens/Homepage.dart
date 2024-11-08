import 'dart:async';

import 'package:android_ios_passenger/Constants/Apikey.dart';
import 'package:android_ios_passenger/Constants/Colours.dart';
import 'package:android_ios_passenger/Presentation/Screens/Confirmationpage.dart';
import 'package:android_ios_passenger/Presentation/Screens/Login.dart';
import 'package:android_ios_passenger/Presentation/Screens/Viewroute.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Profilepage.dart';

class Homepage extends StatefulWidget {
  final String Pickup;
  final String Drop;
  final String Name;
  final int Number;
  final String Location;
  final int PassengerId;
  final String CompanyName;
  final String Token;

  const Homepage({
    Key? key,
    required this.Pickup,
    required this.Drop,
    required this.Name,
    required this.Number,
    required this.Location,
    required this.PassengerId,
    required this.CompanyName,
    required this.Token
  }) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final Dio _dio = Dio();
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;
  bool _isSearching = false;
  String? _selectedPickupLocation;
  String? _selectedDropLocation;
  bool _isPickupSelected = false;
  bool _isDropSelected = false;
  List<Map<String, dynamic>> options = [];
  late String _routeDrop;
  late String _routepickup;
  late  bool isLoggedin =false;
  int? attendanceid;
  late int attendance=0;
  String? routePickup;
  String? routeDrop;
  String? RouteId;
  String? Stop;
  bool search = false;

  List<Map<String, dynamic>> jobCards = [];
  List<Map<String, dynamic>> filteredJobCards = [];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _fetchJobCards();
    _getDatafromCache();
  }


  Future<void> _getDatafromCache() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    attendanceid = prefs.getInt('attendanceId');
    routePickup = prefs.getString('routepickup').toString();
    routeDrop = prefs.getString('routedrop').toString();
    RouteId = prefs.getString('routeid').toString();
    Stop = prefs.getString('stop').toString();
  }

  Future<void> _logout() async {
    try {
      var headers = {'Authorization': 'Bearer ${widget.Token}'};
      const String apiUrl = '${ApiKey.baseUrl}/PassengerLogOut';
      final response = await _dio.delete(
          apiUrl,
          data: widget.Token,
          options: Options(
          headers: headers
      )
      );
      if (response.statusCode == 200) {
        print(response.data);
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(),
          ),
        );
      }
      return ;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(),
        ),
      );
    }
  }

  Future<void> _fetchJobCards() async {
    _searchController.clear();
    print("${widget.Token}");
    var headers = {'Authorization': 'Bearer ${widget.Token}'};
    try {
      String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String apiUrl = '${ApiKey.baseUrl}/CompanyBasedRoute?companyname=${widget.CompanyName}&date=$currentDate';
       // Format current date
      final response = await _dio.get(
          apiUrl,
        options: Options(
          headers: headers
        )
      );
      if (response.statusCode == 200) {
        print(response.data);
        setState(() {
          jobCards = List<Map<String, dynamic>>.from(response.data);
        });
        _filterJobCards("");
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to load job cards',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
        );
      }
    } catch (e) {
      print(e);
      if (e is DioError && e.response != null) {
        Fluttertoast.showToast(
          msg: '${e.response!.data['message']}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
        );
      }
    }
  }

  Future<void> _showPicker(BuildContext context, String title, Function(String) onSelected, String routeId,String titl32,bool allowbooking) async {
    var headers = {'Authorization': 'Bearer ${widget.Token}'};
    try {
      String apiUrl = '${ApiKey.baseUrl}/GetStopsBasedRouteId?routeId=$routeId';
      final response = await _dio.get(
          apiUrl,
        options: Options(
          headers: headers
        )
      );

      if (response.statusCode == 200) {
        setState(() {
          options = List<Map<String, dynamic>>.from(response.data);
          // Extract the route_drop value
          if (options.isNotEmpty) {
            _routeDrop = options[0]['route_id']['route_drop'];
            _routepickup = options[0]['route_id']['route_pickup'];
          }
        });
      }
    } catch (e) {
      print(e);
    }
    Map<String, dynamic> tempSelectedLocation = options[0];

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Row(
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              Spacer(),
              CupertinoButton(
                padding: EdgeInsets.all(8.0),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Close',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
          actions: [
            Container(
              height: 250,
              child: CupertinoPicker(
                itemExtent: 32.0,
                onSelectedItemChanged: (int index) {
                  tempSelectedLocation = options[index];
                },
                children: options.map((option) => Center(child: Text(option['stop_name'] as String))).toList(),
              ),
            ),
            if(allowbooking!=true)
              CupertinoActionSheetAction(
                onPressed: () {
                  onSelected(tempSelectedLocation['stop_name'] as String);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => view
                        (
                        routeDrop: _routeDrop,
                        routePickup: _routepickup,
                        Stop: tempSelectedLocation['stop_name'] as String,
                        RouteId: routeId,
                        AttendanceId: attendance,
                      ),
                    ),
                  );

                },
                child: Text('View Route', style: TextStyle(color: Colors.blue)),
              ),
            if(allowbooking)
              CupertinoActionSheetAction(
                onPressed: () {
                  onSelected(tempSelectedLocation['stop_name'] as String);
                  _navigateToNextPage(routeId);
                  Navigator.pop(context);
                },
                child: Text('Confirm Booking', style: TextStyle(color: Colors.blue)),
              ),
          ],
        );
      },
    );
  }

  void _cancelPickupSelection() {
    setState(() {
      _selectedPickupLocation = null;
      _isPickupSelected = false;
    });
  }

  void _cancelDropSelection() {
    setState(() {
      _selectedDropLocation = null;
      _isDropSelected = false;
    });
  }

  void _filterJobCards(String query) {
    if (query.isEmpty) {
      print("object");


    }else{
      print("object2");
      setState(() {
        filteredJobCards = jobCards;
      });
    }

    List<Map<String, dynamic>> filtered = jobCards.where((job) {
      final routeId = job['route_id'].toString().toLowerCase();
      final pickup = job['route_pick_up'].toString().toLowerCase();
      final drop = job['route_drop'].toString().toLowerCase();
      final startTime = job['route_start_time'].toString().toLowerCase();
      final endTime = job['route_end_time'].toString().toLowerCase();
      final Data = job['schedule_date'].toString();
      final bool booking = job['allow_booking'];

      final searchQuery = query.toLowerCase();
      return routeId.contains(searchQuery) ||
          pickup.contains(searchQuery) ||
          drop.contains(searchQuery) ||
          startTime.contains(searchQuery)||endTime.contains(searchQuery);
    }).toList();

    setState(() {
      filteredJobCards = filtered;
    });

    return;


  }

  Future<void> _navigateToNextPage(String routeID) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    var headers = {'Authorization': 'Bearer $token'};

    if(_selectedPickupLocation == null && _selectedDropLocation == null){
      Fluttertoast.showToast(
        msg: 'Please Select any Locations',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
      );
    }else{
      if(_selectedPickupLocation != null){
        print(routeID);

        try{
          String apiUrl = '${ApiKey.baseUrl}/PassengerAttendance';
          final response = await _dio.post(
            apiUrl,
            data: {
              "passenger_id":widget.PassengerId,
              "route_id":routeID,
              "stop_name":_selectedPickupLocation,
              "date":formattedDate,
              "status":"started"
            },
            options: Options(
              headers: headers
            )
          );
          if(response.statusCode==200){
            print(response.data);
            attendance = response.data['attendanceId'];
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setInt('attendanceId', attendance);
            await prefs.setString('stop', _selectedPickupLocation.toString());
            await prefs.setString('routepickup', _routepickup);
            await prefs.setString('routedrop', _routeDrop);
            await prefs.setString("routeid", routeID);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Confirmation
                  (
                  routeDrop: _routeDrop,
                  routePickup: _routepickup,
                  RouteId: routeID,
                  Stop:_selectedPickupLocation,
                  AttendanceId: attendance, RefreshCached: () { _getDatafromCache(); },
                ),
              ),
            ).then((_) {
              // Add a post frame callback to ensure the context is valid
              WidgetsBinding.instance.addPostFrameCallback((_) {
                initState();
              });
            });
          }

        }catch (e){
          print(e);
          if (e is DioError && e.response != null) {
            Fluttertoast.showToast(
              msg: '${e.response!.data['message']}',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.TOP,
            );
          }
        }
      }
    }


  }
//if passenger booked the trip come back to homepage the Show stop need not to show
  void _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? attendanceid = prefs.getInt('attendanceId');
    print("attendacnce ID : $attendanceid");
    if (attendanceid != null) {
      setState(() {
        isLoggedin = true;
      });
    }
  }
  void _gotonextpage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? attendanceid = prefs.getInt('attendanceId');
    String routePickup = prefs.getString('routepickup').toString();
    String routeDrop = prefs.getString('routedrop').toString();
    String RouteId = prefs.getString('routeid').toString();
    String Stop = prefs.getString('stop').toString();
    if (attendanceid != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => Confirmation(
                routeDrop: routeDrop,
                routePickup: routePickup,
                RouteId: RouteId,
                Stop: Stop,
                AttendanceId: attendanceid, RefreshCached: () { _getDatafromCache(); },
            )
        ),
      );
    }
  }

  Widget _buildCurrentTripCard() {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).size.height *0.67),
      child: GestureDetector(
        onTap: (){
          _gotonextpage();
        },
        child: Column(
          children: [
            Card(
              color: Colours.orange,
              margin: EdgeInsets.all(8.0),
              child: ListTile(
                title: Center(child: Text('Your Current Trip',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Route ID: $RouteId',style: TextStyle(color: Colors.white),),
                    Text('Pickup Location: $routePickup',style: TextStyle(color: Colors.white),),
                    Text('Drop Location: $routeDrop',style: TextStyle(color: Colors.white),),
                    Text('Selected Stop: $Stop',style: TextStyle(color: Colors.white),),
                    SizedBox(height: 10,),
                    Center(child: Text('Tap this card to view the Route Page',style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold),)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<bool> _onWillPop() async {
    return true;
  }
  @override
  Widget build(BuildContext context) {
    String profileName = '${widget.Name}';
    String profileInitials = profileName.length >= 1 ? profileName.substring(0, 1).toUpperCase() : '';
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colours.orange,
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(Icons.person,color: Colours.white,),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PassengerProfilePage(
                        name: profileName,
                        number: widget.Number,
                        pickup: widget.Pickup,
                        drop: widget.Drop,
                        company: widget.CompanyName, location: widget.Location, token: widget.Token,
                      ))
                  );
                },
              );
            },
          ),
          actions: [
            IconButton(onPressed: (){
              print("Refresh");
              _fetchJobCards();
            }, icon: Icon(Icons.refresh))
          ],
        ),

        body: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width *1,
              height: MediaQuery.of(context).size.height *1,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.only(left: 10, top: 8,right: 10),
                      child: SizedBox(
                        height: 50,
                        width: MediaQuery.of(context).size.height *0.4,
                        child: TextFormField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            suffixIcon: search?IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                search =false;
                                setState(() {
                                  _searchQuery = '';
                                  _filterJobCards('');
                                });
                              },
                            ):null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintText: 'Search',
                          ),
                          onChanged: (value) {
                            setState(() {
                              search =true;
                              _searchQuery = value;
                              _filterJobCards(value);
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: filteredJobCards.length,
                      itemBuilder: (context, index) {
                        final jobCard = filteredJobCards[index];
                        final routeDrop = jobCard['route_drop'] as String;
                        final routePickup = jobCard['route_pick_up'] as String;
                        final routeStartTime = jobCard['route_start_time'] as String;
                        final routeEndTime = jobCard['route_end_time'] as String;
                        final routeId = jobCard['route_id'].toString();
                        final routedate = jobCard['schedule_date'].toString();
                        final bool routebook = jobCard['allow_booking'];
                        return Padding(
                          padding: const EdgeInsets.only(left: 20.0,right: 20.0),
                          child: Card(
                            margin: EdgeInsets.all(8.0),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Text('$routeId',style: TextStyle(fontWeight: FontWeight.bold),),
                                  Spacer(),
                                  Text('$routedate',style: TextStyle(fontWeight: FontWeight.bold),),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Tooltip(
                                            message :  '$routePickup',
                                            child: Text(
                                              '$routePickup',
                                              style: TextStyle(fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis, // Adds "..." if the text is too long
                                              maxLines: 1, // Ensures it's a single line
                                              softWrap: false, // Prevents wrapping to multiple lines
                                            ),
                                          ),
                                        ),
                                        Spacer(),
                                        Icon(Icons.arrow_right_alt_rounded),
                                        Spacer(),
                                        Expanded(
                                          child: Tooltip(
                                            message: '$routeDrop',
                                            child: Text(
                                              '$routeDrop',
                                              style: TextStyle(fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis, // Adds "..." if the text is too long
                                              maxLines: 1, // Ensures it's a single line
                                              softWrap: false, // Prevents wrapping to multiple lines
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20,),
                                    Row(
                                      children: [
                                        Text('$routeStartTime'),
                                        Spacer(),
                                        Text('$routeEndTime'),
                                      ],
                                    ),
                                    Divider(),
                                    GestureDetector(
                                      onTap: () {
                                        print("Clicked Show Stops");
                                        _showPicker(context, 'Select your Pickup Location', (String selectedLocation) {
                                          setState(() {
                                              _selectedPickupLocation = selectedLocation;
                                              _isPickupSelected = true;
                                          });
                                          }, jobCard['route_id'], jobCard['route_drop'], routebook);
                                        },
                                      child: Container(padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),child: Text('Show Stops', style: TextStyle(color: Colours.green,fontSize: 16,fontWeight: FontWeight.bold))),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            isLoggedin ?  _buildCurrentTripCard():
            Text(""),
          ],
        ),
      ),
    );
  }
}

