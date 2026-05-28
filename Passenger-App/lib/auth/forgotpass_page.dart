import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ignore: camel_case_types
class forgotpage extends StatefulWidget {
  const forgotpage({super.key});

  @override
  State<forgotpage> createState() => _forgotpageState();
}

// ignore: camel_case_types
class _forgotpageState extends State<forgotpage> {
  late Color mycolor;
  late Size mediasize;
  final TextEditingController emailcontroller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? message; // Message to show user after email is sent

  Future<void> resetPassword() async {
    if (emailcontroller.text.isEmpty) {
      setState(() {
        message = "Please enter your email";
      });
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: emailcontroller.text);
      setState(() {
        message = "Check your email for the reset link.";
      });
    } catch (e) {
      setState(() {
        message = "Error: ${e.toString()}";
      });
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
          
          SizedBox( height: 140,),

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
          "Forgot Password",
          style: TextStyle(
            color: mycolor,
            fontSize: 30,
            fontWeight: FontWeight.w500,
          ),
        ),

        _buildgreytext("Enter your email to reset your password"),
        const SizedBox(height: 30),
        _buildgreytext("Email address"),
        _buildinputfield(emailcontroller),
        const SizedBox(height: 20),
        _buildcontbutton(),
        if (message != null) ...[
              SizedBox(height: 10),
              Text(
                message!,
                style: TextStyle(color: Colors.green, fontSize: 16),
              ),
            ],
        //const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Back to login screen
              },
              child: Text("Back to Login"),
            ),
      ],
    );
  }

  Widget _buildgreytext(String text) {
    return Text(text, style: const TextStyle(color: Colors.grey));
  }

  Widget _buildinputfield(TextEditingController controller) {
    return TextField(
      controller: emailcontroller,
       keyboardType: TextInputType.emailAddress,
    );
  }

 
  
  Widget _buildcontbutton() {
    return Center(
      child: ElevatedButton(
        onPressed: resetPassword,
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
          elevation: 20,
          foregroundColor: Colors.white,
          backgroundColor: mycolor,
          shadowColor: mycolor,
          fixedSize: const Size(200, 50),
        ),
        child: const Text("Continue"),
      ),
    );
  }

 
}
