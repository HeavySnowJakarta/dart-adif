/// This file defines basic data types used in ADIF files.

import 'package:intl/intl.dart';
import '../type.dart';

/// Boolean type.
class AdifBoolean extends AdifGeneral {
  final bool value;

  @override
  String getType() => 'B';
  @override
  String getString() => value ? 'Y' : 'N';

  AdifBoolean(this.value);

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

/// Integer type.
class AdifInteger extends AdifGeneral {
  final int value;

  @override
  String getType() => 'Integer';
  @override
  String getString() => value.toString();

  AdifInteger(this.value);
  static AdifInteger fromString(String str) {
    final intValue = int.tryParse(str);
    if (intValue == null) {
      throw ArgumentError('Invalid integer string: $str');
    }
    return AdifInteger(intValue);
  }
}

/// Number type.
class AdifNumber extends AdifGeneral {
  final double value;

  @override
  String getType() => 'N';
  @override
  String getString() => value.toString();

  AdifNumber(this.value);

  static AdifNumber fromString(String str) {
    final doubleValue = double.tryParse(str);
    if (doubleValue == null) {
      throw ArgumentError('Invalid number string: $str');
    }
    return AdifNumber(doubleValue);
  }
}

/// Date type, 8 digits in the format YYYYMMDD.
class AdifDate extends AdifGeneral {
  final DateTime value;

  @override
  String getType() => 'D';
  @override
  String getString() => DateFormat('yyyyMMdd').format(value);
  
  AdifDate(this.value);
  static AdifDate fromString(String str) {
    final dateValue = DateFormat('yyyyMMdd').parseStrict(str);
    return AdifDate(dateValue);
  }
}

/// Time type, 4 or 6 digits in the format HHMM/HHMMSS.
class AdifTime extends AdifGeneral {
  // 4/6 digits in the format HHMMSS.
  final DateTime value;
  
  @override
  String getType() => 'T';
  @override
  String getString() => DateFormat('HHmmss').format(value);
  
  AdifTime(this.value);
  
  static AdifTime fromString(String str) {
    if (str.length == 4) {
      // HHMM
      final timeValue = DateFormat('HHmm').parseStrict(str);
      return AdifTime(DateTime(0, 1, 1, timeValue.hour, timeValue.minute));
    } else if (str.length == 6) {
      // HHMMSS
      final timeValue = DateFormat('HHmmss').parseStrict(str);
      return AdifTime(
        DateTime(0, 1, 1, timeValue.hour, timeValue.minute, timeValue.second)
      );
    } else {
      throw ArgumentError('Invalid time string: $str');
    }
  }
}

/// String type.
class AdifString extends AdifGeneral {
  final String value;
  
  @override
  String getType() => 'S';
  @override
  String getString() => value;
  
  AdifString(this.value);
  static AdifString fromString(String str) {
    return AdifString(str);
  }
}

/// International string type, used for application and user defined fields
/// only when importing.
class AdifIntlString extends AdifGeneral {
  final String value;
  
  @override
  String getType() => 'I';
  @override
  String getString() => value;
  
  AdifIntlString(this.value);
  static AdifIntlString fromString(String str) {
    return AdifIntlString(str);
  }
}

/// Multiline string type.
class AdifMultilineString extends AdifGeneral {
  final String value;

  @override
  String getType() => 'M';
  @override
  String getString() => value;
  
  AdifMultilineString(this.value);

  static AdifMultilineString fromString(String str) {
    return AdifMultilineString(str);
  }
}

/// International multiline string type, used for application and user defined
/// fields only when importing.
class AdifIntlMultilineString extends AdifGeneral {
  final String value;

  @override
  String getType() => 'G';
  @override
  String getString() => value;

  AdifIntlMultilineString(this.value);

  static AdifIntlMultilineString fromString(String str) {
    return AdifIntlMultilineString(str);
  }
}

/// TODO: Enumeration type.
// class AdifEnumeration extends AdifGeneral {
//   final List<String> enumerations;
//   final String value;

//   AdifEnumeration(this.enumerations, this.value) : super(AdifType.enumeration);
// }

/// a sequence of 11 characters representing a latitude or longitude in
/// XDDD MM.MMM format, where
/// - X is a directional Character from the set {E, W, N, S}
/// - DDD is a 3-Digit degrees specifier, where 0 <= DDD <= 180 [use leading
///   zeroes]
/// - There is a single space character in between DDD and MM.MMM
/// - MM.MMM is an unsigned Number minutes specifier with its decimal point
/// in the third position, where 00.000 <= MM.MMM <= 59.999  [use leading and
/// trailing zeroes]
class AdifLocation extends AdifGeneral {
  final String value;
  
  @override
  String getType() => 'L';
  @override
  String getString() => value;
  
  AdifLocation(this.value);
  
  static AdifLocation fromString(String str) {
    // Validate the format XDDD MM.MMM
    final regex = RegExp(r'^[ENSW]\d{3} \d{2}\.\d{3}$');
    if (!regex.hasMatch(str)) {
      throw ArgumentError('Invalid location string: $str');
    }
    return AdifLocation(str);
  }
}
