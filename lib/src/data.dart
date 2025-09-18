/// This file defines the structure of a log file and a QSO.
/// Currently not all fields are supported, but it may update in the future.
library;

import './basic.dart';
import './type.dart';

/// A ADIF-defined QSO field. Any classes that implement this class shall be
/// defined by the ADIF format document.
abstract class AdifField {
  /// The field name. It must be UPPER_SNAKE_CASE style.
  final String fieldName;

  /// The method to get it value as a string.
  String getString();

  // TODO: The method to get the original type.

  /// The method to parse the value from a string.
  static AdifField fromString(String str) {
    throw UnimplementedError('fromString must be implemented in subclasses');
  }

  AdifField(this.fieldName);
}

/// An application-defined field of a QSO.
class Appdef {
  /// The program's name.
  final String programid;

  /// The field's name.
  final String fieldname;

  /// The field's value.
  final AdifGeneral value;

  Appdef(this.programid, this.fieldname, this.value);
}

/// A user-defined field of a QSO.
class Userdef {
  /// The field's name.
  final String fieldname;

  /// The field's value.
  final AdifGeneral value;

  Userdef(this.fieldname, this.value);
}

/// The structure of each QSO. The major fields are the same with ADIF defined
/// formats (converted from UPPER_SNAKE_CASE to lowerCamelCase).
///
/// When exporting to ADX files, fields marked with "INTL compatible" will be
/// always converted to its corresponding INTL field, no matter whether
/// non-ASCII characters are used. For example, `NOTE_INTL` will be always used
/// when exporting to ADX instead of `NOTE`. Fields that don't have its
/// corresponding INTL field will be marked as "ASCII only".
class Qso {
  /// The QSO's ADIF-defined fields.
  List<AdifField> adifdefs = [];

  /// The application-defined fields.
  List<Appdef> appdefs;

  /// The user-defined fields.
  List<Userdef> userdefs;

  Qso(this.adifdefs, this.appdefs, this.userdefs);
}

/// An ADIF log file's structure.
/// For Dart's favor all UPPER_SNAKE_CASE style fields have been converted to
/// lowerCamelCase style.
class Adif {
  /// The ADIF version.
  String adifVer = adifVersion;

  /// Created timestamp, shall be converted to string when converting.
  DateTime? createdTimestamp = DateTime.now().toUtc();

  /// The program's name.
  final String? programid;

  /// The program's version.
  final String? programversion;

  /// The userdefined fields.
  /// The `index`th one on the list refers to `USERDEF[index+1]` as for ADIF it
  /// shall be a postive number.
  List<String> userdef;

  /// The QSO data.
  List<Qso> data;

  Adif(this.programid, this.programversion, this.userdef, this.data);
}
