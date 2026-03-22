import 'package:flutter/material.dart';

/// Shimmer effect skeleton loader for content placeholders.
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                Color(0xFFEEEEEE),
                Color(0xFFF5F5F5),
                Color(0xFFEEEEEE),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Feed & Social skeletons
// ─────────────────────────────────────────────────────────────────

/// Tek bir feed post için shimmer skeleton.
/// AgendaController isLoading durumunda kullan.
class FeedPostSkeleton extends StatelessWidget {
  const FeedPostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + isim satırı
          Row(
            children: const [
              SkeletonLoader(width: 40, height: 40, borderRadius: 20),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(width: 120, height: 13),
                  SizedBox(height: 6),
                  SkeletonLoader(width: 80, height: 11),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Medya alanı (kare)
          const SkeletonLoader(height: 300, borderRadius: 12),
          const SizedBox(height: 10),
          // Aksiyon ikonları satırı
          Row(
            children: const [
              SkeletonLoader(width: 24, height: 24, borderRadius: 4),
              SizedBox(width: 12),
              SkeletonLoader(width: 24, height: 24, borderRadius: 4),
              SizedBox(width: 12),
              SkeletonLoader(width: 24, height: 24, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 10),
          // Beğeni sayısı
          const SkeletonLoader(width: 80, height: 12),
          const SizedBox(height: 6),
          // Açıklama
          const SkeletonLoader(height: 12),
          const SizedBox(height: 4),
          const SkeletonLoader(width: 200, height: 12),
        ],
      ),
    );
  }
}

/// 3'lü feed post skeleton listesi (ilk yüklemede göster).
class FeedSkeleton extends StatelessWidget {
  final int itemCount;
  const FeedSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (_, __) => const FeedPostSkeleton(),
    );
  }
}

/// Short video (tam ekran) için minimal skeleton.
/// Black background üzerinde shimmer bar'lar.
class ShortVideoSkeleton extends StatelessWidget {
  const ShortVideoSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Video alanı
          const Center(
            child: SkeletonLoader(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 0,
            ),
          ),
          // Alt bilgi alanı
          Positioned(
            bottom: 80,
            left: 16,
            right: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    SkeletonLoader(width: 36, height: 36, borderRadius: 18),
                    SizedBox(width: 8),
                    SkeletonLoader(width: 100, height: 14),
                  ],
                ),
                SizedBox(height: 10),
                SkeletonLoader(height: 12),
                SizedBox(height: 6),
                SkeletonLoader(width: 180, height: 12),
              ],
            ),
          ),
          // Sağ aksiyon bar
          Positioned(
            right: 12,
            bottom: 120,
            child: Column(
              children: List.generate(
                4,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child:
                      SkeletonLoader(width: 32, height: 32, borderRadius: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Profil post grid için skeleton (3 sütun).
class ProfileGridSkeleton extends StatelessWidget {
  final int itemCount;
  const ProfileGridSkeleton({super.key, this.itemCount = 9});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) =>
          const SkeletonLoader(height: double.infinity, borderRadius: 0),
    );
  }
}

/// Story row skeleton (yatay scroll).
class StoryRowSkeleton extends StatelessWidget {
  final int itemCount;
  const StoryRowSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: const [
              SkeletonLoader(width: 56, height: 56, borderRadius: 28),
              SizedBox(height: 6),
              SkeletonLoader(width: 48, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Education skeletons (orijinal)
// ─────────────────────────────────────────────────────────────────

/// Grid skeleton for education modules (2-column grid of cards).
class EducationGridSkeleton extends StatelessWidget {
  final int itemCount;

  const EducationGridSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.65,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return const _CardSkeleton();
        },
      ),
    );
  }
}

/// List skeleton for education modules (vertical list of cards).
class EducationListSkeleton extends StatelessWidget {
  final int itemCount;

  const EducationListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                SkeletonLoader(width: 60, height: 60, borderRadius: 8),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(height: 14, width: 150),
                      SizedBox(height: 8),
                      SkeletonLoader(height: 12, width: 100),
                      SizedBox(height: 6),
                      SkeletonLoader(height: 12, width: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(height: 120, borderRadius: 12),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SkeletonLoader(height: 14, width: 120),
          ),
          SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SkeletonLoader(height: 12, width: 80),
          ),
          SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SkeletonLoader(height: 12, width: 60),
          ),
        ],
      ),
    );
  }
}
