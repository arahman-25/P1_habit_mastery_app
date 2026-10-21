import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habit_mastery_app/settings.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        backgroundColor: Colors.greenAccent,
        title: Text(
          'Dashboard',
          style: GoogleFonts.jetBrainsMono(),
        ),
        centerTitle: true,
        actions: [
          SettingButton()
        ], 
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 400,
            width: 400,
            margin: EdgeInsets.only(top: 30, left: 25, right: 25),
            decoration: BoxDecoration(
              color: Colors.white,
              border: BoxBorder.all(color: Colors.black, width: 2)
            )
          )
        ],
      )
    );
  }
}

class SettingButton extends StatefulWidget {
  const SettingButton({super.key});

  @override
  State<SettingButton> createState() => SettingButtonState();
}

class SettingButtonState extends State<SettingButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Settings()));
      },
      onTapDown: (details) {
        setState(() {
          _isHovered = true;
        });
      },
      onTapUp: (details) {
        setState(() {
          _isHovered = false;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.all(5),
        padding: EdgeInsets.all(5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isHovered ? Colors.green : Colors.greenAccent,
          borderRadius: BorderRadius.circular(2)
        ),
        child: SvgPicture.asset(
          'assets/icons/gear-svgrepo-com.svg',
          height: 30,
          width: 30,
          alignment: Alignment.center
        ),
      ),
    );
  }
}

