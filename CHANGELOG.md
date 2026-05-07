

## 315.2.0

**Breaking updates from `v315.1.1`**:
- The constructor of `Adif()` has BROKEN after the field `userdef` of it has been proved to be useless. You have to update the constructor of it after updated.

## 315.1.0

**Breaking updates from `v315.0.1`**:
- Modes have been **no longer** considered as strings. Instead they must be one of [the modes enumeration](https://www.adif.org/315/ADIF_315.htm#Mode_Enumeration) or [the submodes enumeration](https://www.adif.org/315/ADIF_315.htm#Submode_Enumeration). Attempts to set a mode as one not among them will fail.
- Bands have been **no longer** considered as strings. Instead thay must be one of [the bands enumeration](https://www.adif.org/315/ADIF_315.htm#Band_Enumeration).

## 315.0.1

Fixes:
- Downgraded dependences for better compatibility.

## 315.0.0

Initial version:
- Export to ADX.
- Most ADIF-defined fields (except enums).
