import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Habit {
  final int id;
  final String title;
  final String category;

  const Habit({
    required this.id,
    required this.title,
    required this.category
  });
}