import 'package:flutter/material.dart';
import 'package:flutterapptemp/src/app/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class BranchChip extends StatelessWidget {
  const BranchChip({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 3, 9, 3),
      decoration: BoxDecoration(
        color: c.surface3,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '⎇ ',
            style: GoogleFonts.ibmPlexMono(fontSize: 9.5, color: c.ink4),
          ),
          Text(
            name,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11.5,
              color: c.ink2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
