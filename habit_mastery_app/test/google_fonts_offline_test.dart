import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GoogleFonts loads offline without runtime fetching', () async {
    GoogleFonts.config.allowRuntimeFetching = false;
    expect(GoogleFonts.config.allowRuntimeFetching, isFalse);

    // Verify jetBrainsMono TextStyle can be constructed with various weights and styles
    final regularStyle = GoogleFonts.jetBrainsMono();
    expect(regularStyle.fontFamily, contains('JetBrainsMono'));

    final boldStyle = GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold);
    expect(boldStyle.fontWeight, equals(FontWeight.bold));

    final italicStyle = GoogleFonts.jetBrainsMono(fontStyle: FontStyle.italic);
    expect(italicStyle.fontStyle, equals(FontStyle.italic));

    // Verify assets can be found in the asset bundle
    final boldAsset = await rootBundle.load('assets/google_fonts/JetBrainsMono-Bold.ttf');
    expect(boldAsset.lengthInBytes, greaterThan(0));

    final italicAsset = await rootBundle.load('assets/google_fonts/JetBrainsMono-Italic.ttf');
    expect(italicAsset.lengthInBytes, greaterThan(0));
  });
}
