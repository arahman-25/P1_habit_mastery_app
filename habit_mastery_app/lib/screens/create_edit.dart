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
  String? habitTitle;
  List<String?> category = [];
  String? weeklyTarget;
  String? motivationNote;

  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 40,
      children: [
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
            controller: _controller,
            onSubmitted: (value) {
              habitTitle = value;
            },
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
        CategoryFilter(),
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
            maxLines: 4,
            style: GoogleFonts.jetBrainsMono(),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.greenAccent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none
              ),
              hint: Text(
                'Weekly Target',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.black38
                )
              )
            ),
          )
        ),
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
            maxLines: 6,
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
        ElevatedButton(
          onPressed: () {},
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

class CategoryFilter extends StatefulWidget {
  const new({super.key});

  @override
  State<CategoryFilter> createState() => _CategoryFilterState();
}

class _CategoryFilterState extends State<CategoryFilter> {
  
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 22,
      children: [
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15
              )
            ]
          ),
          child: DropdownMenu(
            width: 280,
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
                value: 's',
                label: 'Study'
              ),
              DropdownMenuEntry(
                value: 'r',
                label: 'Routine'
              ),
            ]
          ),
        ),
        FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.greenAccent,
          tooltip: 'Add Category',
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(10),
            side: BorderSide(
              color: Colors.black54
            )
          ),
          child: Icon(
            Icons.add,
            size: 30,
            color: Colors.black45)
        )
      ],
    );
  }
}