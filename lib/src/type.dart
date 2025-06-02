/// This file defines some data types and the corresponding data.

// /// Types used in ADIF files.
// /// Attention: [AdifType.intlString] is only used for importing application and
// /// user defined fields in ADX files.
// /// All ADIF original fields shall use [AdifType.string] instead as this library
// /// does not distinguish INTL fields or not.
// /// All fields to import are considered as Unicode strings and all
// /// fields will be exported as INTL fields as possible.
// /// So does [AdifType.intlMultilineString].
// ///
// /// The enumeration values keeps the same as the ADIF specification, which have
// /// been converted from UpperCamelCase style to lowerCamelCase style.
// enum AdifType {
//   boolean,
//   integer,
//   number,
//   date,
//   time,
//   string,
//   intlString,
//   multilineString,
//   intlMultilineString,
//   enumeration,
//   location,
// }

// /// Get the corresponding type character from [AdifType].
// String adifTypeToChar(AdifType type) {
//   switch (type) {
//     case AdifType.boolean:
//       return 'B';
//     case AdifType.integer:
//       return 'I';
//     case AdifType.number:
//       return 'N';
//     case AdifType.date:
//       return 'D';
//     case AdifType.time:
//       return 'T';
//     case AdifType.string:
//       return 'S';
//     case AdifType.intlString:
//       return 'I';
//     case AdifType.multilineString:
//       return 'M';
//     case AdifType.intlMultilineString:
//       return 'G';
//     case AdifType.enumeration:
//       return 'E';
//     case AdifType.location:
//       return 'L';
//   }
// }

/// Used for application and user defined fields, which can be used to express
/// different types of data.
/// Please refer to [AdifBoolean], [AdifInteger], [AdifNumber], [AdifDate],
/// [AdifTime], [AdifString], [AdifIntlString], [AdifMultilineString],
/// [AdifIntlMultilineString], and [AdifEnumeration] for more details.
abstract class AdifGeneral {
  String getType();

  String getString();
  static AdifGeneral fromString(String str){
    throw UnimplementedError('fromString must be implemented in subclasses');
  }
}
