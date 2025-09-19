import 'package:adif/src/data_types/basics.dart';
import 'package:xml/xml.dart';
import 'package:intl/intl.dart';
import './data.dart';

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
}
