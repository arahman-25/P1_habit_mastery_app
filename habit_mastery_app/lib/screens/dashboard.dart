import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'details.dart';
import 'settings.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        backgroundColor: Colors.greenAccent,
        shadowColor: Colors.black,
        elevation: 3,
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
              border: BoxBorder.all(color: Colors.white24, width: 10),
              borderRadius: BorderRadiusGeometry.circular(3)
            )
          ),
          SizedBox(height: 25),
          Text(
            'Weekly Completion Rate:',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 25
            ),
          ),
          SizedBox(height: 25),
          Stack(
            alignment: AlignmentDirectional.center,
            children: [
              CircularProgressIndicator(
                value: 0.8,
                constraints: BoxConstraints(
                  minWidth: 100, 
                  minHeight: 100
                ),
                strokeWidth: 15,
                color: Colors.greenAccent,
                backgroundColor: Colors.black12,
              ),
              Text(
                '5/7',
                style: GoogleFonts.jetBrainsMono(
                fontSize: 30
                )
              )
            ]
          ),
          SizedBox(height: 25),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => Details()));
            },
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.greenAccent),
              minimumSize: WidgetStatePropertyAll(Size(250, 60)),
              side: WidgetStatePropertyAll(BorderSide()),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(3)))
            ),
            child: Text(
              'View Cycle Details',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.black,
                fontSize: 20
              ),
            )
          ),
        ],
      ),
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
          color: _isHovered ? Colors.greenAccent : Colors.transparent,
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
