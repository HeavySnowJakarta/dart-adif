/// This file defines the structure of a log file and a QSO.
/// Currently not all fields are supported, but it may update in the future.
library;

import './data_types/index.dart';
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
  final String fieldName;

  /// The field's value.
  final AdifGeneral value;

  Appdef(this.programid, this.fieldName, this.value);

  /// Generate an app-defined field from values of string.
  Appdef.generate(
    this.programid,
    this.fieldName,
    String type,
    String valueString, {
    List<String>? enums,
    (double min, double max)? range,
  }) : value = createAdifContentFromString(valueString, type, enums, range);
}

/// A user-defined field of a QSO.
class Userdef {
  /// The field's name.
  final String fieldName;

  /// The field's value.
  final AdifGeneral value;

  Userdef(this.fieldName, this.value);

  /// Generate a user-defined field from values of string.
  Userdef.generate(
    this.fieldName,
    String type,
    String valueString, {
    List<String>? enums,
    (double min, double max)? range,
  }) : value = createAdifContentFromString(valueString, type, enums, range);
}

/// Metadata of a user-defined field, stored on the header of a ADIF file.
class UserdefMeta {
  final String name;
  final String type;
  final List<String>? enums;
  final (double min, double max)? range;

  UserdefMeta(this.name, this.type, {this.enums, this.range});
}

extension UserdefMetaOps on List<UserdefMeta> {
  /// Get a user-defined field's metadata by its index, starting from 1.
  UserdefMeta? getByIndex(int index) {
    if (index < 1 || index > length) {
      return null;
    }
    return this[index - 1];
  }

  /// Get a user-defined field's metadata by its name.
  UserdefMeta? getByName(String name) {
    try {
      return firstWhere((element) => element.name == name);
    } catch (e) {
      return null;
    }
  }
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

  /// The QSO data.
  List<Qso> data;

  Adif(this.programid, this.programversion, this.data);
}
