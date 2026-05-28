import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gconductor/services/location_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late Color mycolor;
  late Size mediasize;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController emailcontroller = TextEditingController();
  final TextEditingController passcontroller = TextEditingController();

  //Email/Password Login Function
  Future<void> signInWithEmailPassword() async {
    try {
      // ignore: unused_local_variable
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(
            email: emailcontroller.text,
            password: passcontroller.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Login Successful")));
      }

      // Navigate to HomeScreen after successful login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LocationPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Login Failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    mycolor = Theme.of(context).primaryColor;
    mediasize = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
        color: mycolor,
        image: DecorationImage(
          image: AssetImage("assets/image/bg11.jpg"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            // ignore: deprecated_member_use
            mycolor.withOpacity(0.2),
            BlendMode.dstATop,
          ),
        ),
      ),

      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned(top: 20, child: _buildtop()),
            Positioned(bottom: 0, child: _buildbottom()),
          ],
        ),
      ),
    );
  }

  Widget _buildtop() {
    return SizedBox(
      width: mediasize.width,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 100),

          Image(
            image: AssetImage('assets/image/bus1.png'),
            color: Colors.white,
            width: 200,
            height: 125,
          ),

          Text(
            "GConductor",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 40,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildbottom() {
    return SizedBox(
      width: mediasize.width,
      child: Card(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),

        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: _buildform(),
        ),
      ),
    );
  }

  Widget _buildform() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome",
          style: TextStyle(
            color: mycolor,
            fontSize: 30,
            fontWeight: FontWeight.w500,
          ),
        ),

        _buildgreytext("Please login with your information"),
        const SizedBox(height: 20),
        _buildgreytext("Email"),
        TextField(controller: emailcontroller),
        const SizedBox(height: 20),
        _buildgreytext("Password"),
        TextField(controller: passcontroller, obscureText: true),
        const SizedBox(height: 10),
        _buildloginbutton(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildgreytext(String text) {
    return Text(text, style: const TextStyle(color: Colors.grey));
  }

  Widget _buildloginbutton() {
    return Center(
      child: ElevatedButton(
        onPressed: signInWithEmailPassword,
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
          elevation: 20,
          foregroundColor: Colors.white,
          backgroundColor: mycolor,
          shadowColor: mycolor,
          fixedSize: const Size(200, 50),
        ),
        child: const Text("Login"),
      ),
    );
  }
}
