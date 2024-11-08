import 'package:android_ios_passenger/Constants/Apikey.dart';
import 'package:android_ios_passenger/Constants/Colours.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Homepage.dart'; // Ensure this import matches the correct path in your project

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Dio _dio = Dio();
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _login() async {
    final String email = _phoneController.text;
    final String password = _passwordController.text;

    try {
      String apiUrl = '${ApiKey.baseUrl}/PassengerLogin';
      final response = await _dio.post(
        apiUrl,
        data: {
          "username": _phoneController.text,
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
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Colors.orange.shade200,
              Colours.orange,
              Colours.orange
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 80),
            Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Image.asset(
                  'assets/logo.png', // Ensure this matches the path to your logo
                  width: 100,
                  height: 100,
                ),
              ),
            ),
            SizedBox(height: 60),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          SizedBox(height: 60),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromRGBO(225, 95, 27, .3),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                )
                              ],
                            ),
                            child: Column(
                              children: <Widget>[
                                Stack(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                      ),
                                      child: TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(8),
                                        ],
                                        decoration: InputDecoration(
                                          hintText: "Username",
                                          hintStyle: TextStyle(color: Colors.grey),
                                          border: InputBorder.none,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your Username';
                                          }
                                          if (!RegExp(r'^\d{8}$').hasMatch(value)) {
                                            return 'Please enter a valid Username';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Stack(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                      ),
                                      child: TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscureText,
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(15),
                                        ],
                                        decoration: InputDecoration(
                                          hintText: "Password",
                                          hintStyle: TextStyle(color: Colors.grey),
                                          border: InputBorder.none,
                                          suffixIcon: IconButton(
                                            icon: Icon(_obscureText
                                                ? Icons.visibility
                                                : Icons.visibility_off),
                                            onPressed: () {
                                              setState(() {
                                                _obscureText = !_obscureText;
                                              });
                                            },
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your Password';
                                          }
                                          if (value.length > 12) {
                                            return 'Password cannot be more than 12 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 40),
                          TextButton(
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(color: Colors.grey),
                            ),
                            onPressed: () {
                              // Handle forgot password logic here
                            },
                          ),
                          SizedBox(height: 40),
                          MaterialButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _login();
                              }
                            },
                            height: 50,
                            color: Colours.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Center(
                              child: Text(
                                "Login",
                                style: TextStyle(
                                  color:Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
    );
  }
}
