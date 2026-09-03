import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {

  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        backgroundColor:
            const Color(0xFF0F3D75),

        title: const Text(

          "Profile",

          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      body: const Center(

        child: Column(

          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            CircleAvatar(

              radius: 50,

              child: Icon(
                Icons.person,
                size: 50,
              ),
            ),

            SizedBox(height: 20),

            Text(

              "Admin User",

              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "admin@bankxyz.com",
            ),
          ],
        ),
      ),
    );
  }
}