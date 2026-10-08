import 'package:flutter/material.dart';

/// The Cloud Data Solutions logo (`assets/brand/cds_logo.png`).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.scale = 1});

  final double scale;

  /// Height at `scale == 1`; width follows from the asset's own aspect ratio.
  static const double _baseHeight = 36;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/cds_logo.png',
      height: _baseHeight * scale,
      fit: BoxFit.contain,
    );
  }
}

/// Square-ish gradient avatar with the user's initials.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.initials, this.size = 38});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.37),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF34525A), Color(0xFF8DB2A4)],
        ),
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.29,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
