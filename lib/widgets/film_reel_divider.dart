import 'package:flutter/material.dart';

class FilmReelDivider extends StatelessWidget {
  final double height;

  const FilmReelDivider({
    super.key,
    this.height = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xFF090910),
        border: Border.symmetric(
          horizontal: BorderSide(color: Color(0xFF262638), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {

          final holeCount = (constraints.maxWidth / 18).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              holeCount,
              (index) => Container(
                width: 8,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF202030),
                  borderRadius: BorderRadius.circular(1.5),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.8), width: 0.5),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
