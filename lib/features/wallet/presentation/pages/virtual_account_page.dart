import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_client.dart';

class VirtualAccountPage extends StatefulWidget {
  const VirtualAccountPage({super.key});

  @override
  State<VirtualAccountPage> createState() => _VirtualAccountPageState();
}

class _VirtualAccountPageState extends State<VirtualAccountPage> {
  static const _brand = Color(0xff0b845c);
  Map<String, dynamic>? _account;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    setState(() => _loading = true);
    try {
      final response = await ApiClient.instance.dio.get('/api/v1/wallet/virtual-account');
      if (response.statusCode == 200 && response.data['data'] != null) {
        setState(() {
          _account = response.data['data'] as Map<String, dynamic>;
          _loading = false;
        });
      } else if (response.statusCode == 404) {
        // No account yet — create one
        await _createAccount();
      } else {
        setState(() { _error = 'Could not load virtual account.'; _loading = false; });
      }
    } catch (e) {
      log('VirtualAccountPage._loadAccount: $e');
      setState(() { _error = 'Network error. Please retry.'; _loading = false; });
    }
  }

  Future<void> _createAccount() async {
    try {
      final response = await ApiClient.instance.dio.post('/api/v1/wallet/virtual-account');
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _account = response.data['data'] as Map<String, dynamic>?;
          _loading = false;
        });
      } else {
        setState(() { _error = 'Could not create virtual account.'; _loading = false; });
      }
    } catch (e) {
      log('VirtualAccountPage._createAccount: $e');
      setState(() { _error = 'Failed to create account. Please retry.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6f5),
      appBar: AppBar(
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        title: Text(
          'Virtual Account',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : _error != null
              ? _errorView()
              : _accountView(),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Retry',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountView() {
    final account = _account!;
    final accountNumber = account['account_number']?.toString() ?? '—';
    final accountName = account['account_name']?.toString() ?? '—';
    final bankName = account['bank_name']?.toString() ?? 'Moniepoint';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff0b845c), Color(0xff064d37)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _brand.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_rounded,
                        color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      bankName,
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Virtual Account',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  accountNumber,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  accountName,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Copy button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: accountNumber));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Account number copied!',
                      style: TextStyle(color: Colors.white)),
                  backgroundColor: _brand,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
              label: Text(
                'Copy Account Number',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Info panel
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to fund your wallet',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ...[
                  ('1.', 'Copy your dedicated account number above'),
                  ('2.', 'Transfer any amount from your bank app or USSD'),
                  ('3.', 'Your Flip Bills wallet is credited automatically'),
                  ('4.', 'Minimum deposit: ₦100'),
                ].map((step) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _brand.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(step.$1,
                                  style: GoogleFonts.plusJakartaSans(
                                      color: _brand,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(step.$2,
                                style: GoogleFonts.plusJakartaSans(
                                    color: Colors.grey.shade600, fontSize: 13)),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
