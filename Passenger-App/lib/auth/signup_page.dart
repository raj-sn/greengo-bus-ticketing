import 'package:flutter/material.dart';
import 'package:gticketing/auth/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: camel_case_types
class signuppage extends StatefulWidget {
  const signuppage({super.key});

  @override
  State<signuppage> createState() => _signuppageState();
}

// ignore: camel_case_types
class _signuppageState extends State<signuppage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Color mycolor;
  late Size mediasize;

  final TextEditingController emailcontroller = TextEditingController();
  final TextEditingController passcontroller = TextEditingController();
  final TextEditingController namecontroller = TextEditingController();
  final TextEditingController mobcontroller = TextEditingController();

  Future<void> registerUser() async {
    try {
      // Create user with email & password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailcontroller.text,
        password: passcontroller.text,
      );

      // Store additional user data in Firestore
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "name": namecontroller.text,
        "mobile": mobcontroller.text,
        "email": emailcontroller.text,
        "uid": userCredential.user!.uid,
        "balance": 0.0,
        "leaf":0,
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration Successful!")),
      );

      // Navigate to login or home screen after registration
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    mycolor = const Color.fromARGB(255, 30, 43, 30);
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
          SizedBox(height: 5),

          Image(
            image: AssetImage('assets/image/bus1.png'),
            color: Colors.white,
            width: 200,
            height: 125,
          ),

          Text(
            "GTicketing",
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
          "Register",
          style: TextStyle(
            color: mycolor,
            fontSize: 30,
            fontWeight: FontWeight.w500,
          ),
        ),

        _buildgreytext("Please register with your information"),
        const SizedBox(height: 7),
        _buildgreytext("Full Name"),
        TextField(
              controller: namecontroller,
        ),
        const SizedBox(height: 10),
        _buildgreytext("Mobile Number"),
        TextField(
              controller: mobcontroller,
              keyboardType: TextInputType.phone,
        ),
         const SizedBox(height: 10),
        _buildgreytext("Email"),
        TextField(
              controller: emailcontroller,
              keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        _buildgreytext("Password"),
        TextField(
              controller: passcontroller,
              obscureText: true,
        ),
        const SizedBox(height: 10),
        _buildhaveaccount(),
        const SizedBox(height: 10),
        _buildsignbutton(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildgreytext(String text) {
    return Text(text, style: const TextStyle(color: Colors.grey));
  }

  Widget _buildhaveaccount() {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      },
      child: Text(
        "Alraedy have an account",
        style: const TextStyle(color: Colors.blue),
      ),
    );
  }

  Widget _buildsignbutton() {
    return Center(
      child: ElevatedButton(
        onPressed: registerUser,
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
          elevation: 20,
          foregroundColor: Colors.white,
          backgroundColor: mycolor,
          shadowColor: mycolor,
          fixedSize: const Size(200, 50),
        ),
        child: const Text("Sign up"),
      ),
    );
  }

}
