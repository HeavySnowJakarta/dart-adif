// The test case of building an ADX file.
import 'package:adif/adif.dart';

Qso buildQso() {
  final callQso = adifFieldFactory('CALL', 'JA1ABC');
  final bandQso = adifFieldFactory('BAND', '20M');
  final modeQso = adifFieldFactory('MODE', 'SSB');
  final qsoDateQso = adifFieldFactory('QSO_DATE', '20231015');
  final timeOnQso = adifFieldFactory('TIME_ON', '123000');
  final timeOffQso = adifFieldFactory('TIME_OFF', '123500');
  final freqQso = adifFieldFactory('FREQ', '14.200');
  final rstSentQso = adifFieldFactory('RST_SENT', '59');
  final rstRcvdQso = adifFieldFactory('RST_RCVD', '59');
  final nameQso = adifFieldFactory('NAME', 'Tanaka');
  final qthQso = adifFieldFactory('QTH', 'Tokyo');
  final gridQso = adifFieldFactory('GRIDSQUARE', 'PM95gr');
  final myGridQso = adifFieldFactory('MY_GRIDSQUARE', 'FN20hi');
  final myCallQso = adifFieldFactory('STATION_CALLSIGN', 'W1XYZ');
  final txPwrQso = adifFieldFactory('TX_PWR', '100');
  final commentQso = adifFieldFactory('COMMENT', 'Nice QSO from Tokyo');
  final qslSentQso = adifFieldFactory('QSL_SENT', 'Y');
  final qslRcvdQso = adifFieldFactory('QSL_RCVD', 'Y');
  final contQso = adifFieldFactory('CONT', 'AS');
  final countryQso = adifFieldFactory('COUNTRY', 'Japan');
  final myCountryQso = adifFieldFactory('MY_COUNTRY', 'United States');
  final dxccQso = adifFieldFactory('DXCC', '339');
  final myDxccQso = adifFieldFactory('MY_DXCC', '291');
  final cqzQso = adifFieldFactory('CQZ', '25');
  final ituzQso = adifFieldFactory('ITUZ', '45');
  final latQso = adifFieldFactory('LAT', 'N035 41.321');
  final lonQso = adifFieldFactory('LON', 'E139 46.074');
  final myLatQso = adifFieldFactory('MY_LAT', 'N040 45.069');
  final myLonQso = adifFieldFactory('MY_LON', 'W073 59.395');

  return Qso(
    [callQso, bandQso, modeQso, qsoDateQso, timeOnQso, timeOffQso, freqQso, 
     rstSentQso, rstRcvdQso, nameQso, qthQso, gridQso, myGridQso, myCallQso,
     txPwrQso, commentQso, qslSentQso, qslRcvdQso, contQso,
     countryQso, myCountryQso, dxccQso, myDxccQso, cqzQso,
     ituzQso, latQso, lonQso, myLatQso, myLonQso],
    [],
    [],
  );
}

Qso buildQso2() {
  final callQso = adifFieldFactory('CALL', 'VK2DEF');
  final bandQso = adifFieldFactory('BAND', '40M');
  final modeQso = adifFieldFactory('MODE', 'CW');
  final qsoDateQso = adifFieldFactory('QSO_DATE', '20231016');
  final timeOnQso = adifFieldFactory('TIME_ON', '081500');
  final freqQso = adifFieldFactory('FREQ', '7.025');
  final rstSentQso = adifFieldFactory('RST_SENT', '599');
  final rstRcvdQso = adifFieldFactory('RST_RCVD', '579');
  final ageQso = adifFieldFactory('AGE', '45');
  final operatorQso = adifFieldFactory('OPERATOR', 'W1XYZ');
  final rigQso = adifFieldFactory('MY_RIG', 'Yaesu FT-991A');
  final antQso = adifFieldFactory('MY_ANTENNA', 'Dipole');
  final propModeQso = adifFieldFactory('PROP_MODE', 'F2');
  final contestIdQso = adifFieldFactory('CONTEST_ID', 'CQ-WW-CW');
  final srrQso = adifFieldFactory('SRX', '001');
  final stxQso = adifFieldFactory('STX', '025');

  return Qso(
    [callQso, bandQso, modeQso, qsoDateQso, timeOnQso, freqQso,
     rstSentQso, rstRcvdQso, ageQso, operatorQso, rigQso, antQso,
     propModeQso, contestIdQso, srrQso, stxQso],
    [],
    [],
  );
}

Qso buildQso3() {
  final callQso = adifFieldFactory('CALL', 'DL5GHI');
  final bandQso = adifFieldFactory('BAND', '80M');
  final modeQso = adifFieldFactory('MODE', 'FT8');
  final qsoDateQso = adifFieldFactory('QSO_DATE', '20231017');
  final timeOnQso = adifFieldFactory('TIME_ON', '210000');
  final freqQso = adifFieldFactory('FREQ', '3.573');
  final rstSentQso = adifFieldFactory('RST_SENT', '-10');
  final rstRcvdQso = adifFieldFactory('RST_RCVD', '-08');
  final emailQso = adifFieldFactory('EMAIL', 'dl5ghi@example.com');
  final webQso = adifFieldFactory('WEB', 'https://qrz.com/db/DL5GHI');
  final qslMsgQso = adifFieldFactory('QSLMSG', 'TNX QSO 73');
  final notesQso = adifFieldFactory('NOTES', 'Strong signal from Germany');
  final maxBurstsQso = adifFieldFactory('MAX_BURSTS', '4');
  final msPingsQso = adifFieldFactory('MS_SHOWER', 'PER');
  final nrBurstsQso = adifFieldFactory('NR_BURSTS', '2');
  final nrPingsQso = adifFieldFactory('NR_PINGS', '12');

  return Qso(
    [callQso, bandQso, modeQso, qsoDateQso, timeOnQso, freqQso,
     rstSentQso, rstRcvdQso, emailQso, webQso, qslMsgQso, notesQso,
     maxBurstsQso, msPingsQso, nrBurstsQso, nrPingsQso],
    [],
    [],
  );
}

void main() {
  // Build QSOs with various ADIF fields
  final qso1 = buildQso();
  final qso2 = buildQso2();
  final qso3 = buildQso3();

  // Generate an ADIF log
  final adif = Adif(
    "dart-adif.test_suites",
    "315.0.1",
    [],
    [qso1, qso2, qso3]);

  final adxString = adif.buildAdxString();
  print(adxString);
}