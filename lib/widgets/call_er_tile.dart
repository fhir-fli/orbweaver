import 'package:flutter/material.dart';
import 'package:orbweaver/theme/topic_theme.dart';

/// The print's "Call ER" tile: a white card with a heavy black outline holding
/// the word **Call**, a bright-green square with a white telephone glyph, and
/// bold red **ER**.
///
/// It is a recurring visual verb — "phone the receiving ED and pre-alert" —
/// and it always sits immediately right of a dashed box whose last bullet
/// reads `Call a <X> Alert`. Measured on exactly 12 pages (29, 45, 53, 55, 57,
/// 59, 63, 65, 67, 71, 89, 95) with the green square identical on every one
/// (49 x 49 px at 150 dpi), i.e. a fixed reusable asset (audit §4.1).
///
/// Drawn rather than shipped as a raster, for the reason the audit gives: the
/// geometry is fixed, it recurs on twelve pages, and the only thing that varies
/// is the one word in the sentence beside it. It also means it scales with the
/// paged fit-scaler instead of going soft.
///
/// Without it the app's alert box loses most of its weight: the print's box is
/// a plain dashed outline with no fill, and this tile is what makes the pairing
/// read as "act now".
class CallErTile extends StatelessWidget {
  const CallErTile({this.size = 26, super.key});

  /// Side of the green square. The card sizes itself from this.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = TopicThemeScope.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.30,
        vertical: size * 0.18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: theme.boxBorder, width: 2),
        borderRadius: BorderRadius.circular(size * 0.42),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Call',
            style: TextStyle(
              fontSize: size * 0.62,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.05,
            ),
          ),
          SizedBox(height: size * 0.10),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: theme.callErPhone,
              borderRadius: BorderRadius.circular(size * 0.22),
            ),
            child: Icon(Icons.phone, size: size * 0.72, color: Colors.white),
          ),
          SizedBox(height: size * 0.06),
          Text(
            'ER',
            style: TextStyle(
              fontSize: size * 0.62,
              fontWeight: FontWeight.w900,
              color: theme.callErText,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}
