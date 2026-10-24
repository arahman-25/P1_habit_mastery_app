import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Details extends StatelessWidget {
  const Details({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.greenAccent,
        title: Text(
          'Details',
          style: GoogleFonts.jetBrainsMono(),
        ),
        centerTitle: true,
      )
    );  }
}