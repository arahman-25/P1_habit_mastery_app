import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateEdit extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.greenAccent,
        title: Text(
          'Create/Edit',
          style: GoogleFonts.jetBrainsMono(),
        ),
        centerTitle: true,
      )
    );
  }
}