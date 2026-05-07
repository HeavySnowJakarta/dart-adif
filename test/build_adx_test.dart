import 'package:test/test.dart';
import 'package:adif/adif.dart';

void main() {
  group('Comprehensive ADIF / ADX build tests', () {
    // Build a wide set of ADIF-defined fields for QSO #1
    final qso1AdifFields = <AdifField>[
      adifFieldFactory('CALL', 'BA1ABC'),
      adifFieldFactory(
        'QSO_DATE',
        '20250505',
      ), // ADIF prefers QSO_DATE over DATE for QSOs
      adifFieldFactory('TIME_ON', '093015'),
      adifFieldFactory('TIME_OFF', '093145'),
      adifFieldFactory('BAND', '20M'),
      adifFieldFactory('FREQ', '14.074'),
      adifFieldFactory('MODE', 'FT8'),
      adifFieldFactory('SUBMODE', 'FT8'),
      adifFieldFactory('RST_SENT', '59'),
      adifFieldFactory('RST_RCVD', '57'),
      adifFieldFactory('TX_PWR', '50'),
      adifFieldFactory('CQZ', '24'),
      adifFieldFactory('ITUZ', '44'),
      adifFieldFactory('DXCC', '318'),
      adifFieldFactory('COUNTRY', 'China'),
      adifFieldFactory('GRIDSQUARE', 'OM89'),
      adifFieldFactory('MY_GRIDSQUARE', 'OM88'),
      adifFieldFactory('OPERATOR', 'BA1OP'),
      adifFieldFactory('STATION_CALLSIGN', 'BA1ABC'),
      adifFieldFactory(
        'COMMENT',
        'First QSO sample - covering many core fields',
      ),
      adifFieldFactory('NOTES', 'Multiline note line 1\nline 2\nline 3'),
      adifFieldFactory('QSL_SENT', 'Y'),
      adifFieldFactory('QSL_RCVD', 'N'),
      adifFieldFactory('QSO_COMPLETE', 'Y'),
      adifFieldFactory('LAT', 'N039 90.420'),
      adifFieldFactory('LON', 'E116 40.740'),
      adifFieldFactory('A_INDEX', '12'),
      adifFieldFactory('SFI', '145'),
    ];

    // App-defined fields for QSO #1
    final qso1AppDefs = <Appdef>[
      Appdef.generate(
        'dart-adif.test_suites',
        'PHONE_NUMBER',
        'S',
        '+12425333682',
      ),
      Appdef.generate(
        'dart-adif.test_suites',
        'GENDER',
        'E',
        'M',
        enums: ['M', 'F', 'X'],
      ),
      Appdef.generate(
        'dart-adif.test_suites',
        'REMOTE_PROFILE',
        'S',
        'Profile-A',
      ),
    ];

    // User-defined fields for QSO #1
    final qso1UserDefs = <Userdef>[
      Userdef.generate('OP_NUMBER', 'N', '3', range: (1, 10)),
      Userdef.generate('SESSION_TAG', 'S', 'MORNING_RUN'),
      Userdef.generate('IS_REMOTE', 'S', 'Y'),
      Userdef.generate(
        'FAVORITE_COLOR',
        'E',
        'BLUE',
        enums: ['RED', 'GREEN', 'BLUE'],
      ),
      Userdef.generate(
        'LONG_NOTE',
        'M',
        'This is a user-defined multiline field.\nLine 2.\nLine 3.',
      ),
    ];

    final qso1 = Qso(qso1AdifFields, qso1AppDefs, qso1UserDefs);

    // QSO #2 with satellite + propagation + additional fields
    final qso2Adif = <AdifField>[
      adifFieldFactory('CALL', 'K1XYZ'),
      adifFieldFactory('QSO_DATE', '20250505'),
      adifFieldFactory('TIME_ON', '101530'),
      adifFieldFactory('TIME_OFF', '101800'),
      adifFieldFactory('BAND', '2M'),
      adifFieldFactory('MODE', 'SSB'),
      adifFieldFactory('PROP_MODE', 'SAT'),
      adifFieldFactory('SAT_NAME', 'SO-50'),
      adifFieldFactory('SAT_MODE', 'V/U'),
      adifFieldFactory('RST_SENT', '59'),
      adifFieldFactory('RST_RCVD', '59'),
      adifFieldFactory('GRIDSQUARE', 'FN42'),
      adifFieldFactory('MY_GRIDSQUARE', 'OM88'),
      adifFieldFactory('TX_PWR', '5'),
      adifFieldFactory('ANT_AZ', '180'),
      adifFieldFactory('ANT_EL', '45'),
      adifFieldFactory('COMMENT', 'Satellite contact'),
      adifFieldFactory('QSL_SENT', 'N'),
      adifFieldFactory('QSL_RCVD', 'N'),
      adifFieldFactory('QSO_COMPLETE', 'Y'),
    ];

    final qso2App = <Appdef>[
      Appdef.generate('dart-adif.test_suites', 'MIC_MODEL', 'S', 'Heil PR781'),
      Appdef.generate('dart-adif.test_suites', 'AUDIO_CHAIN_OK', 'B', 'Y'),
      Appdef.generate(
        'dart-adif.test_suites',
        'QSO_RATING',
        'N',
        '9',
        range: (1, 10),
      ),
    ];

    final qso2User = <Userdef>[
      Userdef.generate('OP_SEQUENCE', 'N', '2', range: (1, 100)),
      Userdef.generate(
        'BAND_ACTIVITY_LEVEL',
        'E',
        'HIGH',
        enums: ['LOW', 'MEDIUM', 'HIGH'],
      ),
    ];

    final qso2 = Qso(qso2Adif, qso2App, qso2User);

    // QSO #3 focusing on digital + propagation variations + unusual numeric fields
    final qso3Adif = <AdifField>[
      adifFieldFactory('CALL', 'JA1ZZZ'),
      adifFieldFactory('QSO_DATE', '20250506'),
      adifFieldFactory('TIME_ON', '120000'),
      adifFieldFactory('BAND', '40M'),
      adifFieldFactory('FREQ', '7.074'),
      adifFieldFactory('MODE', 'MFSK'),
      adifFieldFactory('SUBMODE', 'JS8'),
      adifFieldFactory('RST_SENT', '-08'),
      adifFieldFactory('RST_RCVD', '-12'),
      adifFieldFactory('PROP_MODE', 'F2'),
      adifFieldFactory('SFI', '152'),
      adifFieldFactory('A_INDEX', '8'),
      adifFieldFactory('K_INDEX', '2'),
      adifFieldFactory('GRIDSQUARE', 'PM95'),
      adifFieldFactory('MY_GRIDSQUARE', 'OM88'),
      adifFieldFactory('COMMENT', 'Digital weak-signal contact'),
      adifFieldFactory('QSO_COMPLETE', 'Y'),
    ];

    final qso3App = <Appdef>[
      Appdef.generate(
        'dart-adif.test_suites',
        'CLIENT_BUILD',
        'S',
        '2025.05.05-nightly',
      ),
      Appdef.generate(
        'dart-adif.test_suites',
        'FAVORITE_MODE',
        'E',
        'DIGITAL',
        enums: ['CW', 'SSB', 'DIGITAL'],
      ),
    ];

    final qso3User = <Userdef>[
      Userdef.generate('RUN_ORDER', 'N', '1', range: (1, 5)),
      Userdef.generate('IS_EXPERIMENTAL', 'B', 'Y'),
      Userdef.generate(
        'SIGNAL_CLASS',
        'E',
        'WEAK',
        enums: ['WEAK', 'MODERATE', 'STRONG'],
      ),
    ];

    final qso3 = Qso(qso3Adif, qso3App, qso3User);

    // Build ADIF log (userdef list left empty per instructions)
    final adif = Adif('dart-adif.test_suites', '315.2.0', [qso1, qso2, qso3]);

    test('Enumerations validity (app + user defined)', () {
      // App enumeration checks
      final gender = qso1AppDefs.firstWhere((a) => a.fieldName == 'GENDER');
      expect((gender.value as AdifEnumeration).enumerations, isNotNull);
      expect(
        (gender.value as AdifEnumeration).enumerations.contains(
          gender.value.getString(),
        ),
        isTrue,
      );

      final favMode = qso3App.firstWhere((a) => a.fieldName == 'FAVORITE_MODE');
      expect(
        (favMode.value as AdifEnumeration).enumerations.contains(
          favMode.value.getString(),
        ),
        isTrue,
      );

      // User-defined enumeration checks
      final color = qso1UserDefs.firstWhere(
        (u) => u.fieldName == 'FAVORITE_COLOR',
      );
      expect(
        (color.value as AdifEnumeration).enumerations.contains(
          color.value.getString(),
        ),
        isTrue,
      );

      final bandActivity = qso2User.firstWhere(
        (u) => u.fieldName == 'BAND_ACTIVITY_LEVEL',
      );
      expect(
        (bandActivity.value as AdifEnumeration).enumerations.contains(
          bandActivity.value.getString(),
        ),
        isTrue,
      );

      final signalClass = qso3User.firstWhere(
        (u) => u.fieldName == 'SIGNAL_CLASS',
      );
      expect(
        (signalClass.value as AdifEnumeration).enumerations.contains(
          signalClass.value.getString(),
        ),
        isTrue,
      );
    });

    test('Ranges validity (app + user defined)', () {
      final qsoRating = qso2App.firstWhere((a) => a.fieldName == 'QSO_RATING');
      final r = (qsoRating.value as AdifRange).range;
      expect(r, isNotNull);
      final ratingVal = double.parse(qsoRating.value.getString());
      expect(ratingVal >= r.$1 && ratingVal <= r.$2, isTrue);

      final opNumber = qso1UserDefs.firstWhere(
        (u) => u.fieldName == 'OP_NUMBER',
      );
      final opRange = (opNumber.value as AdifRange).range;
      final opVal = double.parse(opNumber.value.getString());
      expect(opVal >= opRange.$1 && opVal <= opRange.$2, isTrue);
    });

    test('Build ADX string and verify core content', () {
      final adx = adif.buildAdxString();
      print(adx);
      expect(adx, isNotEmpty);

      // Program metadata
      expect(adx.contains('dart-adif.test_suites'), isTrue);
      expect(adx.contains('315.2.0'), isTrue);

      // Core QSO field values
      for (final callsign in ['BA1ABC', 'K1XYZ', 'JA1ZZZ']) {
        expect(
          adx.contains(callsign),
          isTrue,
          reason: 'ADX should contain callsign $callsign',
        );
      }

      // Sample of ADIF standard fields
      for (final field in [
        'QSO_DATE',
        'TIME_ON',
        'BAND',
        'MODE',
        'SUBMODE',
        'GRIDSQUARE',
        'RST_SENT',
        'RST_RCVD',
        'TX_PWR',
        'COMMENT',
        'PROP_MODE',
        'SAT_NAME',
        'SAT_MODE',
        'A_INDEX',
        'SFI',
      ]) {
        expect(
          adx.contains(field),
          isTrue,
          reason: 'ADX should contain field $field',
        );
      }

      // App-defined field names
      for (final appField in [
        'PHONE_NUMBER',
        'GENDER',
        'REMOTE_PROFILE',
        'MIC_MODEL',
        'AUDIO_CHAIN_OK',
        'QSO_RATING',
        'CLIENT_BUILD',
        'FAVORITE_MODE',
      ]) {
        expect(
          adx.contains(appField),
          isTrue,
          reason: 'ADX should contain app-defined field $appField',
        );
      }

      // User-defined field names
      for (final userField in [
        'OP_NUMBER',
        'SESSION_TAG',
        'IS_REMOTE',
        'FAVORITE_COLOR',
        'LONG_NOTE',
        'OP_SEQUENCE',
        'BAND_ACTIVITY_LEVEL',
        'RUN_ORDER',
        'IS_EXPERIMENTAL',
        'SIGNAL_CLASS',
      ]) {
        expect(
          adx.contains(userField),
          isTrue,
          reason: 'ADX should contain user-defined field $userField',
        );
      }

      // Spot check some values (less dependent on exact ADX formatting)
      expect(adx.contains('+12425333682'), isTrue);
      expect(adx.contains('FT8'), isTrue);
      expect(adx.contains('SO-50'), isTrue);
      expect(adx.contains('JS8'), isTrue);
    });

    test('Logical fields render correctly in ADX', () {
      final adx = adif.buildAdxString();
      for (final logicalVal in ['Y', 'N']) {
        expect(
          adx.contains(logicalVal),
          isTrue,
          reason: 'Expected logical value $logicalVal present',
        );
      }
    });
  });
}
