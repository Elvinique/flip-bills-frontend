import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  static const _brand = Color(0xff0b845c);
  static const _surface = Color(0xfff4f6f5);

  final _searchCtrl = TextEditingController();
  String _query = '';
  int? _expandedIndex;

  static const _faqs = [
    _Faq(
      q: 'How do I fund my wallet?',
      a: 'Tap the "+ Fund Wallet" button on the dashboard. Choose an amount and a payment provider (Flutterwave or Monnify), then complete the payment on the provider\'s secure page. Your wallet is credited automatically once the transaction is confirmed.',
    ),
    _Faq(
      q: 'How long does it take for wallet funding to reflect?',
      a: 'Card payments typically reflect within seconds. Bank transfers may take up to 5 minutes. If your balance hasn\'t updated after 10 minutes, contact support with your payment reference.',
    ),
    _Faq(
      q: 'How do I buy airtime or data?',
      a: 'Tap "Airtime" or "Data" from the Quick Actions section on your dashboard. Select your network, enter the phone number, choose a plan and confirm with your PIN.',
    ),
    _Faq(
      q: 'What is my daily spend limit?',
      a: 'Your daily limit depends on your account tier. Basic accounts have a ₦50,000 daily limit. Standard and Premium accounts have higher limits. You can see your current usage on the wallet card.',
    ),
    _Faq(
      q: 'How do I upgrade my account tier?',
      a: 'Account upgrades are processed automatically based on your transaction history and identity verification. Premium upgrades require a verified BVN and consistent usage. Contact support for more details.',
    ),
    _Faq(
      q: 'I forgot my PIN. How do I reset it?',
      a: 'Currently, PIN resets require identity verification. Please contact our support team via WhatsApp or email and we will guide you through a secure PIN reset process.',
    ),
    _Faq(
      q: 'Why did my electricity or betting payment fail?',
      a: 'Payments can fail due to insufficient wallet balance, incorrect meter/betting account details, or a temporary issue with the service provider. Double-check your details and try again. If the amount was deducted but the service wasn\'t delivered, we will reverse it within 24 hours.',
    ),
    _Faq(
      q: 'How do I report a failed transaction?',
      a: 'Go to your transaction history, find the failed transaction, and tap "Report". Alternatively, contact support with the transaction reference and date.',
    ),
  ];

  List<_Faq> get _filteredFaqs {
    if (_query.trim().isEmpty) return _faqs;
    return _faqs
        .where((f) =>
            f.q.toLowerCase().contains(_query.toLowerCase()) ||
            f.a.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        '$label copied to clipboard!',
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: const Color(0xff0b845c),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFaqs;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _brand,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          'Help & Support',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 4),
          // Search
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() {
                      _query = v;
                      _expandedIndex = null;
                    }),
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search FAQs…',
                      hintStyle: GoogleFonts.plusJakartaSans(
                          color: Colors.grey.shade400, fontSize: 14),
                    ),
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                    child: Icon(Icons.close_rounded,
                        color: Colors.grey.shade400, size: 18),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Contact cards
          Text(
            'Contact Us',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xff1a1a1a),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ContactCard(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  sub: 'Chat with us',
                  color: const Color(0xff25d366),
                  onTap: () => _copyToClipboard('+2349000000000', 'WhatsApp number'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ContactCard(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  sub: 'support@flipbills.ng',
                  color: const Color(0xff4a90d9),
                  onTap: () => _copyToClipboard('support@flipbills.ng', 'Email address'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ContactCard(
            icon: Icons.phone_outlined,
            label: 'Call Support',
            sub: '+234 900 000 0000 · Mon–Fri, 8am–6pm',
            color: _brand,
            onTap: () => _copyToClipboard('+2349000000000', 'Phone number'),
            wide: true,
          ),
          const SizedBox(height: 28),
          // FAQs
          Text(
            'Frequently Asked Questions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xff1a1a1a),
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 44, color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    Text(
                      'No results for "$_query"',
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.grey.shade500, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(filtered.length, (i) {
              final faq = filtered[i];
              final expanded = _expandedIndex == i;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: expanded ? _brand.withValues(alpha: 0.4) : Colors.grey.shade200,
                  ),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    initiallyExpanded: expanded,
                    onExpansionChanged: (v) =>
                        setState(() => _expandedIndex = v ? i : null),
                    iconColor: _brand,
                    collapsedIconColor: Colors.grey.shade400,
                    title: Text(
                      faq.q,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff1a1a1a),
                      ),
                    ),
                    children: [
                      Text(
                        faq.a,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 32),
          // App version
          Center(
            child: Text(
              'Flip Bills v1.0.0',
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Data & Sub-widgets ───────────────────────────────────────────────────────

class _Faq {
  final String q;
  final String a;
  const _Faq({required this.q, required this.a});
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  final bool wide;
  const _ContactCard({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: wide ? double.infinity : null,
        padding: EdgeInsets.symmetric(
            horizontal: 16, vertical: wide ? 14 : 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: wide
            ? Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xff1a1a1a),
                        ),
                      ),
                      Text(
                        sub,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Colors.grey.shade400),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xff1a1a1a),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
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
