import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return _CategoryCard(category: cat);
              },
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF121212),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 72),
        title: const Text(
          'PocusApp',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A2E), Color(0xFF121212)],
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Busca global em breve')),
              );
            },
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search, color: Colors.grey[500], size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Buscar protocolos, doenças, cálculos...',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _CategoryData {
  const _CategoryData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final String? route;
}

const List<_CategoryData> _categories = [
  _CategoryData(
    title: 'POCUS',
    subtitle: 'Ultrassom\nPoint-of-Care',
    icon: Icons.monitor_heart_outlined,
    gradientColors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
    route: '/pocus',
  ),
  _CategoryData(
    title: 'Via Aérea',
    subtitle: 'Intubação\ne Drogas',
    icon: Icons.air_outlined,
    gradientColors: [Color(0xFF00695C), Color(0xFF004D40)],
  ),
  _CategoryData(
    title: 'Calculadoras',
    subtitle: 'Débito Cardíaco\nVolume Sistólico',
    icon: Icons.calculate_outlined,
    gradientColors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
  ),
  _CategoryData(
    title: 'Emergências',
    subtitle: 'IAM, Choque\ne Protocolos',
    icon: Icons.local_hospital_outlined,
    gradientColors: [Color(0xFFC62828), Color(0xFFB71C1C)],
  ),
];

// ---------------------------------------------------------------------------
// Card widget
// ---------------------------------------------------------------------------

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final _CategoryData category;

  void _handleTap(BuildContext context) {
    if (category.route != null) {
      context.go(category.route!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${category.title} — em breve')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: category.gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: category.gradientColors.last.withValues(alpha: 0.45),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with semi-transparent background circle
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  category.icon,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                category.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                category.subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
