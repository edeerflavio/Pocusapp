import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/pocus_item.dart';

// ---------------------------------------------------------------------------
// PocusScreen — Protocol / Category List
// Route: /pocus   (Branch 2 in StatefulShellRoute)
// ---------------------------------------------------------------------------

class PocusScreen extends StatelessWidget {
  const PocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: _ProtocolList(),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'POCUS',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'Selecione um protocolo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        background: Container(color: Colors.white),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Protocol data model
// ---------------------------------------------------------------------------

class _Protocol {
  const _Protocol({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.category,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String category;

  PocusItem toMockItem() => PocusItem(
        id: id,
        category: category,
        titlePt: title,
        titleEs: title,
        bodyPt: '',
        bodyEs: '',
        isPremium: false,
        status: 'published',
      );
}

const List<_Protocol> _protocols = [
  _Protocol(
    id: 'pocus-cardiac',
    title: 'Cardíaco',
    subtitle: 'Função ventricular, derrame pericárdico e tamponamento',
    icon: Icons.favorite_border,
    color: Color(0xFFE53935),
    category: 'Cardíaco',
  ),
  _Protocol(
    id: 'pocus-pulmonar',
    title: 'Pulmonar',
    subtitle: 'Pneumotórax, derrame pleural e consolidação',
    icon: Icons.air_outlined,
    color: Color(0xFF1565C0),
    category: 'Pulmonar',
  ),
  _Protocol(
    id: 'pocus-fast',
    title: 'FAST',
    subtitle: 'Focused Assessment with Sonography in Trauma',
    icon: Icons.emergency_outlined,
    color: Color(0xFFE65100),
    category: 'FAST',
  ),
  _Protocol(
    id: 'pocus-rush',
    title: 'RUSH',
    subtitle: 'Rapid Ultrasound in Shock — avaliação do choque',
    icon: Icons.monitor_heart_outlined,
    color: Color(0xFF6A1B9A),
    category: 'RUSH',
  ),
  _Protocol(
    id: 'pocus-casa',
    title: 'CASA',
    subtitle: 'Cardiac Arrest Sonographic Assessment',
    icon: Icons.local_hospital_outlined,
    color: Color(0xFF00695C),
    category: 'CASA',
  ),
  _Protocol(
    id: 'pocus-dtc',
    title: 'DTC',
    subtitle: 'Doppler Transcraniano — vasospasmo e HSA',
    icon: Icons.hub_outlined,
    color: Color(0xFF37474F),
    category: 'DTC',
  ),
];

// ---------------------------------------------------------------------------
// Sliver list
// ---------------------------------------------------------------------------

class _ProtocolList extends StatelessWidget {
  const _ProtocolList();

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: _protocols.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _ProtocolCard(protocol: _protocols[index]);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Protocol card
// ---------------------------------------------------------------------------

class _ProtocolCard extends StatelessWidget {
  const _ProtocolCard({required this.protocol});

  final _Protocol protocol;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final item = protocol.toMockItem();
          context.go('/pocus/player/${item.id}', extra: item);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: protocol.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(protocol.icon, color: protocol.color, size: 24),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      protocol.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      protocol.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
