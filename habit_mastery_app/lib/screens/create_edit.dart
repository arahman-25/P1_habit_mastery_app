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
      body: CreateEditForms()
    );
  }
}


class CreateEditForms extends StatefulWidget {
  const new({super.key});

  @override
  State<CreateEditForms> createState() => _CreateEditFormsState();
}

class _CreateEditFormsState extends State<CreateEditForms> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _motivationController = TextEditingController();

  String titleProof = '';
  double sliderInitialValue = 1;
  final int _weeklyTarget = 7;

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _motivationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 40,
      children: [


        // Habit Title Text Field
        Container(
          margin: EdgeInsets.only(top: 45, left: 25, right: 25),
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
            autofocus: true,
            controller: _titleController,
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


        // Category Filter Text Field
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15
              )
            ]
          ),
          child: DropdownMenu<String>(
            controller: _categoryController,
            width: 360,
            hintText: 'Select Category',
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.greenAccent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide()
              ),
              hintStyle: GoogleFonts.jetBrainsMono(
                color: Colors.black38
              ),
            ),
            menuStyle: MenuStyle(
              backgroundColor: WidgetStateProperty.all(
                Colors.greenAccent
              ),
              side: WidgetStatePropertyAll(
                BorderSide(
                    color: Colors.black54,
                  )
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(10),
                ),
              ),
            ),
            dropdownMenuEntries: [
              DropdownMenuEntry(
                value: 'all',
                label: 'All'
              ),
              DropdownMenuEntry(
                value: 'study',
                label: 'Study'
              ),
              DropdownMenuEntry(
                value: 'health',
                label: 'Health'
              ),
              DropdownMenuEntry(
                value: 'creative',
                label: 'Creative'
              ),
              DropdownMenuEntry(
                value: 'mindfulness',
                label: 'Mindfulness'
              )
            ]
          ),
        ),


        // Weekly Target Slider
        Container(
          margin: EdgeInsets.only(left: 25, right: 25),
          decoration: BoxDecoration(
            color: Colors.greenAccent,
            borderRadius: BorderRadiusGeometry.circular(5),
            border: BoxBorder.all(
              color: Colors.black,
              width: 1
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15
              )
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsetsGeometry.fromLTRB(15, 10, 0, 0),
                child: Text(
                  'Weekly Target Slider: ${sliderInitialValue.toInt()}/$_weeklyTarget',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.black54,
                    fontSize: 20
                  ),
                )
              ),
              Slider(
                activeColor: Colors.green,
                inactiveColor: Colors.green.shade900,
                value: sliderInitialValue,
                max: _weeklyTarget.toDouble(),
                min: 1,
                divisions: _weeklyTarget - 1,
                onChanged: (value) {
                  setState(() {
                    sliderInitialValue = value;
                  });
                },
              ),
            ],
          )
        ),
          
        // Motivation Note
        Container(
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
            maxLines: 8,
            style: GoogleFonts.jetBrainsMono(),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.greenAccent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none
              ),
              hint: Text(
                'Motivation Note',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.black38
                )
              )
            ),
          )
        ),
        // Edit/Create Button
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return SimpleDialog(
                  contentPadding: EdgeInsetsGeometry.fromLTRB(25, 12, 10, 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                  title: Text(
                    'Created Habit Successfully',
                    style: GoogleFonts.jetBrainsMono()
                  ),
                  children: [
                    Text(
                      titleProof,
                      style: GoogleFonts.jetBrainsMono()
                    ),
                    Text(
                      _categoryController.text,
                      style: GoogleFonts.jetBrainsMono()
                    )
                  ]
                );
              }
            );
            if (_titleController.text.isNotEmpty) {
              setState(() {
                titleProof = _titleController.text;
                _titleController.clear();
              });
            }
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
            'Create/Edit',
            style: GoogleFonts.jetBrainsMono(
              color: Colors.black,
              fontSize: 20
            ),
          )
        ),
      ]
    );
  }
}
