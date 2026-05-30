import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/vas_bloc.dart';
import 'airtime_page.dart';
import 'data_page.dart';
import 'electricity_page.dart';
import 'betting_page.dart';

/// Entry point for all VAS services.
/// Fetches the catalog once on mount, then routes to individual pages.
class VasHubPage extends StatelessWidget {
  const VasHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VasBloc()..add(VasLoadCatalog()),
      child: const _VasHubView(),
    );
  }
}

class _VasHubView extends StatelessWidget {
  const _VasHubView();

  static const _brand = Color(0xff0b845c);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6f5),
      appBar: AppBar(
        title: Text(
          'Services',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<VasBloc, VasState>(
        builder: (context, state) {
          if (state is VasCatalogLoading || state is VasInitial) {
            return const Center(
              child: CircularProgressIndicator(color: _brand),
            );
          }

          if (state is VasCatalogLoaded) {
            return _CatalogGrid(catalog: state);
          }

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded,
                    size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'Could not load services',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.grey.shade500),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () =>
                      context.read<VasBloc>().add(VasLoadCatalog()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CatalogGrid extends StatelessWidget {
  final VasCatalogLoaded catalog;
  const _CatalogGrid({required this.catalog});

  static const _brand = Color(0xff0b845c);

  static const List<_ServiceTile> _tiles = [
    _ServiceTile(
      key: 'airtime',
      label: 'Airtime',
      subtitle: 'All networks',
      icon: Icons.phone_android_rounded,
      accent: Color(0xffffb300),
      bg: Color(0xfffff8e1),
    ),
    _ServiceTile(
      key: 'data',
      label: 'Data',
      subtitle: 'Bundles & plans',
      icon: Icons.wifi_rounded,
      accent: Color(0xff1e88e5),
      bg: Color(0xffe3f2fd),
    ),
    _ServiceTile(
      key: 'electricity',
      label: 'Electricity',
      subtitle: 'Prepaid & postpaid',
      icon: Icons.bolt_rounded,
      accent: Color(0xffef6c00),
      bg: Color(0xfffff3e0),
    ),
    _ServiceTile(
      key: 'betting',
      label: 'Betting',
      subtitle: 'Fund your wallet',
      icon: Icons.sports_soccer_rounded,
      accent: Color(0xff43a047),
      bg: Color(0xffe8f5e9),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero top bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: const BoxDecoration(
            color: _brand,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: Text(
            'What would you like to pay for?',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.1,
              children: _tiles.map((tile) {
                return _ServiceCard(
                  tile: tile,
                  onTap: () => _navigate(context, tile.key),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _navigate(BuildContext context, String key) {
    final bloc = context.read<VasBloc>();
    switch (key) {
      case 'airtime':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: bloc,
              child: AirtimePage(networks: catalog.airtimeNetworks),
            ),
          ),
        );
        break;
      case 'data':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: bloc,
              child: DataPage(
                networks: catalog.airtimeNetworks,
                dataPlans: catalog.dataPlans,
              ),
            ),
          ),
        );
        break;
      case 'electricity':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: bloc,
              child: ElectricityPage(discos: catalog.electricityDiscos),
            ),
          ),
        );
        break;
      case 'betting':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: bloc,
              child: BettingPage(providers: catalog.bettingProviders),
            ),
          ),
        );
        break;
    }
  }
}

class _ServiceCard extends StatelessWidget {
  final _ServiceTile tile;
  final VoidCallback onTap;
  const _ServiceCard({required this.tile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tile.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(tile.icon, color: tile.accent, size: 22),
            ),
            const Spacer(),
            Text(
              tile.label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tile.subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceTile {
  final String key;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color bg;

  const _ServiceTile({
    required this.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.bg,
  });
}
