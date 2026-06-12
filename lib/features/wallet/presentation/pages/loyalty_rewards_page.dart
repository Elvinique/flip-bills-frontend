import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoyaltyRewardsPage extends StatelessWidget {
  const LoyaltyRewardsPage({super.key});

  static const _brand = Color(0xff0b845c);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6f5),
      appBar: AppBar(
        title: Text(
          'Loyalty Rewards',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: _brand,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPointsBanner(),
            const SizedBox(height: 32),
            Text(
              'Redeem Points',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xff1a1d20),
              ),
            ),
            const SizedBox(height: 16),
            _buildRedemptionOptions(context),
            const SizedBox(height: 32),
            Text(
              'How to Earn',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xff1a1d20),
              ),
            ),
            const SizedBox(height: 16),
            _buildEarnGuide(),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffffb300), Color(0xfff57c00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.stars_rounded, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(
            '1,250 PTS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Equivalent to ₦1,250 Cashback',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedemptionOptions(BuildContext context) {
    final options = [
      {
        'title': 'Convert to Wallet Cash',
        'subtitle': 'Minimum 1,000 pts',
        'icon': Icons.account_balance_wallet_rounded,
        'color': _brand,
      },
      {
        'title': 'Free 1GB Data',
        'subtitle': '500 pts',
        'icon': Icons.wifi_rounded,
        'color': const Color(0xff9b59b6),
      },
      {
        'title': '₦500 Airtime',
        'subtitle': '500 pts',
        'icon': Icons.phone_android_rounded,
        'color': const Color(0xff4a90d9),
      },
    ];

    return Column(
      children: options.map((opt) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (opt['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(opt['icon'] as IconData, color: opt['color'] as Color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opt['title'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: const Color(0xff1a1d20),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opt['subtitle'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Redemption coming soon!'),
                      backgroundColor: Colors.orange.shade700,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Redeem'),
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEarnGuide() {
    final guides = [
      {'title': 'Pay Bills', 'desc': 'Earn 10 points per ₦10,000 spent on utility bills.'},
      {'title': 'Book Flights', 'desc': 'Earn 50 points per domestic flight ticket.'},
      {'title': 'Refer Friends', 'desc': 'Get 200 points when a friend completes KYC.'},
    ];

    return Column(
      children: guides.map((g) => Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.amber, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    g['title']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    g['desc']!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      )).toList(),
    );
  }
}
