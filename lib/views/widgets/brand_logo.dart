import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The two interlocking rings + "CDS TEAM / CLOUD DATA SOLUTIONS" lockup.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.scale = 1, this.onDark = false});

  final double scale;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _CloudMark(scale: scale, onDark: onDark),
        SizedBox(width: 8 * scale),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'CDS TEAM',
              style: TextStyle(
                fontSize: 12 * scale,
                letterSpacing: 1.6 * scale,
                height: 1.05,
                fontWeight: FontWeight.w800,
                color: onDark ? Colors.white : AppColors.ink,
              ),
            ),
            SizedBox(height: 3 * scale),
            Text(
              'CLOUD DATA SOLUTIONS',
              style: TextStyle(
                fontSize: 6.5 * scale,
                letterSpacing: 1 * scale,
                fontWeight: FontWeight.w700,
                color: onDark ? Colors.white70 : const Color(0xFF77807E),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CloudMark extends StatelessWidget {
  const _CloudMark({required this.scale, required this.onDark});

  final double scale;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28 * scale,
      height: 25 * scale,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            top: 3 * scale,
            child: _Ring(scale: scale, color: AppColors.green),
          ),
          Positioned(
            right: 0,
            top: 3 * scale,
            child: _Ring(
              scale: scale,
              color: onDark ? Colors.white : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.scale, required this.color});

  final double scale;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.61, // -35deg
      child: Container(
        width: 19 * scale,
        height: 19 * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 4.4 * scale),
        ),
      ),
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
