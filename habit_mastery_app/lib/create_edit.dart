import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateEdit extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        backgroundColor: Colors.greenAccent,
        shadowColor: Colors.black,
        elevation: 3,
        title: Text(
          'Create/Edit',
          style: GoogleFonts.jetBrainsMono(),
        ),
        centerTitle: true,
      ),
      body: Column(
        spacing: 30,
        children: [
          Container(
            margin: EdgeInsets.only(top: 40, left: 25, right: 25),
            decoration: BoxDecoration(
              borderRadius: BorderRadiusGeometry.circular(10),
              border: BoxBorder.all(
                color: Colors.black,
                width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15
                )
              ]
            ),
            child: TextField(
              style: GoogleFonts.jetBrainsMono(),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.greenAccent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none
                ),
                hint: Text(
                  'Habit Title',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.black38
                  )
                )
              ),
            )
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadiusGeometry.circular(10),
              border: BoxBorder.all(
                color: Colors.black,
                width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15
                )
              ]
            ),
            child: DropdownMenu(
              width: 360,
              hintText: 'Select Category',
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.greenAccent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none
                ),
                hintStyle: GoogleFonts.jetBrainsMono(
                  color: Colors.black38
                ),
              ),
              dropdownMenuEntries: [
                DropdownMenuEntry(
                  value: 's',
                  label: 'Study'
                ),
                DropdownMenuEntry(
                  value: 'r',
                  label: 'Routine'
                ),
                DropdownMenuEntry(
                  value: null,
                  label: 'None')
              ]
            ),
          )
          /* Container(
            margin: EdgeInsets.only(left: 25, right: 25),
            decoration: BoxDecoration(
              borderRadius: BorderRadiusGeometry.circular(10),
              border: BoxBorder.all(
                color: Colors.black,
                width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15
                )
              ]
            ),
            child: TextField(
              readOnly: true,
              style: GoogleFonts.jetBrainsMono(),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.greenAccent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none
                ),
                suffixIcon: Icon(
                  Icons.arrow_drop_down,
                  size: 45
                ),
                hint: Text(
                  'Category',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.black38
                  )
                )
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: Text(
                      'Select Category'
                    ),
                  )
                );
              },
            )
          )*/
        ]
      )
    );
  }
}