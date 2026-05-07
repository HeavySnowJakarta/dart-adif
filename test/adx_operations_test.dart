import 'package:adif/adif.dart';
import 'package:test/test.dart';

const _sampleAdx = '''
<?xml version="1.0" encoding="UTF-8"?>
<ADX>
  <HEADER>
    <ADIF_VER>3.0.5</ADIF_VER>
    <PROGRAMID>monolog</PROGRAMID>
    <USERDEF FIELDID="1" TYPE="N">EPC</USERDEF>
  </HEADER>
  <RECORDS>
    <RECORD>
      <QSO_DATE>19900620</QSO_DATE>
      <TIME_ON>1523</TIME_ON>
      <CALL>VK9NS</CALL>
      <mode>RTTY</mode>
      <USERDEF FIELDNAME="EPC">32123</USERDEF>
      <APP PROGRAMID="MONOLOG" FIELDNAME="COMPRESSION" TYPE="S">off</APP>
    </RECORD>
  </RECORDS>
</ADX>
''';

void main() {
  group('ADX regression', () {
    test('buildAdxString still renders core ADX structure', () {
      final qso = Qso(
        <AdifField>[
          adifFieldFactory('CALL', 'BA1ABC'),
          adifFieldFactory('QSO_DATE', '20250506'),
          adifFieldFactory('TIME_ON', '123456'),
        ],
        <Appdef>[Appdef.generate('monolog', 'COMPRESSION', 'S', 'off')],
        <Userdef>[Userdef.generate('EPC', 'N', '32123', range: (1, 99999))],
      );

      final adx = Adif('monolog', '1.0.0', [qso]).buildAdxString();

      expect(adx, contains('<ADX>'));
      expect(adx, contains('<PROGRAMID>monolog</PROGRAMID>'));
      expect(adx, contains('<CALL>BA1ABC</CALL>'));
      expect(adx, contains('FIELDNAME="COMPRESSION"'));
      expect(adx, contains('FIELDNAME="EPC"'));
    });

    test('parseAdxString still restores records and custom fields', () {
      final parsed = AdifOperations.parseAdxString(
        _sampleAdx,
        ignoreIllegals: false,
      );

      expect(parsed.adifVer, '3.0.5');
      expect(parsed.programid, 'monolog');
      expect(parsed.data, hasLength(1));
      expect(
        parsed.data.single.adifdefs
            .singleWhere((f) => f.fieldName == 'CALL')
            .getString(),
        'VK9NS',
      );
      expect(parsed.data.single.appdefs.single.programid, 'MONOLOG');
      expect(parsed.data.single.appdefs.single.fieldName, 'COMPRESSION');
      expect(parsed.data.single.userdefs.single.fieldName, 'EPC');
    });
  });
}
