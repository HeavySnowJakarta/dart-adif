/// This file defines basic data types used in ADIF files.
library;

import 'package:intl/intl.dart';
import '../type.dart';

/// ADIF Boolean type.
class AdifBoolean extends AdifGeneral<bool> {
  @override
  String getType() => 'B';
  @override
  String getString() => value ? 'Y' : 'N';

  AdifBoolean(super.value);

  static AdifBoolean fromString(String str) {
    if (str == 'Y' || str == 'y') {
      return AdifBoolean(true);
    } else if (str == 'N' || str == 'n') {
      return AdifBoolean(false);
    } else {
      throw ArgumentError('Invalid boolean string: $str');
    }
  }
}

/// ADIF Character type.
class AdifCharacter extends AdifGeneral<String> {
  @override
  String getType() => 'Character';
  @override
  String getString() => value;

  AdifCharacter(super.value) {
    if (value.length != 1) {
      throw ArgumentError('Value must be a single character: $value');
    }
  }

  static AdifCharacter fromString(String str) {
    if (str.length != 1) {
      throw ArgumentError('Invalid character string: $str');
    }
    return AdifCharacter(str);
  }
}

/// ADIF International Character type.
class AdifIntlCharacter extends AdifGeneral<String> {
  @override
  String getType() => 'IntlCharacter';
  @override
  String getString() => value;

  AdifIntlCharacter(super.value) {
    if (value.length != 1) {
      throw ArgumentError('Value must be a single character: $value');
    }
  }

  static AdifIntlCharacter fromString(String str) {
    if (str.length != 1) {
      throw ArgumentError('Invalid character string: $str');
    }
    return AdifIntlCharacter(str);
  }
}

/// ADIF Integer type.
class AdifInteger extends AdifGeneral<int> {
  @override
  String getType() => 'Integer';
  @override
  String getString() => value.toString();

  AdifInteger(super.value);
  static AdifInteger fromString(String str) {
    final intValue = int.tryParse(str);
    if (intValue == null) {
      throw ArgumentError('Invalid integer string: $str');
    }
    return AdifInteger(intValue);
  }
}

/// Postive integer type.
class AdifPositiveInteger extends AdifGeneral<int> {
  @override
  String getType() => 'PostiveInteger';
  @override
  String getString() => value.toString();

  AdifPositiveInteger(super.value) {
    if (value < 0) {
      throw ArgumentError('Value must be a positive integer: $value');
    }
  }

  static AdifPositiveInteger fromString(String str) {
    final intValue = int.tryParse(str);
    if (intValue == null || intValue < 0) {
      throw ArgumentError('Invalid positive integer string: $str');
    }
    return AdifPositiveInteger(intValue);
  }
}

/// Number type.
class AdifNumber extends AdifGeneral<double> {
  @override
  String getType() => 'N';
  @override
  String getString() => value.toString();

  AdifNumber(super.value);

  static AdifNumber fromString(String str) {
    final doubleValue = double.tryParse(str);
    if (doubleValue == null) {
      throw ArgumentError('Invalid number string: $str');
    }
    return AdifNumber(doubleValue);
  }
}

/// an ASCII character whose code lies in the range of 48 through 57, inclusive
class AdifDigit extends AdifGeneral<String> {
  @override
  String getType() => 'Digit';
  @override
  String getString() => value;

  AdifDigit(super.value) {
    if (value.length != 1 || !RegExp(r'^[0-9]$').hasMatch(value)) {
      throw ArgumentError('Value must be a single digit (0-9): $value');
    }
  }

  static AdifDigit fromString(String str) {
    if (str.length != 1 || !RegExp(r'^[0-9]$').hasMatch(str)) {
      throw ArgumentError('Invalid digit string: $str');
    }
    return AdifDigit(str);
  }
}

/// Date type, 8 digits in the format YYYYMMDD.
class AdifDate extends AdifGeneral<DateTime> {
  @override
  String getType() => 'D';
  @override
  String getString() => DateFormat('yyyyMMdd').format(value);

  AdifDate(super.value);
  static AdifDate fromString(String str) {
    try {
      final year = int.parse(str.substring(0, 4));
      final month = int.parse(str.substring(4, 6));
      final day = int.parse(str.substring(6, 8));
      final dateValue = DateTime(year, month, day);
      return AdifDate(dateValue);
    } catch (e) {
      throw ArgumentError('Invalid YYYYMMDD date string: $str');
    }
  }
}

/// Time type, 4 or 6 digits in the format HHMM/HHMMSS.
class AdifTime extends AdifGeneral<DateTime> {
  @override
  String getType() => 'T';
  @override
  String getString() => DateFormat('HHmmss').format(value);
  AdifTime(super.value);

  static AdifTime fromString(String str) {
    try {
      if (str.length == 4) {
        // HHMM
        final hour = int.parse(str.substring(0, 2));
        final minute = int.parse(str.substring(2, 4));
        return AdifTime(DateTime(0, 1, 1, hour, minute));
      } else if (str.length == 6) {
        // HHMMSS
        final hour = int.parse(str.substring(0, 2));
        final minute = int.parse(str.substring(2, 4));
        final second = int.parse(str.substring(4, 6));
        return AdifTime(DateTime(0, 1, 1, hour, minute, second));
      } else {
        throw ArgumentError('');
      }
    } catch (e) {
      throw ArgumentError('Invalid HHMM or HHMMSS time string: $str');
    }
  }
}

/// String type.
class AdifString extends AdifGeneral<String> {
  @override
  String getType() => 'S';
  @override
  String getString() => value;

  AdifString(super.value);
  static AdifString fromString(String str) {
    return AdifString(str);
  }
}

/// International string type, used for application and user defined fields
/// only when importing.
class AdifIntlString extends AdifGeneral<String> {
  @override
  String getType() => 'I';
  @override
  String getString() => value;

  AdifIntlString(super.value);
  static AdifIntlString fromString(String str) {
    return AdifIntlString(str);
  }
}

/// Multiline string type.
class AdifMultilineString extends AdifGeneral<String> {
  @override
  String getType() => 'M';
  @override
  String getString() => value;

  AdifMultilineString(super.value);

  static AdifMultilineString fromString(String str) {
    return AdifMultilineString(str);
  }
}

/// International multiline string type, used for application and user defined
/// fields only when importing.
class AdifIntlMultilineString extends AdifGeneral<String> {
  @override
  String getType() => 'G';
  @override
  String getString() => value;

  AdifIntlMultilineString(super.value);

  static AdifIntlMultilineString fromString(String str) {
    return AdifIntlMultilineString(str);
  }
}

/// Enumeration type. The derived class shall provide the list of valid enumerations,
/// and when initializing an instance, the value must be one among them.
/// The enumeration is case-insensitive, so they shall be provided in upper case.
abstract class AdifEnumeration extends AdifGeneral {
  @override
  String getType() => 'E';
  @override
  String getString() => value;

  AdifEnumeration(value, List<String> enumerations)
    : super(value.toUpperCase()) {
    if (!enumerations.contains(value.toUpperCase())) {
      throw ArgumentError(
        'Value must be one of the enumerations: $enumerations',
      );
    }
  }

  static AdifEnumeration fromString(String str) {
    throw UnimplementedError('fromString must be implemented in subclasses');
  }
}

/// a sequence of 11 characters representing a latitude or longitude in
/// XDDD MM.MMM format, where
/// - X is a directional Character from the set {E, W, N, S}
/// - DDD is a 3-Digit degrees specifier, where 0 <= DDD <= 180 (use leading
///   zeroes)
/// - There is a single space character in between DDD and MM.MMM
/// - MM.MMM is an unsigned Number minutes specifier with its decimal point
/// in the third position, where 00.000 <= MM.MMM <= 59.999  (use leading and
/// trailing zeroes)
class AdifLocation extends AdifGeneral<String> {
  @override
  String getType() => 'L';
  @override
  String getString() => value;

  AdifLocation(super.value);

  static AdifLocation fromString(String str) {
    // Validate the format XDDD MM.MMM
    final regex = RegExp(r'^[ENSW]\d{3} \d{2}\.\d{3}$');
    if (!regex.hasMatch(str)) {
      throw ArgumentError('Invalid location string: $str');
    }
    return AdifLocation(str);
  }
}

/// a case-insensitive 2-character, 4-character, 6-character, or 8-character
/// Maidenhead locator.
/// Specific fields impose additional restrictions on the number of characters;
/// see the field descriptions for the allowed numbers of characters.
class AdifGridSquare extends AdifGeneral<String> {
  @override
  String getType() => 'GridSquare';
  @override
  String getString() => value;

  AdifGridSquare(super.value) {
    final len = value.length;
    if (len != 2 && len != 4 && len != 6 && len != 8) {
      throw ArgumentError('Value must be 2, 4, 6, or 8 characters: $value');
    }
    final regex = RegExp(r'^[A-Ra-r]{2}([0-9]{2}([A-Ra-r]{2}([0-9]{2})?)?)?$');
    if (!regex.hasMatch(value)) {
      throw ArgumentError('Invalid Maidenhead locator: $value');
    }
  }

  static AdifGridSquare fromString(String str) {
    return AdifGridSquare(str);
  }
}

/// For a 10-character Maidenhead locator, contains characters 9 and 10.
/// For a 12-character Maidenhead locator, contains characters 9, 10, 11 and 12.
/// Characters 9 and 10 are case-insensitive ASCII letters in the range A-X.
/// Characters 11 and 12 are Digits in the range 0-9.
class AdifGridSquareExt extends AdifGeneral<String> {
  @override
  String getType() => 'GridSquareExt';
  @override
  String getString() => value;

  AdifGridSquareExt(super.value) {
    final len = value.length;
    if (len != 2 && len != 4) {
      throw ArgumentError('Value must be 2 or 4 characters: $value');
    }
    final regex = RegExp(r'^[A-Xa-x]{2}([0-9]{2})?$');
    if (!regex.hasMatch(value)) {
      throw ArgumentError('Invalid Maidenhead extended locator: $value');
    }
  }

  static AdifGridSquareExt fromString(String str) {
    return AdifGridSquareExt(str);
  }
}

/// a comma-delimited list of GridSquare items
class AdifGridSquareList extends AdifGeneral<List<AdifGridSquare>> {
  @override
  String getType() => 'GridSquareList';
  @override
  String getString() => value.map((e) => e.getString()).join(',');

  AdifGridSquareList(super.value);

  static AdifGridSquareList fromString(String str) {
    final parts = str.split(',').map((e) => e.trim()).toList();
    final gridSquares = parts.map((e) => AdifGridSquare.fromString(e)).toList();
    return AdifGridSquareList(gridSquares);
  }
}

/// a sequence of case-insensitive Characters representing a Parks on the Air
/// park reference in the form xxxx-nnnnn[@yyyyyy] comprising 6 to 17
/// characters where:
/// - xxxx is the POTA national program and is 1 to 4 characters in length,
/// typically the default callsign prefix of the national program (rather
/// than the DX entity)
/// - nnnnn represents the unique number within the national program and is
/// either 4 or 5 characters in length (use the exact format listed on the
/// POTA website)
/// - yyyyyy **Optional** is the 4 to 6 character ISO 3166-2 code to
/// differentiate which state/province/prefecture/primary administration
/// location the contact represents, in the case that the park reference spans
/// more than one location (such as a trail).
class AdifPOTARef extends AdifGeneral<String> {
  @override
  String getType() => 'POTARef';
  @override
  String getString() => value;

  AdifPOTARef(super.value) {
    final regex = RegExp(r'^[A-Za-z0-9]{1,4}-\d{4,5}(@[A-Za-z0-9]{4,6})?$');
    if (!regex.hasMatch(value)) {
      throw ArgumentError('Invalid POTA reference: $value');
    }
  }

  static AdifPOTARef fromString(String str) {
    return AdifPOTARef(str);
  }
}

/// a comma-delimited list of one or more POTARef items.
class AdifPOTARefList extends AdifGeneral<List<AdifPOTARef>> {
  @override
  String getType() => 'POTARefList';
  @override
  String getString() => value.map((e) => e.getString()).join(',');

  AdifPOTARefList(super.value);

  static AdifPOTARefList fromString(String str) {
    final parts = str.split(',').map((e) => e.trim()).toList();
    final potaRefs = parts.map((e) => AdifPOTARef.fromString(e)).toList();
    return AdifPOTARefList(potaRefs);
  }
}

/// a sequence of Characters representing an International SOTA Reference.
/// The sequence comprises:
/// an ITU prefix
/// if applicable, a SOTA subdivision
/// a / Character
/// a SOTA Reference Number
/// Examples:
/// W2/WE-003
/// G/LD-003
class AdifSOTARef extends AdifGeneral<String> {
  @override
  String getType() => 'SOTARef';
  @override
  String getString() => value;

  AdifSOTARef(super.value) {
    final regex = RegExp(r'^[A-Za-z0-9]+(/[A-Za-z0-9]+)?-\d{3}$');
    if (!regex.hasMatch(value)) {
      throw ArgumentError('Invalid SOTA reference: $value');
    }
  }

  static AdifSOTARef fromString(String str) {
    return AdifSOTARef(str);
  }
}

/// a sequence of case-insensitive Characters representing an International
/// WWFF (World Wildlife Flora & Fauna) reference in the form xxFF-nnnn
/// comprising 8 to 11 characters where:
/// xx is the WWFF national program and is 1 to 4 characters in length.
/// FF- is two F characters followed by a dash character.
/// nnnn represents the unique number within the national program and is
/// 4 characters in length with leading zeros.
/// Examples:
/// KFF-4655
/// 3DAFF-0002
class AdifWWFFRef extends AdifGeneral<String> {
  @override
  String getType() => 'WWFFRef';
  @override
  String getString() => value;

  AdifWWFFRef(super.value) {
    final regex = RegExp(r'^[A-Za-z0-9]{1,4}FF-\d{4}$');
    if (!regex.hasMatch(value)) {
      throw ArgumentError('Invalid WWFF reference: $value');
    }
  }

  static AdifWWFFRef fromString(String str) {
    return AdifWWFFRef(str);
  }
}
