// The test case of building an ADX file.
import 'package:adif/adif.dart';

Qso buildQso(call, mode, qsoDate, timeOn, freq) {
  final callQso = adifFieldFactory('CALL', call);
  // final bandQso = adifFieldFactory('BAND', band);
  final modeQso = adifFieldFactory('MODE', mode);
  final qsoDateQso = adifFieldFactory('QSO_DATE', qsoDate);
  final timeOnQso = adifFieldFactory('TIME_ON', timeOn);
  final freqQso = adifFieldFactory('FREQ', freq);
  return Qso(
    [callQso, modeQso, qsoDateQso, timeOnQso, freqQso],
    [],
    [],
  );
}

void main() {
  // Build QSOs.
  final qso1 = buildQso('K1ABC', 'SSB', '20231001', '1200', '14.200');
  final qso2 = buildQso('K2DEF', 'CW', '20231001', '1300', '7.050');
  final qso3 = buildQso('K3GHI', 'FT8', '20231001', '1400', '3.580');

  // Generate an ADIF log.
  final adif = Adif(
    "dart-adif.test_suites",
    "315.0.1",
    [],
    [qso1, qso2, qso3]);

  final adxString = adif.buildAdxString();
  print(adxString);
}
