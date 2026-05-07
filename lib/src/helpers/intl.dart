/// See whether the string contains non-ASCII characters.
bool isNotPureAscii(String str) {
  return str.codeUnits.any((unit) => unit > 127);
}

/// Removes all non-ASCII characters from [str].
String stripNonAscii(String str) {
  return String.fromCharCodes(str.codeUnits.where((unit) => unit <= 127));
}
