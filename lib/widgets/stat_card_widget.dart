import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'motion.dart';

/// Kartu angka ringkas. Satu aksen (hijau merek) untuk semua kartu agar
/// halaman terbaca sebagai satu sistem, bukan empat warna berbeda.
class StatCardWidget extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final int index;

  const StatCardWidget({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    const angkaStyle = TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      color: kText,
      letterSpacing: -0.8,
      height: 1.1,
    );
    final angka = int.tryParse(count);

    return FadeSlideIn(
      index: index,
      child: PressScale(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kRadiusCard),
            border: Border.all(color: kBorder),
            boxShadow: kCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kBrandSoft,
                  borderRadius: BorderRadius.circular(kRadiusControl),
                ),
                child: Icon(icon, size: 20, color: kBrand),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  angka == null
                      ? Text(count, style: angkaStyle)
                      : CountUp(value: angka, style: angkaStyle),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: kMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
