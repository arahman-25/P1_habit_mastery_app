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
  TextEditingController _titleController = TextEditingController();
  TextEditingController _categoryController = TextEditingController();
  TextEditingController _motivationController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _motivationController.dispose();
    super.dispose();
  }

  List<String> categoryList = [];
  List<DropdownMenuEntry<String>> get dropdownEntries {
    return categoryList.map((category) => DropdownMenuEntry(
      value: category,
      label: category,
      style: MenuItemButton.styleFrom(
        textStyle: GoogleFonts.jetBrainsMono()
      )
      )).toList();
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


        // Category Filter Text Field & Button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 15,
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
              child: DropdownMenu<String>(
                width: 290,
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
                dropdownMenuEntries: categoryList.map<DropdownMenuEntry<String>>((String value) {
                  return DropdownMenuEntry<String>(
                    value: value,
                    label: value
                  );
                }).toList(),
              ),
            ),
            FloatingActionButton(
              onPressed: () {
                showDialog<String>(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                      title: Text(
                        'Add Category',
                        style: GoogleFonts.jetBrainsMono()
                      ),
                      actions: [
                        TextField(
                          controller: _categoryController,
                          style: GoogleFonts.jetBrainsMono(),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.greenAccent,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none
                            ),
                            hint: Text(
                              'Add Category',
                              style: GoogleFonts.jetBrainsMono(
                                color: Colors.black38
                              )
                            )
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => categoryList.add(_categoryController.text.trim()));
                            Navigator.of(dialogContext).pop();
                            _categoryController.clear();
                          },
                          child: Text(
                            'Create',
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.black
                            )
                          ))
                      ],
                    );
                  }
                );
              },
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
        ),


        // Weekly Target Slider
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
        // Edit/Create Button
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return SimpleDialog(
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
                      _titleController.text,
                      style: GoogleFonts.jetBrainsMono()
                    )
                  ]
                );
              }
            );
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
