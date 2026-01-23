import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;

    final String tanggalFormatted = DateFormat(
      'EEEE, d MMMM',
      'id_ID',
    ).format(DateTime.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hallo",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              tanggalFormatted,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),

        /// PROFILE PICTURE
        GestureDetector(
          onTap: () {
            // nanti bisa buka profile / bottom sheet
            debugPrint("Profile clicked");
          },
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[200],
            backgroundImage: photoUrl != null
                ? NetworkImage(photoUrl)
                : const AssetImage("assets/images/profile.png")
                      as ImageProvider,
          ),
        ),
      ],
    );
  }
}
