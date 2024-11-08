import 'package:android_ios_passenger/Constants/Apikey.dart';
import 'package:android_ios_passenger/Constants/Colours.dart';
import 'package:android_ios_passenger/Presentation/Screens/Login.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PassengerProfilePage extends StatefulWidget {
  final String name;
  final int number;
  final String pickup;
  final String drop;
  final String company;
  final String location;
  final String token;

  const PassengerProfilePage({
    Key? key,
    required this.name,
    required this.number,
    required this.pickup,
    required this.drop,
    required this.company,
    required this.location,
    required this.token,
  }) : super(key: key);

  @override
  _PassengerProfilePageState createState() => _PassengerProfilePageState();
}

class _PassengerProfilePageState extends State<PassengerProfilePage> {
  late String profileInitial;

  @override
  void initState() {
    super.initState();
    profileInitial = widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '';
  }

  Future<void> _logout() async {
    final _dio = Dio();
    try {
      var headers = {'Authorization': 'Bearer ${widget.token}'};
      const String apiUrl = '${ApiKey.baseUrl}/PassengerLogOut';
      final response = await _dio.delete(
        apiUrl,
        data: widget.token,
        options: Options(headers: headers),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colours.orange,
                child: Text(
                  profileInitial,
                  style: TextStyle(fontSize: 40, color: Colors.white),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Hello',
                style: TextStyle(fontSize: 20, color: Colors.black54),
              ),
              Text(
                widget.name,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              SizedBox(height: 20),
              _buildProfileDetail('Number', widget.number.toString()),
              _buildProfileDetail('Company', widget.company),
              _buildProfileDetail('Location', widget.location),
              _buildProfileDetail('Pickup', widget.pickup),
              _buildProfileDetail('Drop', widget.drop),
              Divider(height: 40, color: Colors.black54),
              _buildMenuOption(context, Icons.lock, 'Change Password'),
              _buildMenuOption(context, Icons.support, 'Support'),
              ListTile(
                leading: Icon(Icons.logout, color: Colours.orange),
                title: Text('Log Out', style: TextStyle(color: Colours.orange)),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetail(String title, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              detail,
              style: TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(BuildContext context, IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colours.orange),
      title: Text(label),
      onTap: () {
        // Navigation logic here
      },
    );
  }
}
