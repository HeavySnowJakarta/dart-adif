/// This file defines some data types and the corresponding data.

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
