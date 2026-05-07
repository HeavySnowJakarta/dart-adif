import 'package:adif/adif.dart';
import 'package:test/test.dart';

Adif _buildSampleAdiLog() {
  final qso = Qso(
    <AdifField>[
      adifFieldFactory('CALL', 'BA1ABC'),
      adifFieldFactory('QSO_DATE', '20250506'),
      adifFieldFactory('TIME_ON', '123456'),
      adifFieldFactory('COMMENT', 'ASCII ONLY'),
    ],
    <Appdef>[
      Appdef.generate('LOGGER', 'REMOTE_PROFILE', 'S', 'Profile-A'),
      Appdef.generate('LOGGER', 'FIELD_WITH_UNDERSCORE', 'S', 'Alpha'),
      Appdef.generate('LOGGER', 'IS_ROOKIE', 'B', 'Y'),
    ],
    <Userdef>[
      Userdef.generate('OP_NUMBER', 'N', '3', range: (1, 10)),
      Userdef.generate(
        'FAVORITE_COLOR',
        'E',
        'BLUE',
        enums: ['RED', 'GREEN', 'BLUE'],
      ),
      Userdef.generate('SESSION_TAG', 'S', 'MORNING_RUN'),
    ],
  );

  final adif = Adif('dart-adif', '1.0.0', [qso]);
  adif.adifVer = '3.1.5';
  adif.createdTimestamp = DateTime.utc(2025, 5, 6, 12, 34, 56);
  return adif;
}

void main() {
  group('ADI build and parse', () {
    test(
      'builds ADI with header, records, APP literal names, and USERDEF metadata',
      () {
        final adi = _buildSampleAdiLog().buildAdiString();

        expect(adi, contains('<ADIF_VER:5>3.1.5'));
        expect(adi, contains('<PROGRAMID:9>dart-adif'));
        expect(adi, contains('<PROGRAMVERSION:5>1.0.0'));
        expect(adi, contains('<CREATED_TIMESTAMP:15>20250506 123456'));
        expect(adi, contains('<EOH>'));
        expect(adi, contains('<EOR>'));

        expect(adi, contains('<APP_LOGGER_REMOTE_PROFILE:9:S>Profile-A'));
        expect(adi, contains('<APP_LOGGER_FIELD_WITH_UNDERSCORE:5:S>Alpha'));
        expect(adi, contains('<APP_LOGGER_IS_ROOKIE:1:B>Y'));

        expect(adi, contains('<USERDEF1:'));
        expect(adi, contains('>OP_NUMBER,{1.0:10.0}'));
        expect(adi, contains('<USERDEF2:'));
        expect(adi, contains('>FAVORITE_COLOR,{RED,GREEN,BLUE}'));
        expect(adi, contains('<USERDEF3:11:S>SESSION_TAG'));
      },
    );

    test('parses built ADI back into the data model', () {
      final adi = _buildSampleAdiLog().buildAdiString();
      final parsed = AdifOperations.parseAdiString(adi, ignoreIllegals: false);

      expect(parsed.adifVer, '3.1.5');
      expect(parsed.programid, 'dart-adif');
      expect(parsed.programversion, '1.0.0');
      expect(parsed.createdTimestamp, DateTime.utc(2025, 5, 6, 12, 34, 56));
      expect(parsed.data, hasLength(1));

      final qso = parsed.data.single;
      expect(
        qso.adifdefs.map((field) => field.fieldName),
        containsAll(<String>['CALL', 'QSO_DATE', 'TIME_ON', 'COMMENT']),
      );

      final remoteProfile = qso.appdefs.firstWhere(
        (field) => field.fieldName == 'REMOTE_PROFILE',
      );
      expect(remoteProfile.programid, 'LOGGER');
      expect(remoteProfile.value.getString(), 'Profile-A');

      final fieldWithUnderscore = qso.appdefs.firstWhere(
        (field) => field.fieldName == 'FIELD_WITH_UNDERSCORE',
      );
      expect(fieldWithUnderscore.programid, 'LOGGER');
      expect(fieldWithUnderscore.value.getString(), 'Alpha');

      final opNumber = qso.userdefs.firstWhere(
        (field) => field.fieldName == 'OP_NUMBER',
      );
      expect(opNumber.value.getType(), 'N');
      expect((opNumber.value as AdifRange).range, (1.0, 10.0));

      final favoriteColor = qso.userdefs.firstWhere(
        (field) => field.fieldName == 'FAVORITE_COLOR',
      );
      expect((favoriteColor.value as AdifEnumeration).enumerations, <String>[
        'RED',
        'GREEN',
        'BLUE',
      ]);
    });

    test('rejects APP fields that need auxiliary metadata during build', () {
      final qso = Qso(
        <AdifField>[adifFieldFactory('CALL', 'BA1ABC')],
        <Appdef>[
          Appdef.generate(
            'LOGGER',
            'MODE_KIND',
            'E',
            'VOICE',
            enums: ['VOICE', 'DIGITAL'],
          ),
        ],
        const <Userdef>[],
      );

      expect(
        () => Adif('dart-adif', '1.0.0', [qso]).buildAdiString(),
        throwsArgumentError,
      );
    });
  });

  group('ADI non-ASCII behavior', () {
    test('throws in strict build mode for intl ADIF-defined fields', () {
      final qso = Qso(
        <AdifField>[adifFieldFactory('COMMENT_INTL', 'ASCII你好')],
        const <Appdef>[],
        const <Userdef>[],
      );

      expect(
        () => Adif('dart-adif', '1.0.0', [qso]).buildAdiString(),
        throwsArgumentError,
      );
    });

    test('removes non-ASCII characters and downgrades intl field names', () {
      final qso = Qso(
        <AdifField>[adifFieldFactory('COMMENT_INTL', 'ASCII你好')],
        const <Appdef>[],
        const <Userdef>[],
      );

      final adi = Adif('dart-adif', '1.0.0', [qso]).buildAdiString(
        nonAsciiFallback: NonAsciiBuildOption.removeCharacters,
      );

      expect(adi, contains('<COMMENT:5>ASCII'));
      expect(adi, isNot(contains('COMMENT_INTL')));
    });

    test('drops intl fields in removeFields build mode', () {
      final qso = Qso(
        <AdifField>[adifFieldFactory('COMMENT_INTL', 'ASCII你好')],
        const <Appdef>[],
        const <Userdef>[],
      );

      final adi = Adif('dart-adif', '1.0.0', [
        qso,
      ]).buildAdiString(nonAsciiFallback: NonAsciiBuildOption.removeFields);

      expect(adi, isNot(contains('COMMENT_INTL')));
      expect(adi, isNot(contains('ASCII')));
      expect(adi, contains('<EOR>'));
    });

    test(
      'upgrades parsed ADIF-defined strings to intl fields when allowed',
      () {
        const adi = '<EOH>\n<COMMENT:2>你好\n<EOR>\n';

        final parsed = AdifOperations.parseAdiString(
          adi,
          ignoreIllegals: false,
          nonAsciiParse: NonAsciiParseOption.parseByCharacter,
        );

        expect(parsed.data, hasLength(1));
        expect(parsed.data.single.adifdefs.single.fieldName, 'COMMENT_INTL');
        expect(parsed.data.single.adifdefs.single.getString(), '你好');
      },
    );

    test('throws on non-ASCII parse in strict mode', () {
      const adi = '<EOH>\n<COMMENT:2>你好\n<EOR>\n';

      expect(
        () => AdifOperations.parseAdiString(
          adi,
          ignoreIllegals: false,
          nonAsciiParse: NonAsciiParseOption.throwError,
        ),
        throwsArgumentError,
      );
    });

    test('distinguishes character length and byte length during parse', () {
      const adi = '<EOH>\n<COMMENT:2>你好\n<EOR>\n';

      final byCharacter = AdifOperations.parseAdiString(
        adi,
        ignoreIllegals: false,
        nonAsciiParse: NonAsciiParseOption.parseByCharacter,
      );
      expect(byCharacter.data.single.adifdefs.single.getString(), '你好');

      expect(
        () => AdifOperations.parseAdiString(
          adi,
          ignoreIllegals: false,
          nonAsciiParse: NonAsciiParseOption.parseByByte,
        ),
        throwsFormatException,
      );
    });
  });
}
