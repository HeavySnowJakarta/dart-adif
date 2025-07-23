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
    try{
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
    }
    catch (e) {
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

// TODO: Enumeration type.
// class AdifEnumeration extends AdifGeneral {
//   final List<String> enumerations;
//   final String value;

//   AdifEnumeration(this.enumerations, this.value) : super(AdifType.enumeration);
// }

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
