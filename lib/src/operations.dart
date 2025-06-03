import 'package:xml/xml.dart';
import 'package:intl/intl.dart';
import './data.dart';

extension AdifOperations on Adif {
  String buildAdxString() {
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
            for (var i = 0; i < userdef.length; i++) {
              b.element('USERDEF${i + 1}', nest: userdef[i]);
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
                    b.element(
                      adifField.fieldName,
                      nest: adifField.getString(),
                    );
                  }
                  // Application-defined fields.
                  for (var appField in qso.appdefs) {
                    b.element(
                      'APP',
                      attributes: {
                        'PROGRAMID': programid ?? '',
                        'FIELDNAME': appField.fieldname,
                        'TYPE': appField.value.getType(),
                      },
                      nest: appField.value.getString(),
                    );
                  }

                  // TODO: User-defined fields.
                },
              );
            }
          },
        );
      },
    );

    return b.buildDocument().toXmlString(
      pretty: true,
      indent: '  '
    );
  }
}
