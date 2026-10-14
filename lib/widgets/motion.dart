import 'package:flutter/material.dart';

import '../app/theme.dart';

// Gerakan di app ini punya tujuan: urutan muncul (hierarki), umpan balik
// sentuhan, dan status memuat. Semuanya mati bila pengguna memilih
// "kurangi animasi" di pengaturan sistem.
bool kurangiGerak(BuildContext context) =>
    MediaQuery.of(context).disableAnimations;

/// Muncul pelan dari bawah, berurutan menurut [index]. Dimainkan sekali saat
/// widget pertama dibangun (item daftar muncul saat digulir masuk).
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (kurangiGerak(context)) return child;
    final delay = index.clamp(0, 8) * 55;
    final total = 380 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - v)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Mengecil sedikit saat ditekan. Tidak menelan ketukan: InkWell di dalamnya
/// tetap bekerja.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child});

  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down && !kurangiGerak(context) ? 0.975 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Angka menghitung naik dari 0 saat pertama tampil.
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, this.style});

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (kurangiGerak(context)) return Text('$value', style: style);
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('$v', style: style),
    );
  }
}

/// Pengganti spinner: kerangka daftar yang berdenyut pelan, bentuknya
/// mirip kartu yang akan tampil.
class ListSkeleton extends StatefulWidget {
  const ListSkeleton({super.key, this.count = 6});

  final int count;

  @override
  State<ListSkeleton> createState() => _ListSkeletonState();
}

class _ListSkeletonState extends State<ListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diam = kurangiGerak(context);
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: widget.count,
      separatorBuilder: (context, i) => const SizedBox(height: 10),
      itemBuilder: (context, i) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Opacity(
          opacity: diam
              ? 0.7
              : 0.45 + 0.4 * Curves.easeInOut.transform(_c.value),
          child: child,
        ),
        child: Container(
          height: 76,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kRadiusCard),
            border: Border.all(color: kBorder),
          ),
          child: Row(
            children: [
              const CircleAvatar(radius: 20, backgroundColor: kField),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 160,
                      decoration: BoxDecoration(
                        color: kField,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 10,
                      width: 110,
                      decoration: BoxDecoration(
                        color: kField,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
