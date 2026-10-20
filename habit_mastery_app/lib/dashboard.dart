import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

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
          HoverButton()
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
              border: BoxBorder.all(color: Colors.black, width: 2)
            )
          )
        ],
      )
    );
  }
}

class HoverButton extends StatefulWidget {
  const new({super.key});

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
              onEnter:(event) {
                setState(() {
                  _isHovered = true;
                });
              },
              onExit:(event) {
                setState(() {
                  _isHovered = false;
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                margin: EdgeInsets.all(10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isHovered ? Colors.blue : Colors.red
                ),
                child: SvgPicture.asset('assets/icons/gear-svgrepo-com.svg',
                  height: 30,
                  width: 30,
                  alignment: Alignment.center
                ),
              ),
            );
  }
}

