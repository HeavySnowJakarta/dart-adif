# Dart_adif

Amateur Data Interchange Format (ADIF) parser for Dart.

There are three parts among the version. The first part is _the version of the related ADIF file_, for example `315` refers to [ADIF 3.1.5](https://www.adif.org/315/ADIF_315.htm). The second and third part are the version of this library that is compatiple to the corresponding ADIF version.

This library is still under active development. Now it supports exproting ADIF-defined fields to ADX files, on the next version APP/user-defined fields and importing from ADX files will also be supported, and eventually ADI files.

**Note**:
+ Submodes are considered as [strings](https://www.adif.org/315/ADIF_315.htm#QSO_Field_SUBMODE), but please use [the submodes enumeration](https://www.adif.org/315/ADIF_315.htm#Submode_Enumeration) for interoperability.
+ All the fields exported to ADX are considered as international as possible.

**Breaking updates from `v315.0.1`**:
+ Modes have been **no longer** considered as strings. Instead they must be one of [the modes enumeration](https://www.adif.org/315/ADIF_315.htm#Mode_Enumeration) or [the submodes enumeration](https://www.adif.org/315/ADIF_315.htm#Submode_Enumeration). Attempts to set a mode as one not among them will fail.
* Bands have been **no longer** considered as strings. Instead thay must be one of [the bands enumeration](https://www.adif.org/315/ADIF_315.htm#Band_Enumeration).

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
  "315.1.1",
  [],
  [qso1, qso2, qso3]);
```

Then export it into an ADX string:

```dart
final String adxString = adif.buildAdxString();
```

## Roadmap

### Supported ADIF Data types

+ [x] AwardList
+ [x] Boolean
+ [x] Character
+ [x] CreditList
+ [x] Date
+ [x] Digit
+ [x] Enumeration
+ [x] GridSquare
+ [x] GridSquareExt
+ [x] GridSquareList
+ [x] Integer
+ [x] IntlCharacter
+ [x] IntlMultilineString
+ [x] IntlString
+ [x] IOTARefNo
+ [x] Location
+ [x] MultilineString
+ [x] Number
+ [x] PositiveInteger
+ [x] POTARef
+ [x] POTARefList
+ [x] SecondarySubdivisionList (`Secondary_Administrative_Subdivision_Alt` items are treated as strings)
+ [ ] SecondaryAdministrativeSubdivisionListAlt
+ [x] SOTARef
+ [ ] SponsoredAwardList
+ [x] String
+ [x] Time
+ [x] WWFFRef

### Supported operations

+ [ ] Import from ADI
+ [ ] Export to ADI
+ [ ] Import from ADX
+ [x] Export to ADX

### Supported fields

+ [x] ADIF-defined fields
+ [ ] APP-defined fields
+ [ ] User-defied fields

### Unupported ADIF-defined fields

+ AWARD_SUBMITTED
+ AWARD_GRANTED
+ CNTY
+ CNTY_ALT
+ DARK_DOK
+ MY_CNTY
+ MY_CNTY_ALT
+ MY_DARK_DOK
+ MY_STATE
+ STATE
