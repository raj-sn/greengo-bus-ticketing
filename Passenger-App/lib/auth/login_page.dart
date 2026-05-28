import 'package:flutter/material.dart';
import 'package:gticketing/auth/forgotpass_page.dart';
import 'package:gticketing/pages/home_page.dart';
import 'package:gticketing/auth/signup_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late Color mycolor;
  late Size mediasize;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final TextEditingController emailcontroller = TextEditingController();
  final TextEditingController passcontroller = TextEditingController();
  String message = '';

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

      // 🔥 Navigate to HomeScreen after successful login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => homepage()),
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

  // ✅ Google Sign-In + Store in Firestore
  Future<void> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return; // User canceled login

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential =
        await _auth.signInWithCredential(credential);
    final User? user = userCredential.user;

    if (user != null) {
      final DocumentReference userDoc =
          _firestore.collection('users').doc(user.uid);

      final DocumentSnapshot docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // If user doesn't exist, create with balance = 0
        await userDoc.set({
          'name': user.displayName,
          'email': user.email,
          'mobile': user.phoneNumber ?? '',
          'uid': user.uid,
          'balance': 0,
          'leafs':0, 
        });
      } else {
        // If user exists, update only name, email, etc. — don't overwrite balance
        await userDoc.set({
          'name': user.displayName,
          'email': user.email,
          'mobile': user.phoneNumber ?? '',
          'uid': user.uid,
        }, SetOptions(merge: true));
      }
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => homepage()),
      );
    }
  } catch (e) {
    setState(() => message = "Google Sign-In Failed: $e");
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
          SizedBox(height: 30),

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

        _buildforgotcreate(),
        const SizedBox(height: 10),
        _buildloginbutton(),
        const SizedBox(height: 20),
        _buildotherlogin(),
      ],
    );
  }

  Widget _buildgreytext(String text) {
    return Text(text, style: const TextStyle(color: Colors.grey));
  }

  Widget _buildforgotcreate() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => forgotpage()),
                );
              },
              child: _buildgreytext("I forgot my password"),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => signuppage()),
            );
          },
          child: Text(
            "Create an account",
            style: const TextStyle(color: Colors.blue),
          ),
        ),
      ],
    );
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

  Widget _buildotherlogin() {
    return Center(
      child: Column(
        children: [
          _buildgreytext("Or"),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: signInWithGoogle,
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
              elevation: 10,
              shadowColor: mycolor,
              fixedSize: const Size(200, 10),
            ),
            child: Image(image: AssetImage('assets/image/gg2.png')),
          ),
        ],
      ),
    );
  }
}
