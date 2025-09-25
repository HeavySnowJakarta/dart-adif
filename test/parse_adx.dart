import 'package:adif/adif.dart';
import 'package:test/scaffolding.dart';

const String sample1 = """
<?xml version="1.0" encoding="UTF-8"?>
<ADX>
  <HEADER>
    <!--Generated on 2011-11-22 at 02:15:23Z for WN4AZY-->
    <ADIF_VER>3.0.5</ADIF_VER>
    <PROGRAMID>monolog</PROGRAMID>
    <USERDEF FIELDID="1" TYPE="N">EPC</USERDEF>
    <USERDEF FIELDID="2" TYPE="E" ENUM="{S,M,L}">SWEATERSIZE</USERDEF>
    <USERDEF FIELDID="3" TYPE="N" RANGE="{5:20}">SHOESIZE</USERDEF>
  </HEADER>
  <RECORDS>
    <RECORD>
      <QSO_DATE>19900620</QSO_DATE>
      <TIME_ON>1523</TIME_ON>
      <CALL>VK9NS</CALL>
      <BAND>20M</BAND>
      <MODE>RTTY</MODE>
      <USERDEF FIELDNAME="SWEATERSIZE">M</USERDEF>
      <USERDEF FIELDNAME="SHOESIZE">11</USERDEF>
      <APP PROGRAMID="MONOLOG" FIELDNAME="Compression" TYPE="s">off</APP>
    </RECORD>
    <RECORD>
      <QSO_DATE>20101022</QSO_DATE>
      <TIME_ON>0111</TIME_ON>
      <CALL>ON4UN</CALL>
      <BAND>40M</BAND>
      <MODE>PSK</MODE>
      <SUBMODE>PSK63</SUBMODE>
      <USERDEF FIELDNAME="EPC">32123</USERDEF>
      <APP PROGRAMID="MONOLOG" FIELDNAME="COMPRESSION" TYPE="s">off</APP>
    </RECORD>
  </RECORDS>
</ADX>
""";

void main() {
  group('Parse from ADX files and build it again', () {
    final adif1 = AdifOperations.parseAdxString(sample1, ignoreIllegals: false);
    final s = adif1.buildAdxString();
    test(
      'Parsed object string representation likely contains at least one callsign',
      () {
        if (!(s.contains('VK9NS') || s.contains('ON4UN'))) {
          throw StateError(
            'Parsed object string representation missing expected callsigns.',
          );
        }
      },
    );

    test('ADX header includes ADIF version and program id', () {
      final hasVersion = s.contains('<ADIF_VER>3.0.5');
      final hasProgramId =
          s.contains('<PROGRAMID>monolog') || s.contains('<PROGRAMID>MONOLOG');
      if (!(hasVersion && hasProgramId)) {
        throw StateError(
          'Header missing ADIF version or PROGRAMID. String: $s',
        );
      }
    });

    test('User defined field definitions are present', () {
      if (!(s.contains('EPC') &&
          s.contains('SWEATERSIZE') &&
          s.contains('SHOESIZE'))) {
        throw StateError('Missing one or more USERDEF field definitions.');
      }
    });

    test('All expected QSO_DATE values are present', () {
      if (!(s.contains('<QSO_DATE>19900620') &&
          s.contains('<QSO_DATE>20101022'))) {
        throw StateError('Not all expected QSO_DATE values found.');
      }
    });

    test('Bands and modes (including submode) are represented', () {
      final ok =
          s.contains('<BAND>20M') &&
          s.contains('<BAND>40M') &&
          s.contains('<MODE>RTTY') &&
          (s.contains('<MODE>PSK') ||
              s.contains('<MODE>PSK ') ||
              s.contains('<MODE>PSK</')) &&
          s.contains('<SUBMODE>PSK63');
      if (!ok) {
        throw StateError('Bands/Modes/Submode not all present. String: $s');
      }
    });

    test('Custom USERDEF field values inside records are preserved', () {
      final hasSweater =
          s.contains('SWEATERSIZE') &&
          (s.contains('>M<') || s.contains('>M</'));
      final hasShoe =
          s.contains('SHOESIZE') && (s.contains('>11') || s.contains('>11'));
      final hasEpc = s.contains('EPC') && (s.contains('32123'));
      if (!(hasSweater && hasShoe && hasEpc)) {
        throw StateError('One or more USERDEF field values missing.');
      }
    });

    test(
      'APP (application-specific) fields are present (case-insensitive)',
      () {
        final sUpper = adif1.buildAdxString().toUpperCase();
        // Looking for PROGRAMID="MONOLOG" and FIELDNAME="COMPRESSION"
        final hasAppProgram = sUpper.contains('PROGRAMID="MONOLOG"');
        final hasAppField = sUpper.contains('FIELDNAME="COMPRESSION"');
        if (!(hasAppProgram && hasAppField)) {
          throw StateError('APP fields missing expected attributes.');
        }
      },
    );

    test('Contains both callsigns across records', () {
      if (!(s.contains('<CALL>VK9NS') && s.contains('<CALL>ON4UN'))) {
        throw StateError('Not all expected callsigns found.');
      }
    });

    test('Expected number of RECORD elements (2)', () {
      final count = RegExp('<RECORD>').allMatches(s).length;
      if (count != 2) {
        throw StateError('Expected 2 <RECORD> elements, found $count.');
      }
    });

    test('Rebuilt ADX string remains well-formed for key structural tags', () {
      final needed = [
        '<ADX',
        '<HEADER>',
        '</HEADER>',
        '<RECORDS>',
        '</RECORDS>',
        '</ADX>',
      ];
      for (final tag in needed) {
        if (!s.contains(tag)) {
          throw StateError('Missing structural tag: $tag');
        }
      }
    });

    test('No obviously empty critical tags (CALL, BAND, MODE)', () {
      final emptyPattern = RegExp(r'<(CALL|BAND|MODE)>\s*</\1>');
      if (emptyPattern.hasMatch(s)) {
        throw StateError('Found an unexpectedly empty critical tag.');
      }
    });
  });
}
