# Dart_adif

Amateur Data Interchange Format (ADIF) parser for Dart.

There are three parts among the version. The first part is _the version of the related ADIF file_, for example `315` refers to [ADIF 3.1.5](https://www.adif.org/315/ADIF_315.htm). The second and third part are the version of this library that is compatiple to the corresponding ADIF version.

**Note**:
+ Enumeration is not supported yet, and modes are considered as strings for now. Be cautious if other apps can parse from the modes exported from this library.
+ All the fields exported to ADX are considered as international as possible.

## Usage

First let's see the data structure of a QSO:

```dart
class Qso {
  /// The QSO's ADIF-defined fields.
  List<AdifField> adifdefs = [];

  /// TODO: The application-defined fields.
  List<Appdef> appdefs;

  /// TODO: The user-defined fields.
  List<Userdef> userdefs;
}
```

You can generate a QSO like this:

```dart
final call = adifFieldFactory('CALL', 'BA1ABC');
final date = adifFieldFactory('DATE', '20250505');

final qso = Qso([call, date], [], []);
```

And here is the structure of an ADIF object:

```dart
class Adif {
  /// The ADIF version. Generally defined by this library.
  String adifVer = adifVersion;

  /// Created timestamp, shall be converted to string when converting.
  /// Generated automatically.
  DateTime? createdTimestamp = DateTime.now().toUtc();

  /// The program's name.
  final String? programid;

  /// The program's version.
  final String? programversion;

  /// TODO: The userdefined fields.
  /// The `index`th one on the list refers to `USERDEF[index+1]` as for ADIF it
  /// shall be a postive number.
  List<String> userdef;

  /// The QSO data.
  List<Qso> data;

  Adif(this.programid, this.programversion, this.userdef, this.data);
}
```

Give the fields of your program, leave the `userdef` as empty, and put the QSOs together as a list, you can get an ADIF object:

```dart
// Generate an ADIF log.
final adif = Adif(
  "dart-adif.test_suites",
  "315.0.1",
  [],
  [qso1, qso2, qso3]);
```

Then export it into an ADX string:

```dart
final String adxString = adif.buildAdxString();
```

## Roadmap

### Supported ADIF Data types

+ [x] Boolean
+ [ ] Character
+ [ ] CreditList
+ [x] Date
+ [ ] Digit
+ [ ] Enumeration
+ [ ] GridSquare
+ [ ] GridSquareExt
+ [ ] GridSquareList
+ [x] Integer
+ [ ] IntlCharacter
+ [x] IntlMultilineString
+ [x] IntlString
+ [ ] IOTARefNo
+ [x] Location
+ [x] MultilineString
+ [x] Number
+ [x] PositiveInteger
+ [ ] POTARef
+ [ ] POTARefList
+ [ ] SecondarySubdivisionList
+ [ ] SecondaryAdministrativeSubdivisionListAlt
+ [ ] SOTARef
+ [ ] SponsoredAwardList
+ [x] String
+ [x] Time
+ [ ] WWFFRef

### Supported operations

+ [ ] Import from ADI
+ [ ] Export to ADI
+ [ ] Import from ADX
+ [x] Export to ADX

### Supported fields

+ [x] ADIF-defined fields
+ [ ] APP-defined fields
+ [ ] User-defied fields

### Supported ADIF-defined fields

+ ADDRESS
+ ADDRESS_INTL
+ CALL
+ CHECK
+ CLASS
+ CLUBLOG_QSO_UPLOAD_DATE
+ COMMENT
+ COMMENT_INTL
+ CONTACTED_OP
+ CONTEST_ID
+ COUNTRY
+ COUNTRY_INTL
+ CQZ
+ DCL_QSLRDATE
+ DCL_QSLSDATE
+ EMAIL
+ EQ_CALL
+ EQSL_QSLRDATE
+ EQSL_QSLSDATE
+ FISTS
+ FISTS_CC
+ FORCE_INIT
+ FREQ
+ FREQ_RX
+ GUEST_OP
+ HAMLOGEU_QSO_UPLOAD_DATE
+ HAMQTH_QSO_UPLOAD_DATE
+ HRDLOG_QSO_UPLOAD_DATE
+ IOTA_ISLAND_ID
+ ITUZ
+ K_INDEX
+ LAT
+ LON
+ LOTW_QSLRDATE
+ LOTW_QSLSDATE
+ MODE
+ MORSE_KEY_INFO
+ MS_SHOWER
+ MY_ANTENNA
+ MY_ANTENNA_INTL
+ MY_CITY
+ MY_CITY_INTL
+ MY_COUNTRY
+ MY_COUNTRY_INTL
+ MY_CQ_ZONE
+ MY_FISTS
+ MY_IOTA_ISLAND_ID
+ MY_ITU_ZONE
+ MY_LAT
+ MY_LON
+ MY_MORSE_KEY_INFO
+ MY_NAME
+ MY_NAME_INTL
+ MY_POSTAL_CODE
+ MY_POSTAL_CODE_INTL
+ MY_RIG
+ MY_RIG_INTL
+ MY_SIG
+ MY_SIG_INTL
+ MY_SIG_INFO
+ MY_SIG_INFO_INTL
+ MY_STREET
+ MY_STREET_INTL
+ NAME
+ NAME_INTL
+ NOTES
+ NOTES_INTL
+ NR_BURSTS
+ NR_PINGS
+ OPERATOR
+ OWNER_CALLSIGN
+ PFX
+ PRECEDENCE
+ PUBLIC_KEY
+ QRZCOM_QSO_DOWNLOAD_DATE
+ QRZCOM_QSO_UPLOAD_DATE
+ QSLMSG
+ QSLMSG_INTL
+ QSLMSG_RCVD
+ QSLRDATE
+ QSLSDATE
+ QSL_VIA
+ QSO_DATE
+ QSO_DATE_OFF
+ QSO_RANDOM
+ QTH
+ QTH_INTL
+ RIG
+ RIG_INTL
+ RST_RCVD
+ RST_SENT
+ SAT_MODE
+ SAT_NAME
+ SFI
+ SIG
+ SIG_INTL
+ SIG_INFO
+ SIG_INFO_INTL
+ SILENT_KEY
+ SKCC
+ SRX
+ SRX_STRING
+ STATION_CALLSIGN
+ STX
+ STX_STRING
+ SUBMODE
+ SWL
+ TEN_TEN
+ TIME_OFF
+ TIME_ON
+ UKSMG
+ VE_PROV
+ WEB
