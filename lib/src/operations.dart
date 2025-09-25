import 'package:adif/adif.dart';
import 'package:xml/xml.dart';
import 'package:intl/intl.dart';

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
}
