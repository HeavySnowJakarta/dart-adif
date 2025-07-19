/// This file defines some data types and the corresponding data.
library;

/// Used for application and user defined fields, which can be used to express
/// different types of data.
/// Please refer to [AdifBoolean], [AdifInteger], [AdifNumber], [AdifDate],
/// [AdifTime], [AdifString], [AdifIntlString], [AdifMultilineString],
/// [AdifIntlMultilineString], and [AdifEnumeration] for more details.
abstract class AdifGeneral<T> {
  T value;
  String getType();

  AdifGeneral(this.value);

  /// The original data of the adif data.
  T get original => value;

  static AdifGeneral fromOriginal<T>(T original) {
    throw UnimplementedError('fromOriginal must be implemented in subclasses');
  }

  String getString();
  static AdifGeneral fromString(String str) {
    throw UnimplementedError('fromString must be implemented in subclasses');
  }
}
