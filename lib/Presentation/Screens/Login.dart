import 'package:android_ios_passenger/Constants/Apikey.dart';
import 'package:android_ios_passenger/Constants/Colours.dart';
import 'package:android_ios_passenger/Presentation/Screens/Homepage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Dio _dio = Dio();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _login() async {
    final String email = _usernameController.text;
    final String password = _passwordController.text;

    try {
      String apiUrl = '${ApiKey.baseUrl}/PassengerLogin';
      final response = await _dio.post(
        apiUrl,
        data: {
          "username": _usernameController.text,
          "password": _passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        // Show confirmation dialog with passenger details
        _showConfirmationDialog(response.data);
      }

      return;
    } catch (e) {
      print(e);
      if (e is DioError && e.response != null) {
        if (email.isNotEmpty || password.isNotEmpty) {
          Fluttertoast.showToast(
            msg: '${e.response!.data["message"]}',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
          );
        }
      }
    }
  }

  void _showConfirmationDialog(Map<String, dynamic> passengerData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Name: ${passengerData["passenger_name"]}"),
              Text("Phone: ${passengerData["passenger_phone"]}"),
              Text("Location: ${passengerData["passenger_location"]}"),
              Text("Company: ${passengerData["companyname"]}"),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
                // Optionally, you can cancel any action here if needed
              },
            ),
            TextButton(
              child: Text("Confirm"),
              onPressed: () {
                // Save to SharedPreferences and navigate to Homepage
                _saveToSharedPreferences(passengerData);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveToSharedPreferences(Map<String, dynamic> passengerData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', passengerData["token"]);
    await prefs.setInt('passenger_id', passengerData["passenger_id"]);
    await prefs.setString("pickup", passengerData["pickup_route_id"]);
    await prefs.setString("drop", passengerData["drop_route_id"]);
    await prefs.setString("name", passengerData["passenger_name"]);
    await prefs.setInt("phone", passengerData["passenger_phone"]);
    await prefs.setString("location", passengerData["passenger_location"]);
    await prefs.setString("company", passengerData["companyname"]);

    // Navigate to Homepage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Homepage(
          Pickup: passengerData["pickup_route_id"],
          Drop: passengerData["drop_route_id"],
          Name: passengerData["passenger_name"],
          Number: passengerData["passenger_phone"],
          Location: passengerData["passenger_location"],
          PassengerId: passengerData["passenger_id"],
          CompanyName: passengerData["companyname"],
          Token: passengerData["token"],
        ),
      ),
    );
  }

  void _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    int? Passid = prefs.getInt('passenger_id');
    String Pickup = prefs.getString('pickup') ?? "";
    String Drop = prefs.getString('drop') ?? "";
    String Name = prefs.getString('name') ?? "";
    int Phone = prefs.getInt('phone') ?? 0;

    String Location = prefs.getString('location') ?? "";
    String Company = prefs.getString('company') ?? "";

    if (token != null && Passid != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Homepage(
            Pickup: Pickup,
            Drop: Drop,
            Name: Name,
            Number: Phone,
            Location: Location,
            PassengerId: Passid,
            CompanyName: Company,
            Token: token,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colours.white,
      body: Stack(
        children: [
          Positioned(child: Container(
            color: Colours.orange,
            height: MediaQuery.of(context).size.height * 0.40,
          )),

          Positioned(
            top: MediaQuery.of(context).size.height * 0.05,
            child:Image.asset(
            'assets/mobile.png',  // Replace with your logo

          ), ),

          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.30,left: 15,right: 15),
              child: Container(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 5,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo at the top of form
                        Image.asset(
                          'assets/logo.png',  // Replace with your logo
                          height: 60,
                        ),
                        SizedBox(height: 20),

                        // Username or Phone Number Input
                        TextFormField(
                          controller: _usernameController,
                          maxLength: 8,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Username';
                            }
                            if (!RegExp(r'^\d{8}$').hasMatch(value)) {
                              return 'Please enter a valid Username';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            counterText: "",
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Password Input
                        TextFormField(
                          controller: _passwordController,
                          maxLength: 8,
                          obscureText: _obscureText,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Password';
                            }
                            if (value.length > 12) {
                              return 'Password cannot be more than 12 characters';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            counterText: '',
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),

                        // Remember Me and Forgot Password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [

                            TextButton(
                              onPressed: () {
                                // Handle forgot password logic
                              },
                              child: Text("Forgot Password?",style: TextStyle(color: Colours.orange),),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        // Login Button
                        SizedBox(
                          width: 200,  // Set the desired width here
                          child: MaterialButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _login();
                              }
                            },
                            color: Colours.orange,
                            height: 50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ))
        ],
      ),
    );
  }
}
