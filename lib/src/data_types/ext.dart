/// This file relies on './enum_auto.dart', when the script to generate this
/// file breaks, functions in this file may stop working.
library;

import '../type.dart';

import './enum_auto.dart';

/// a comma-delimited list of members of the Award enumeration
class AdifAwardList extends AdifGeneral<List<String>> {
  @override
  String getType() => 'AwardList';
  @override
  String getString() => value.join(',');

  AdifAwardList(super.value) {
    value.map((e) {
      if (!listAwardEnumeration.contains(e)) {
        throw ArgumentError('Invalid Award value: $e');
      }
    });
  }

  static AdifAwardList fromString(String str) {
    final parts = str.split(',').map((e) => e.trim()).toList();
    return AdifAwardList(parts);
  }
}

/// a comma-delimited list where each list item is either:
/// A member of the Credit enumeration.
/// A member of the Credit enumeration followed by a colon and an
/// ampersand-delimited list of members of the QSL_Medium enumeration.
/// For example IOTA,WAS:LOTW&CARD,DXCC:CARD
class AdifCreditList extends AdifGeneral<List<String>> {
  @override
  String getType() => 'CreditList';
  @override
  String getString() => value.join(',');

  AdifCreditList(super.value) {
    value.map((e) {
      final parts = e.split(':');
      if (parts.isEmpty || parts.length > 2) {
        throw ArgumentError('Invalid Credit value: $e');
      }
      if (!listCreditEnumeration.contains(parts[0].trim())) {
        throw ArgumentError('Invalid Credit value: $e');
      }
      if (parts.length == 2) {
        final qslParts = parts[1].split('&').map((e) => e.trim()).toList();
        for (final qsl in qslParts) {
          if (!listQslMediumEnumeration.contains(qsl)) {
            throw ArgumentError('Invalid Credit value: $e');
          }
        }
      }
    });
  }

  static AdifCreditList fromString(String str) {
    final parts = str.split(',').map((e) => e.trim()).toList();
    return AdifCreditList(parts);
  }
}

/// IOTA designator, in format CC-XXX, where
/// CC is a member of the Continent enumeration
/// XXX is the island group designator, where 1 <= XXX <= 999  (use leading zeroes)
class AdifIOTARefNo extends AdifGeneral<String> {
  @override
  String getType() => 'IOTARefNo';
  @override
  String getString() => value;

  AdifIOTARefNo(super.value) {
    final parts = value.split('-');
    if (parts.length != 2) {
      throw ArgumentError('Invalid IOTA_Ref_No value: $value');
    }
    if (!listContinentEnumeration.contains(parts[0].trim())) {
      throw ArgumentError('Invalid IOTA_Ref_No value: $value');
    }
    final islandGroup = int.tryParse(parts[1]);
    if (islandGroup == null || islandGroup < 1 || islandGroup > 999) {
      throw ArgumentError('Invalid IOTA_Ref_No value: $value');
    }
  }

  static AdifIOTARefNo fromString(String str) {
    return AdifIOTARefNo(str);
  }
}

/// 	a colon-delimited list of two or more members of the
/// Secondary_Administrative_Subdivision enumeration.  E.g.:
/// MA,Franklin:MA,Hampshire
///
/// Attention: Now the validation of
/// SecondaryAdministrativeSubdivisionEnumeration is not implemented.
class AdifSecondarySubdivisionList extends AdifGeneral<List<String>> {
  @override
  String getType() => 'SecondarySubdivisionList';
  @override
  String getString() => value.join(':');

  AdifSecondarySubdivisionList(super.value) {
    if (value.length < 2) {
      throw ArgumentError('Invalid Secondary_Subdivision_List value: $value');
    }
  }

  static AdifSecondarySubdivisionList fromString(String str) {
    final parts = str.split(':').map((e) => e.trim()).toList();
    return AdifSecondarySubdivisionList(parts);
  }
}
