import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class TravelDashboardPage extends StatelessWidget {
  const TravelDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Travel Engine'),
        backgroundColor: AppColors.brand,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.confirmation_num_outlined),
            onPressed: () => context.push('/travel/tickets'),
            tooltip: 'My Tickets',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Where to next?',
              style: AppText.h1(),
            ),
            const SizedBox(height: 8),
            Text(
              'Book inter-state buses or flights instantly.',
              style: AppText.body(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            _buildTravelOptionCard(
              context: context,
              title: 'Inter-State Bus',
              subtitle: 'GIGM, ABC Transport & more',
              icon: Icons.directions_bus_filled,
              color: AppColors.brand,
              onTap: () => context.push('/travel/bus'),
            ),
            const SizedBox(height: 16),
            _buildTravelOptionCard(
              context: context,
              title: 'Flights',
              subtitle: 'Domestic & International',
              icon: Icons.flight_takeoff,
              color: AppColors.info,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Flight booking coming soon in Phase 3!')),
                );
              },
            ),
            const SizedBox(height: 32),
            _buildPromoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: AppCard.standard(),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.h3()),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppText.caption()),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard() {
    return Container(
      decoration: AppCard.gradient(),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Travel Insurance',
                  style: AppText.h3(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add trip cancellation cover for just ₦500 and travel with peace of mind.',
                  style: AppText.body(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.shield, color: Colors.white, size: 48),
        ],
      ),
    );
  }
}
