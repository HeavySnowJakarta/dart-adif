import 'dart:convert';

import 'package:adif/adif.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

import './basic.dart';
import './helpers/intl.dart';

/// Options for handling international fields when generating ADI texts.
///
/// - [throwError]: Refuses to generate texts if international fields are
/// found.
/// - [removeCharacters]: Remove non-ASCII characters directly from the
/// strings and try to transfer them to their non-international versions. If
/// the process fails, throw an exception.
/// - [removeFields]: Ignore all international fields.
enum NonAsciiBuildOption { throwError, removeCharacters, removeFields }

/// Options when meeting non-ASCII characters (multiple bytes) when parsing
/// texts.
///
/// - [throwError]: Refuses to parse ADI texts if non-ASCII characters are
/// found.
/// - [parseByCharacter]: Regard each non-ASCII character as a single
/// character for ADI.
/// - [parseByByte]: Regard each byte as a single character for ADI.
///
/// When fallbacking, the string fields will try to be transfered to their
/// international fields version as dart-adif is type safe. If the
/// international fields don't exist, exceptions still occur. For ADX,
/// there's no difference between [parseByCharacter] and [parseByByte] as it
/// does not concern the string length.
enum NonAsciiParseOption { throwError, parseByCharacter, parseByByte }

/// The literal prefix used by ADI application-defined field names.
const _adiAppPrefix = 'APP_';

/// Matches a regular ADI field token in the form `NAME:length[:type]`.
final _adiFieldPattern = RegExp(r'^([^:>]+):(\d+)(?::([^>]+))?$');

/// Matches numbered ADI user-defined field references such as `USERDEF3`.
final _adiUserdefPattern = RegExp(r'^USERDEF(\d+)$');

/// A scanned ADI token together with the parser cursor position after it.
///
/// This acts as the output of the ADI lexical scanner. It represents either a
/// control marker such as `<EOH>` / `<EOR>`, or a regular data field with an
/// optional type and value.
class _AdiFieldToken {
  /// The field or control token name exactly as scanned from the ADI text.
  final String fieldName;

  /// The optional ADI type token following the second colon.
  final String? type;

  /// The parsed ADI field value.
  ///
  /// This is `null` for control tokens such as `<EOH>` and `<EOR>`.
  final String? value;

  /// Whether this token is a control marker instead of a regular data field.
  final bool isControl;

  /// The input index immediately after this token and its value.
  final int nextIndex;

  /// Creates a control token for `<EOH>` or `<EOR>`.
  const _AdiFieldToken.control(this.fieldName, this.nextIndex)
    : type = null,
      value = null,
      isControl = true;

  /// Creates a regular ADI field token with its parsed value.
  const _AdiFieldToken.data(
    this.fieldName,
    this.value,
    this.nextIndex, {
    this.type,
  }) : isControl = false;
}

/// Returns whether [fieldName] points to an ADIF `_INTL` field.
bool _isIntlFieldName(String fieldName) {
  return fieldName.toUpperCase().endsWith('_INTL');
}

/// Converts an `_INTL` field name to its non-international counterpart.
///
/// If [fieldName] is not an `_INTL` field, the upper-cased original name is
/// returned unchanged.
String _toNonIntlFieldName(String fieldName) {
  final upperFieldName = fieldName.toUpperCase();
  if (!upperFieldName.endsWith('_INTL')) {
    return upperFieldName;
  }
  return upperFieldName.substring(0, upperFieldName.length - 5);
}

/// Compares two optional string lists by value and order.
bool _stringListsEqual(List<String>? left, List<String>? right) {
  if (identical(left, right)) {
    return true;
  }
  if (left == null || right == null || left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}

/// Returns whether two [UserdefMeta] instances describe the same field.
bool _sameUserdefMeta(UserdefMeta left, UserdefMeta right) {
  return left.name == right.name &&
      left.type == right.type &&
      _stringListsEqual(left.enums, right.enums) &&
      left.range == right.range;
}

/// Collects user-defined metadata from all QSOs and validates consistency.
///
/// ADI header declarations are global to the whole file, so repeated
/// user-defined fields must agree on type, enumerations, and range.
List<UserdefMeta> _getValidatedUserdefMetaList(List<Qso> data) {
  final result = <UserdefMeta>[];

  for (final qso in data) {
    for (final userDefinedField in qso.userdefs) {
      final nextMeta = UserdefMeta(
        userDefinedField.fieldName,
        userDefinedField.value.getType(),
        enums:
            userDefinedField.value is AdifEnumeration
                ? (userDefinedField.value as AdifEnumeration).enumerations
                : null,
        range:
            userDefinedField.value is AdifRange
                ? (userDefinedField.value as AdifRange).range
                : null,
      );

      final existing = result.getByName(userDefinedField.fieldName);
      if (existing == null) {
        result.add(nextMeta);
        continue;
      }

      if (!_sameUserdefMeta(existing, nextMeta)) {
        throw ArgumentError(
          'Conflicting USERDEF metadata for ${userDefinedField.fieldName}',
        );
      }
    }
  }

  return result;
}

/// Formats a single ADI field in the form `<NAME:length[:type]>value`.
String _formatAdiField(String fieldName, String value, {String? type}) {
  final typeSuffix = type == null ? '' : ':$type';
  return '<$fieldName:${value.length}$typeSuffix>$value';
}

/// Formats a UTC timestamp using the canonical ADI header representation.
String _formatAdiTimestamp(DateTime timestamp) {
  return DateFormat('yyyyMMdd HHmmss').format(timestamp.toUtc());
}

/// Parses a canonical ADI `CREATED_TIMESTAMP` value.
DateTime _parseAdiTimestamp(String value) {
  if (value.length != 15 || value[8] != ' ') {
    throw FormatException('Invalid CREATED_TIMESTAMP: $value');
  }
  return DateTime.utc(
    int.parse(value.substring(0, 4)),
    int.parse(value.substring(4, 6)),
    int.parse(value.substring(6, 8)),
    int.parse(value.substring(9, 11)),
    int.parse(value.substring(11, 13)),
    int.parse(value.substring(13, 15)),
  );
}

/// Builds the ADI payload for a `USERDEFn` header declaration.
String _formatUserdefPayload(UserdefMeta meta) {
  if (meta.enums != null) {
    return '${meta.name},{${meta.enums!.join(',')}}';
  }
  if (meta.range != null) {
    return '${meta.name},{${meta.range!.$1}:${meta.range!.$2}}';
  }
  return meta.name;
}

/// Parses a `USERDEFn` payload into its name, enum list, and numeric range.
({String name, List<String>? enums, (double min, double max)? range})
_parseUserdefPayload(String payload) {
  final metadataSeparator = payload.lastIndexOf(',{');
  if (metadataSeparator == -1 || !payload.endsWith('}')) {
    return (name: payload, enums: null, range: null);
  }

  final name = payload.substring(0, metadataSeparator);
  final metadata = payload.substring(metadataSeparator + 1);
  final isRange = metadata.contains(':') && !metadata.contains(',');
  final (enums, range) = AdifOperations.parseEnumsAndRanges(
    isRange ? null : metadata,
    isRange ? metadata : null,
  );
  return (name: name, enums: enums, range: range);
}

/// Validates one literal component of an ADI `APP_{PROGRAMID}_{FIELDNAME}` name.
void _validateAppNameComponent(
  String value, {
  required String label,
  required bool allowUnderscore,
}) {
  if (value.isEmpty) {
    throw ArgumentError('$label must not be empty');
  }
  if (isNotPureAscii(value)) {
    throw ArgumentError('$label must be ASCII only for ADI');
  }
  if (value.endsWith(' ')) {
    throw ArgumentError('$label must not end with a space');
  }
  const invalidCharacters = ',:<>{}';
  for (final character in invalidCharacters.split('')) {
    if (value.contains(character)) {
      throw ArgumentError('$label must not contain "$character"');
    }
  }
  if (!allowUnderscore && value.contains('_')) {
    throw ArgumentError('$label must not contain "_" in ADI APP wire names');
  }
}

/// Returns the ASCII-safe fallback type for an international custom type.
String? _asciiFallbackType(String type) {
  switch (type.toLowerCase()) {
    case 'intlcharacter':
      return 'Character';
    case 'i':
    case 'intlstring':
      return 'S';
    case 'g':
    case 'intlmultilinestring':
      return 'M';
  }
  return null;
}

/// Returns the international fallback type for an ASCII custom type.
String? _intlFallbackType(String type) {
  switch (type.toLowerCase()) {
    case 'character':
      return 'IntlCharacter';
    case 's':
    case 'string':
      return 'I';
    case 'm':
    case 'multilinestring':
      return 'G';
  }
  return null;
}

/// Prepares a custom field value for ADI output according to fallback rules.
///
/// This is used by APP and USERDEF fields, which may need type downgrading
/// when the source value is an international ADIF type.
({String type, String value})? _prepareCustomFieldForAdi(
  AdifGeneral value,
  NonAsciiBuildOption nonAsciiFallback,
) {
  final originalType = value.getType();
  final originalValue = value.getString();
  final needsFallback = value.isIntl() || isNotPureAscii(originalValue);

  if (!needsFallback) {
    return (type: originalType, value: originalValue);
  }

  switch (nonAsciiFallback) {
    case NonAsciiBuildOption.throwError:
      throw ArgumentError(
        'Cannot emit non-ASCII or international custom value into ADI',
      );
    case NonAsciiBuildOption.removeFields:
      if (value.isIntl()) {
        return null;
      }
      throw ArgumentError('Non-ASCII custom value cannot be emitted into ADI');
    case NonAsciiBuildOption.removeCharacters:
      final fallbackType =
          value.isIntl() ? _asciiFallbackType(originalType) : originalType;
      if (fallbackType == null) {
        throw ArgumentError(
          'Cannot downgrade custom type $originalType into ASCII-safe ADI',
        );
      }
      final strippedValue = stripNonAscii(originalValue);
      final enums =
          value is AdifEnumeration ? value.enumerations.cast<String>() : null;
      final range = value is AdifRange ? value.range : null;
      createAdifContentFromString(strippedValue, fallbackType, enums, range);
      return (type: fallbackType, value: strippedValue);
  }
}

/// Prepares an ADIF-defined field for ADI output according to fallback rules.
({String fieldName, String value})? _prepareAdifFieldForAdi(
  AdifField field,
  NonAsciiBuildOption nonAsciiFallback,
) {
  final originalFieldName = field.fieldName.toUpperCase();
  final originalValue = field.getString();
  final isIntlField = _isIntlFieldName(originalFieldName);
  final hasNonAscii = isNotPureAscii(originalValue);

  if (!isIntlField && !hasNonAscii) {
    return (fieldName: originalFieldName, value: originalValue);
  }

  switch (nonAsciiFallback) {
    case NonAsciiBuildOption.throwError:
      throw ArgumentError('Cannot emit $originalFieldName into ADI safely');
    case NonAsciiBuildOption.removeFields:
      if (isIntlField) {
        return null;
      }
      throw ArgumentError(
        'Non-ASCII ADIF-defined value cannot be emitted into ADI',
      );
    case NonAsciiBuildOption.removeCharacters:
      final fallbackFieldName =
          isIntlField
              ? _toNonIntlFieldName(originalFieldName)
              : originalFieldName;
      final strippedValue = stripNonAscii(originalValue);
      adifFieldFactory(fallbackFieldName, strippedValue);
      return (fieldName: fallbackFieldName, value: strippedValue);
  }
}

/// Builds a custom ADIF value while parsing ADI APP/USERDEF fields.
///
/// When non-ASCII parsing is allowed, this attempts to upgrade ASCII string
/// types to their international counterparts if the plain parse fails.
AdifGeneral _createCustomValueForAdiParse(
  String value,
  String type, {
  List<String>? enums,
  (double min, double max)? range,
  required NonAsciiParseOption nonAsciiParse,
}) {
  if (nonAsciiParse == NonAsciiParseOption.throwError &&
      isNotPureAscii(value)) {
    throw ArgumentError('Non-ASCII custom value is not allowed in strict mode');
  }

  try {
    return createAdifContentFromString(value, type, enums, range);
  } catch (_) {
    if (!isNotPureAscii(value) ||
        nonAsciiParse == NonAsciiParseOption.throwError) {
      rethrow;
    }

    final fallbackType = _intlFallbackType(type);
    if (fallbackType == null) {
      rethrow;
    }
    return createAdifContentFromString(value, fallbackType, enums, range);
  }
}

/// Builds an ADIF-defined field while parsing ADI record data.
///
/// When non-ASCII parsing is allowed, plain string-like fields may be retried
/// as their `_INTL` variants to preserve the original content.
AdifField _createAdifFieldForAdiParse(
  String fieldName,
  String value,
  NonAsciiParseOption nonAsciiParse,
) {
  final normalizedFieldName = fieldName.toUpperCase();
  if (nonAsciiParse == NonAsciiParseOption.throwError &&
      isNotPureAscii(value)) {
    throw ArgumentError('Non-ASCII field value is not allowed in strict mode');
  }

  try {
    return adifFieldFactory(normalizedFieldName, value);
  } catch (_) {
    if (!isNotPureAscii(value) ||
        nonAsciiParse == NonAsciiParseOption.throwError ||
        _isIntlFieldName(normalizedFieldName)) {
      rethrow;
    }

    return adifFieldFactory('${normalizedFieldName}_INTL', value);
  }
}

/// Reads the Unicode rune that starts at [index].
///
/// This handles UTF-16 surrogate pairs so that character-count parsing can
/// walk ADI values by Unicode scalar value instead of raw code units.
int _readRuneAt(String input, int index) {
  final first = input.codeUnitAt(index);
  if (first >= 0xD800 && first <= 0xDBFF && index + 1 < input.length) {
    final second = input.codeUnitAt(index + 1);
    if (second >= 0xDC00 && second <= 0xDFFF) {
      return ((first - 0xD800) << 10) + (second - 0xDC00) + 0x10000;
    }
  }
  return first;
}

/// Reads an ADI field value using character-count length semantics.
(String, int) _readAdiValueByCharacter(String input, int start, int length) {
  var currentIndex = start;
  var remaining = length;

  while (remaining > 0 && currentIndex < input.length) {
    final rune = _readRuneAt(input, currentIndex);
    currentIndex += rune > 0xFFFF ? 2 : 1;
    remaining--;
  }

  if (remaining != 0) {
    throw FormatException('ADI field value is shorter than declared length');
  }

  return (input.substring(start, currentIndex), currentIndex);
}

/// Reads an ADI field value using UTF-8 byte-count length semantics.
(String, int) _readAdiValueByByte(String input, int start, int length) {
  var currentIndex = start;
  var remainingBytes = length;

  while (remainingBytes > 0 && currentIndex < input.length) {
    final rune = _readRuneAt(input, currentIndex);
    final runeString = String.fromCharCode(rune);
    final runeBytes = utf8.encode(runeString).length;
    if (runeBytes > remainingBytes) {
      throw FormatException('ADI field byte length cuts through a UTF-8 rune');
    }
    remainingBytes -= runeBytes;
    currentIndex += rune > 0xFFFF ? 2 : 1;
  }

  if (remainingBytes != 0) {
    throw FormatException(
      'ADI field value is shorter than declared byte length',
    );
  }

  return (input.substring(start, currentIndex), currentIndex);
}

/// Scans the next ADI token from [input] starting at [start].
///
/// The scanner skips malformed tokens when [ignoreIllegals] is true. Returned
/// values include the cursor position immediately after the token so the parser
/// can continue scanning without recomputing offsets.
_AdiFieldToken? _readNextAdiField(
  String input,
  int start, {
  required bool ignoreIllegals,
  required NonAsciiParseOption nonAsciiParse,
}) {
  var cursor = start;

  while (true) {
    final openIndex = input.indexOf('<', cursor);
    if (openIndex == -1) {
      return null;
    }

    final closeIndex = input.indexOf('>', openIndex + 1);
    if (closeIndex == -1) {
      if (ignoreIllegals) {
        return null;
      }
      throw FormatException('Unterminated ADI field token');
    }

    final token = input.substring(openIndex + 1, closeIndex).trim();
    if (token.isEmpty) {
      if (ignoreIllegals) {
        cursor = closeIndex + 1;
        continue;
      }
      throw FormatException('Empty ADI field token');
    }

    final upperToken = token.toUpperCase();
    if (upperToken == 'EOH' || upperToken == 'EOR') {
      return _AdiFieldToken.control(upperToken, closeIndex + 1);
    }

    final match = _adiFieldPattern.firstMatch(token);
    if (match == null) {
      if (ignoreIllegals) {
        cursor = closeIndex + 1;
        continue;
      }
      throw FormatException('Malformed ADI field token <$token>');
    }

    final fieldName = match.group(1)!.trim();
    final length = int.parse(match.group(2)!);
    final type = match.group(3)?.trim();

    try {
      final (value, nextIndex) = switch (nonAsciiParse) {
        NonAsciiParseOption.parseByByte => _readAdiValueByByte(
          input,
          closeIndex + 1,
          length,
        ),
        _ => _readAdiValueByCharacter(input, closeIndex + 1, length),
      };

      return _AdiFieldToken.data(fieldName, value, nextIndex, type: type);
    } catch (_) {
      if (ignoreIllegals) {
        cursor = closeIndex + 1;
        continue;
      }
      rethrow;
    }
  }
}

/// Splits a literal ADI application-defined field name into its two components.
///
/// The parser expects the exact wire form `APP_{PROGRAMID}_{FIELDNAME}` and
/// splits on the first underscore after the `APP_` prefix.
(String programId, String fieldName) _parseAppWireFieldName(String fieldName) {
  if (!fieldName.toUpperCase().startsWith(_adiAppPrefix)) {
    throw FormatException('Not an APP wire field: $fieldName');
  }

  final suffix = fieldName.substring(_adiAppPrefix.length);
  final separatorIndex = suffix.indexOf('_');
  if (separatorIndex <= 0 || separatorIndex == suffix.length - 1) {
    throw FormatException('Malformed APP wire field: $fieldName');
  }

  return (
    suffix.substring(0, separatorIndex),
    suffix.substring(separatorIndex + 1),
  );
}

extension AdifOperations on Adif {
  /// Build the list of &lt;USERDEF&gt; from the given QSOs.
  static List<UserdefMeta> getUserdefMetaList(List<Qso> data) {
    List<UserdefMeta> result = [];
    for (var qso in data) {
      for (var userDefinedField in qso.userdefs) {
        // Add to the list if not exists.
        if (result.getByName(userDefinedField.fieldName) == null) {
          // Get the enums.
          final List<String>? enums =
              userDefinedField.value.getType() == 'E'
                  ? (userDefinedField.value as AdifEnumeration).enumerations
                  : null;
          // Get the range.
          final (double min, double max)? range =
              userDefinedField.value is AdifRange
                  ? (userDefinedField.value as AdifRange).range
                  : null;
          result.add(
            UserdefMeta(
              userDefinedField.fieldName,
              userDefinedField.value.getType(),
              enums: enums,
              range: range,
            ),
          );
        }
      }
    }
    return result;
  }

  /// Parse optional lists of enums and double ranges from the given strings.
  static (List<String>?, (double min, double max)?) parseEnumsAndRanges(
    String? enumsStr,
    String? rangeStr,
  ) {
    // Parse enums.
    List<String>? enums;
    if (enumsStr != null) {
      enums =
          enumsStr
              .substring(1, enumsStr.length - 1)
              .split(',')
              .map((e) => e.trim())
              .toList();
    }

    // Parse range.
    (double min, double max)? range;
    if (rangeStr != null) {
      final rangeParts =
          rangeStr
              .substring(1, rangeStr.length - 1)
              .split(':')
              .map((e) => double.parse(e.trim()))
              .toList();
      if (rangeParts.length == 2) {
        range = (rangeParts[0], rangeParts[1]);
      }
    }

    return (enums, range);
  }

  /// Build the ADI string.
  String buildAdiString({
    NonAsciiBuildOption nonAsciiFallback = NonAsciiBuildOption.throwError,
  }) {
    final userdefs = _getValidatedUserdefMetaList(data);
    final userdefIds = <String, int>{
      for (var i = 0; i < userdefs.length; i++) userdefs[i].name: i + 1,
    };
    final lines = <String>[];

    lines.add(_formatAdiField('ADIF_VER', adifVer));
    if (createdTimestamp != null) {
      lines.add(
        _formatAdiField(
          'CREATED_TIMESTAMP',
          _formatAdiTimestamp(createdTimestamp!),
        ),
      );
    }
    if (programid != null) {
      lines.add(_formatAdiField('PROGRAMID', programid!));
    }
    if (programversion != null) {
      lines.add(_formatAdiField('PROGRAMVERSION', programversion!));
    }

    for (var i = 0; i < userdefs.length; i++) {
      final userdef = userdefs[i];
      final payload = _formatUserdefPayload(userdef);
      lines.add(
        _formatAdiField('USERDEF${i + 1}', payload, type: userdef.type),
      );
    }

    lines.add('<EOH>');

    for (final qso in data) {
      for (final adifField in qso.adifdefs) {
        final prepared = _prepareAdifFieldForAdi(adifField, nonAsciiFallback);
        if (prepared == null) {
          continue;
        }
        lines.add(_formatAdiField(prepared.fieldName, prepared.value));
      }

      for (final appField in qso.appdefs) {
        if (appField.value is AdifEnumeration || appField.value is AdifRange) {
          throw ArgumentError(
            'APP field ${appField.fieldName} requires auxiliary metadata that ADI does not carry',
          );
        }

        _validateAppNameComponent(
          appField.programid,
          label: 'APP programid',
          allowUnderscore: false,
        );
        _validateAppNameComponent(
          appField.fieldName,
          label: 'APP field name',
          allowUnderscore: true,
        );

        final prepared = _prepareCustomFieldForAdi(
          appField.value,
          nonAsciiFallback,
        );
        if (prepared == null) {
          continue;
        }

        lines.add(
          _formatAdiField(
            '$_adiAppPrefix${appField.programid}_${appField.fieldName}',
            prepared.value,
            type: prepared.type,
          ),
        );
      }

      for (final userField in qso.userdefs) {
        final fieldId =
            userdefIds[userField.fieldName] ??
            (throw ArgumentError(
              'USERDEF metadata missing for ${userField.fieldName}',
            ));
        final prepared = _prepareCustomFieldForAdi(
          userField.value,
          nonAsciiFallback,
        );
        if (prepared == null) {
          continue;
        }

        lines.add(
          _formatAdiField(
            'USERDEF$fieldId',
            prepared.value,
            type: prepared.type,
          ),
        );
      }

      lines.add('<EOR>');
    }

    return '${lines.join('\n')}\n';
  }

  /// Build the ADX string.
  String buildAdxString() {
    // Build the list of <USERDEF>.
    List<UserdefMeta> userdefs = getUserdefMetaList(data);

    // Build the XML document.
    final b = XmlBuilder();
    b.processing('xml', 'version="1.0" encoding="UTF-8"');
    b.element(
      'ADX',
      nest: () {
        // HEADER
        b.element(
          'HEADER',
          nest: () {
            b.element('ADIF_VER', nest: adifVer);
            // CREATED_TIMESTAMP
            if (createdTimestamp != null) {
              b.element(
                'CREATED_TIMESTAMP',
                nest: DateFormat('yyyyMMdd hhmmss').format(createdTimestamp!),
              );
            }

            // PROGRAMID
            if (programid != null) {
              b.element('PROGRAMID', nest: programid!);
            }
            // PROGRAMVERSION
            if (programversion != null) {
              b.element('PROGRAMVERSION', nest: programversion!);
            }

            // USERDEF
            for (var i = 0; i < userdefs.length; i++) {
              b.element(
                'USERDEF',
                attributes: {
                  'FIELDID': (i + 1).toString(),
                  'TYPE': userdefs[i].type,
                  if (userdefs[i].enums != null)
                    'ENUMS': '{${userdefs[i].enums!.join(',')}}',
                  if (userdefs[i].range != null)
                    'RANGE':
                        '{${userdefs[i].range!.$1}:${userdefs[i].range!.$2}}',
                },
                nest: userdefs[i].name,
              );
            }
          },
        );

        // RECORDS
        b.element(
          'RECORDS',
          nest: () {
            for (var qso in data) {
              b.element(
                'RECORD',
                nest: () {
                  // ADIF-defined fields.
                  for (var adifField in qso.adifdefs) {
                    b.element(adifField.fieldName, nest: adifField.getString());
                  }

                  // Application-defined fields.
                  for (var appField in qso.appdefs) {
                    b.element(
                      'APP',
                      attributes: {
                        'PROGRAMID': programid ?? '',
                        'FIELDNAME': appField.fieldName,
                        'TYPE': appField.value.getType(),
                      },
                      nest: appField.value.getString(),
                    );
                  }

                  // User-defined fields.
                  for (var userField in qso.userdefs) {
                    b.element(
                      'USERDEF',
                      attributes: {'FIELDNAME': userField.fieldName},
                      nest: userField.value.getString(),
                    );
                  }
                },
              );
            }
          },
        );
      },
    );

    return b.buildDocument().toXmlString(pretty: true, indent: '  ');
  }

  /// Parse from ADX strings.
  /// - @param str The ADX string to be parsed
  /// - @param ignoreIllegals Whether to ignore illegal data. When this
  ///   argument is set to true, the method ignores all illegal fields (they
  ///   won't be parsed anyway), otherwise it throws an exception.
  ///
  /// Set `ignoreIllegals` to true does not mean it never throws an exception.
  /// When the ADX string is broken severely (eg. even not a valid XML string),
  /// exceptions may occur.
  static Adif parseAdxString(String str, {bool ignoreIllegals = true}) {
    final document = XmlDocument.parse(str);
    final XmlElement adx =
        document.getElement('ADX') ?? (throw Exception("Not a valid ADX file"));

    // Parse the header.
    final header = adx.getElement('HEADER');
    final adifVer = header?.getElement('ADIF_VER');
    final programId = header?.getElement('PROGRAMID');
    final programVersion = header?.getElement('PROGRAMVERSION');
    final userdefIterables = header?.findAllElements('USERDEF') ?? [];
    final userdefMetas = userdefIterables.map((e) {
      // final fieldId = int.parse(e.getAttribute('FIELDID') ?? '0');
      final fieldName = e.innerText;
      final type = e.getAttribute('TYPE') ?? 'S';
      final enumsStr = e.getAttribute('ENUM');
      final enums =
          enumsStr
              ?.substring(1, enumsStr.length - 1)
              .split(',')
              .map((e) => e.trim())
              .toList();
      final rangeStr = e.getAttribute('RANGE');
      final range =
          rangeStr
              ?.substring(1, rangeStr.length - 1)
              .split(':')
              .map((e) => double.parse(e.trim()))
              .toList();
      try {
        return UserdefMeta(
          fieldName,
          type,
          enums: enums,
          range:
              range != null && range.length == 2 ? (range[0], range[1]) : null,
        );
      } catch (e) {
        if (ignoreIllegals) {
          return null;
        } else {
          rethrow;
        }
      }
    });

    // Parse the records.
    final records = adx.getElement('RECORDS');
    final qsos =
        records?.findElements('RECORD').map((record) {
          final fields = record.children.whereType<XmlElement>().map((field) {
            final fieldName = field.name.local;

            // App-defined fields.
            if (fieldName == 'APP') {
              final programId = field.getAttribute('PROGRAMID');
              final customFieldName = field.getAttribute('FIELDNAME');
              final type = field.getAttribute('TYPE');
              final value = field.innerText;
              final (enums, range) = parseEnumsAndRanges(
                field.getAttribute('ENUMS'),
                field.getAttribute('RANGE'),
              );
              try {
                return Appdef.generate(
                  programId ?? 'unknown',
                  customFieldName ??
                      (throw Exception("APP-defined field without FIELDNAME")),
                  type ?? 'S',
                  value,
                  enums: enums,
                  range: range,
                );
              } catch (e) {
                if (ignoreIllegals) {
                  return null;
                } else {
                  rethrow;
                }
              }
            }

            // User-defined fields.
            if (fieldName == 'USERDEF') {
              final customFieldName = field.getAttribute('FIELDNAME');
              final value = field.innerText;
              try {
                // Get the metadata.
                final metadata =
                    userdefMetas.firstWhere(
                      (userdefMeta) => userdefMeta?.name == customFieldName,
                    ) ??
                    (throw Exception("USERDEF field undefined"));
                return Userdef.generate(
                  customFieldName ??
                      (throw Exception("USERDEF field without FIELDNAME")),
                  metadata.type,
                  value,
                  enums: metadata.enums,
                  range: metadata.range,
                );
              } catch (e) {
                if (ignoreIllegals) {
                  return null;
                } else {
                  rethrow;
                }
              }
            }

            // Any other fields are regarded as ADIF-defined fields.
            final value = field.innerText;
            try {
              return adifFieldFactory(fieldName, value);
            } catch (e) {
              if (ignoreIllegals) {
                return null;
              } else {
                rethrow;
              }
            }
          });
          return Qso(
            fields.whereType<AdifField>().toList(),
            fields.whereType<Appdef>().toList(),
            fields.whereType<Userdef>().toList(),
          );
        }).toList() ??
        [];

    return Adif(
      programId?.innerText ?? 'unknown',
      programVersion?.innerText ?? '',
      qsos,
      adifVer: adifVer?.innerText,
    );
  }

  /// Parse from ADI strings.
  /// - @param str The ADI string to be parsed
  /// - @param ignoreIllegals Whether to ignore illegal data. When this
  ///   argument is set to true, the method skips malformed fields, unexpected
  ///   control markers, and unsupported values whenever it can continue
  ///   scanning. Otherwise it throws an exception immediately.
  /// - @param nonAsciiParse How to interpret ADI field lengths when
  ///   non-ASCII characters are present in texts generated by non-standard
  ///   programs.
  ///
  /// Set `ignoreIllegals` to true does not mean it never throws an exception.
  /// When the ADI string is broken severely (eg. an unterminated token or a
  /// byte-length that cuts through a UTF-8 rune), exceptions may still occur.
  static Adif parseAdiString(
    String str, {
    bool ignoreIllegals = true,
    NonAsciiParseOption nonAsciiParse = NonAsciiParseOption.parseByCharacter,
  }) {
    final userdefMetas = <UserdefMeta>[];
    String adifVer = adifVersion;
    String? programId;
    String? programVersion;
    DateTime? createdTimestamp;
    var cursor = 0;
    var foundHeaderEnd = false;

    while (true) {
      final field = _readNextAdiField(
        str,
        cursor,
        ignoreIllegals: ignoreIllegals,
        nonAsciiParse: nonAsciiParse,
      );

      if (field == null) {
        break;
      }

      cursor = field.nextIndex;

      if (field.isControl) {
        if (field.fieldName == 'EOH') {
          foundHeaderEnd = true;
          break;
        }
        if (!ignoreIllegals) {
          throw FormatException('Unexpected ${field.fieldName} before <EOH>');
        }
        continue;
      }

      final normalizedFieldName = field.fieldName.toUpperCase();
      final value = field.value!;
      try {
        switch (normalizedFieldName) {
          case 'ADIF_VER':
            adifVer = value;
          case 'CREATED_TIMESTAMP':
            createdTimestamp = _parseAdiTimestamp(value);
          case 'PROGRAMID':
            programId = value;
          case 'PROGRAMVERSION':
            programVersion = value;
          default:
            final match = _adiUserdefPattern.firstMatch(normalizedFieldName);
            if (match == null) {
              continue;
            }

            final (:name, :enums, :range) = _parseUserdefPayload(value);
            userdefMetas.add(
              UserdefMeta(name, field.type ?? 'S', enums: enums, range: range),
            );
        }
      } catch (_) {
        if (!ignoreIllegals) {
          rethrow;
        }
      }
    }

    if (!foundHeaderEnd && !ignoreIllegals) {
      throw FormatException('ADI header is missing <EOH>');
    }

    final qsos = <Qso>[];
    final adifFields = <AdifField>[];
    final appFields = <Appdef>[];
    final userFields = <Userdef>[];

    while (true) {
      final field = _readNextAdiField(
        str,
        cursor,
        ignoreIllegals: ignoreIllegals,
        nonAsciiParse: nonAsciiParse,
      );

      if (field == null) {
        if (!ignoreIllegals &&
            (adifFields.isNotEmpty ||
                appFields.isNotEmpty ||
                userFields.isNotEmpty)) {
          throw FormatException('ADI record is missing <EOR>');
        }
        break;
      }

      cursor = field.nextIndex;

      if (field.isControl) {
        if (field.fieldName == 'EOR') {
          qsos.add(
            Qso(
              List<AdifField>.from(adifFields),
              List<Appdef>.from(appFields),
              List<Userdef>.from(userFields),
            ),
          );
          adifFields.clear();
          appFields.clear();
          userFields.clear();
        } else if (!ignoreIllegals) {
          throw FormatException(
            'Unexpected ${field.fieldName} inside a record',
          );
        }
        continue;
      }

      final rawFieldName = field.fieldName;
      final normalizedFieldName = rawFieldName.toUpperCase();
      final value = field.value!;

      try {
        if (normalizedFieldName.startsWith(_adiAppPrefix)) {
          final (embeddedProgramId, appFieldName) = _parseAppWireFieldName(
            rawFieldName,
          );
          final type =
              field.type ??
              (throw FormatException(
                'APP field $rawFieldName is missing explicit type information',
              ));
          final appValue = _createCustomValueForAdiParse(
            value,
            type,
            nonAsciiParse: nonAsciiParse,
          );
          appFields.add(Appdef(embeddedProgramId, appFieldName, appValue));
          continue;
        }

        final userdefMatch = _adiUserdefPattern.firstMatch(normalizedFieldName);
        if (userdefMatch != null) {
          final fieldId = int.parse(userdefMatch.group(1)!);
          final metadata =
              userdefMetas.getByIndex(fieldId) ??
              (throw FormatException('USERDEF$fieldId is undefined in header'));
          final userValue = _createCustomValueForAdiParse(
            value,
            metadata.type,
            enums: metadata.enums,
            range: metadata.range,
            nonAsciiParse: nonAsciiParse,
          );
          userFields.add(Userdef(metadata.name, userValue));
          continue;
        }

        adifFields.add(
          _createAdifFieldForAdiParse(
            normalizedFieldName,
            value,
            nonAsciiParse,
          ),
        );
      } catch (_) {
        if (!ignoreIllegals) {
          rethrow;
        }
      }
    }

    final adif = Adif(
      programId ?? 'unknown',
      programVersion ?? '',
      qsos,
      adifVer: adifVer,
    );
    adif.createdTimestamp = createdTimestamp;
    return adif;
  }
}
