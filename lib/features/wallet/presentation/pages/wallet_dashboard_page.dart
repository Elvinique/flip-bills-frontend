import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/wallet_bloc.dart';
import '../../../../features/checkout/presentation/pages/search_aggregation_page.dart';
import '../../../../features/vas/presentation/pages/vas_hub_page.dart';
import '../../../../features/vas/presentation/bloc/vas_bloc.dart';
import '../../../../features/vas/presentation/pages/airtime_page.dart';
import '../../../../features/vas/presentation/pages/data_page.dart';
import '../../../../features/vas/presentation/pages/electricity_page.dart';
import '../../../../features/vas/presentation/pages/betting_page.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/auth/presentation/pages/login_page.dart';
import '../../../../features/profile/data/repositories/profile_repository.dart';
import '../../../../features/profile/presentation/pages/profile_page.dart';
import '../../../../features/profile/presentation/pages/change_password_page.dart';
import '../../../../features/profile/presentation/pages/help_support_page.dart';
import '../../../../features/checkout/presentation/pages/offline_travel_passes_page.dart';
import 'loyalty_rewards_page.dart';

class WalletDashboardPage extends StatelessWidget {
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialPhone;
  final String? initialDob;

  const WalletDashboardPage({
    super.key,
    this.initialFirstName,
    this.initialLastName,
    this.initialPhone,
    this.initialDob,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WalletBloc()..add(WalletLoadRequested()),
      child: _WalletDashboardView(
        initialFirstName: initialFirstName,
        initialLastName: initialLastName,
        initialPhone: initialPhone,
        initialDob: initialDob,
      ),
    );
  }
}

class _WalletDashboardView extends StatefulWidget {
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialPhone;
  final String? initialDob;

  const _WalletDashboardView({
    this.initialFirstName,
    this.initialLastName,
    this.initialPhone,
    this.initialDob,
  });

  @override
  State<_WalletDashboardView> createState() => _WalletDashboardViewState();
}

class _WalletDashboardViewState extends State<_WalletDashboardView>
    with TickerProviderStateMixin {
  bool _balanceVisible = true;
  late AnimationController _cardAnimCtrl;
  late AnimationController _actionsAnimCtrl;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _actionsFade;

  // User info — seeded from registration props, then overwritten by profile API
  String _firstName = '';
  String _lastName  = '';
  String _phone     = '';
  String _dob       = '';

  static const _brand = Color(0xff0b845c);
  static const _surface = Color(0xfff4f6f5);

  @override
  void initState() {
    super.initState();
    _firstName = widget.initialFirstName ?? '';
    _lastName  = widget.initialLastName  ?? '';
    _phone     = widget.initialPhone     ?? '';
    _dob       = widget.initialDob       ?? '';
    // Always fetch from API to ensure fresh data; seed values shown immediately
    _fetchUserProfile();
    _cardAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _actionsAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _cardFade = CurvedAnimation(parent: _cardAnimCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardAnimCtrl, curve: Curves.easeOutCubic));
    _actionsFade =
        CurvedAnimation(parent: _actionsAnimCtrl, curve: Curves.easeOut);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _cardAnimCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _actionsAnimCtrl.forward();
    });
  }

  @override
  void dispose() {
    _cardAnimCtrl.dispose();
    _actionsAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final repo = ProfileRepository();
      final data = await repo.getProfile();
      if (data != null && mounted) {
        setState(() {
          // Try both snake_case and camelCase variants
          _firstName = data['first_name']?.toString().trim()
              ?? data['firstName']?.toString().trim()
              ?? _firstName;
          _lastName  = data['last_name']?.toString().trim()
              ?? data['lastName']?.toString().trim()
              ?? _lastName;
          _phone     = data['phone']?.toString().trim()       ?? _phone;
          _dob       = data['date_of_birth']?.toString().trim()
              ?? data['dateOfBirth']?.toString().trim()
              ?? _dob;
        });
      }
    } catch (_) {}
  }

  String _formatNgn(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i != 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return '₦$buffer.$decPart';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state is WalletError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message,
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          }
          if (state is WalletFundingReady) {
            _showFundingSheet(context, state);
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            color: _brand,
            onRefresh: () async {
              context.read<WalletBloc>().add(WalletRefreshRequested());
              await Future.delayed(const Duration(milliseconds: 800));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAppBar(context, state),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        SlideTransition(
                          position: _cardSlide,
                          child: FadeTransition(
                            opacity: _cardFade,
                            child: _buildBalanceCard(context, state),
                          ),
                        ),
                        const SizedBox(height: 28),
                        FadeTransition(
                          opacity: _actionsFade,
                          child: _buildQuickActions(context),
                        ),
                        const SizedBox(height: 28),
                        _buildTransactionSection(context, state),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WalletState state) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final displayName = _firstName.isNotEmpty ? _firstName : 'User';
    final initials = (_firstName.isNotEmpty ? _firstName[0] : '') +
                     (_lastName.isNotEmpty  ? _lastName[0]  : '');

    return SliverAppBar(
      backgroundColor: _brand,
      expandedHeight: 0,
      floating: true,
      snap: true,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Greeting + name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                Text(
                  displayName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.white, size: 26),
            onPressed: () {},
          ),
          // Avatar with initials
          GestureDetector(
            onTap: () => _showProfileMenu(context),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              child: initials.isNotEmpty
                  ? Text(
                      initials.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_outline_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, WalletState state) {
    final isLoading = state is WalletLoading || state is WalletInitial;
    final balance = state is WalletLoaded ? state.balanceNgn : 0.0;
    final loyaltyPoints = state is WalletLoaded ? state.loyaltyPoints : 0;
    final tier = state is WalletLoaded ? state.tier : 'basic';
    final dailySpent = state is WalletLoaded ? state.dailySpentNgn : 0.0;
    final dailyLimit = state is WalletLoaded ? state.dailyLimitNgn : 50000.0;
    final progress = dailyLimit > 0 ? (dailySpent / dailyLimit).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff0b845c), Color(0xff064d37)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _brand.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row
                Row(
                  children: [
                    Text(
                      'Wallet Balance',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    _TierBadge(tier: tier),
                  ],
                ),
                const SizedBox(height: 12),
                // Balance
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (isLoading)
                      _Shimmer(
                        child: Container(
                          width: 180,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Text(
                          _balanceVisible ? _formatNgn(balance) : '₦ ••••••',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        _balanceVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 22,
                      ),
                      onPressed: () => setState(() => _balanceVisible = !_balanceVisible),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Daily spend progress
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daily spend',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${_formatNgn(dailySpent)} / ${_formatNgn(dailyLimit)}',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: isLoading ? null : progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress > 0.8 ? Colors.orangeAccent : Colors.white,
                        ),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Bottom row - loyalty + fund button
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoyaltyRewardsPage())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars_rounded, color: Colors.amber, size: 15),
                          const SizedBox(width: 5),
                          Text(
                            isLoading ? '...' : '$loyaltyPoints pts',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                    const Spacer(),
                    _FundButton(onTap: () => _showFundingDialog(context)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Opens a specific VAS page with a pre-seeded [VasBloc] (fallback catalog),
  /// so users land directly on the service without an extra hub step.
  void _openVasPage(BuildContext context, String vasKey) {
    // Build a VasBloc with the hardcoded fallback catalog ready to go
    final bloc = VasBloc()..add(VasLoadCatalog());

    const airtimeNetworks = <Map<String, dynamic>>[
      {'code': 'MTN', 'name': 'MTN Nigeria'},
      {'code': 'GLO', 'name': 'Globacom'},
      {'code': 'AIRTEL', 'name': 'Airtel Nigeria'},
      {'code': '9MOBILE', 'name': '9mobile'},
    ];
    const dataPlans = <Map<String, dynamic>>[
      {'code': 'MTN_1GB_30D', 'network': 'MTN', 'name': '1GB', 'amount': 50000, 'validity': '30 days'},
      {'code': 'MTN_2GB_30D', 'network': 'MTN', 'name': '2GB', 'amount': 100000, 'validity': '30 days'},
      {'code': 'GLO_1GB_30D', 'network': 'GLO', 'name': '1GB', 'amount': 50000, 'validity': '30 days'},
      {'code': 'AIRTEL_1GB_30D', 'network': 'AIRTEL', 'name': '1GB', 'amount': 50000, 'validity': '30 days'},
      {'code': '9MOBILE_1GB_30D', 'network': '9MOBILE', 'name': '1GB', 'amount': 50000, 'validity': '30 days'},
    ];
    const electricityDiscos = <Map<String, dynamic>>[
      {'code': 'IKEDC', 'name': 'Ikeja Electric'},
      {'code': 'EKEDC', 'name': 'Eko Electricity'},
      {'code': 'AEDC', 'name': 'Abuja Electricity'},
      {'code': 'PHED', 'name': 'Port Harcourt Electricity'},
      {'code': 'KEDCO', 'name': 'Kano Electricity'},
      {'code': 'IBEDC', 'name': 'Ibadan Electricity'},
      {'code': 'BEDC', 'name': 'Benin Electricity'},
      {'code': 'EEDC', 'name': 'Enugu Electricity'},
    ];
    const bettingProviders = <Map<String, dynamic>>[
      {'code': 'BET9JA', 'name': 'Bet9ja'},
      {'code': 'SPORTYBET', 'name': 'SportyBet'},
      {'code': 'BETKING', 'name': 'BetKing'},
      {'code': 'NAIRABET', 'name': 'NairaBET'},
      {'code': '1XBET', 'name': '1xBet'},
    ];

    Widget page;
    switch (vasKey) {
      case 'airtime':
        page = BlocProvider.value(
          value: bloc,
          child: const AirtimePage(networks: airtimeNetworks),
        );
        break;
      case 'data':
        page = BlocProvider.value(
          value: bloc,
          child: const DataPage(networks: airtimeNetworks, dataPlans: dataPlans),
        );
        break;
      case 'electricity':
        page = BlocProvider.value(
          value: bloc,
          child: const ElectricityPage(discos: electricityDiscos),
        );
        break;
      case 'betting':
        page = BlocProvider.value(
          value: bloc,
          child: const BettingPage(providers: bettingProviders),
        );
        break;
      default:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VasHubPage()));
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.phone_android_rounded,
        label: 'Airtime',
        color: const Color(0xff4a90d9),
        onTap: () => _openVasPage(context, 'airtime'),
      ),
      _QuickAction(
        icon: Icons.wifi_rounded,
        label: 'Data',
        color: const Color(0xff9b59b6),
        onTap: () => _openVasPage(context, 'data'),
      ),
      _QuickAction(
        icon: Icons.bolt_rounded,
        label: 'Electricity',
        color: const Color(0xffe67e22),
        onTap: () => _openVasPage(context, 'electricity'),
      ),
      _QuickAction(
        icon: Icons.sports_soccer_rounded,
        label: 'Betting',
        color: const Color(0xffe74c3c),
        onTap: () => _openVasPage(context, 'betting'),
      ),
      _QuickAction(
        icon: Icons.directions_bus_rounded,
        label: 'Travel',
        color: _brand,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SearchAggregationPage())),
      ),
      _QuickAction(
        icon: Icons.grid_view_rounded,
        label: 'All Services',
        color: Colors.grey.shade600,
        onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const VasHubPage())),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xff1a1a1a),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: actions.map((a) => _QuickActionTile(action: a)).toList(),
        ),
      ],
    );
  }

  Widget _buildTransactionSection(BuildContext context, WalletState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xff1a1a1a),
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<WalletBloc>().add(const WalletTransactionsRequested());
              },
              child: Text(
                'See all',
                style: GoogleFonts.plusJakartaSans(
                  color: _brand,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (state is WalletLoading || state is WalletInitial)
          ..._buildTransactionShimmers()
        else if (state is WalletTransactionsLoaded && state.transactions.isNotEmpty)
          ...state.transactions.take(5).map((tx) => _TransactionTile(tx: tx))
        else if (state is WalletLoaded)
          _buildEmptyTransactions()
        else if (state is WalletTransactionsLoaded && state.transactions.isEmpty)
          _buildEmptyTransactions()
        else
          _buildEmptyTransactions(),
      ],
    );
  }

  List<Widget> _buildTransactionShimmers() {
    return List.generate(
      4,
      (i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _Shimmer(
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Fund your wallet to get started',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showFundingDialog(BuildContext ctx) {
    final amountCtrl = TextEditingController();
    String provider = 'flutterwave';

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<WalletBloc>(),
        child: _FundingSheet(
          amountCtrl: amountCtrl,
          initialProvider: provider,
          onFund: (amount, prov) {
            ctx.read<WalletBloc>().add(
                  WalletFundingInitialized(
                    amountKobo: (amount * 100).toInt(),
                    provider: prov,
                  ),
                );
          },
        ),
      ),
    );
  }

  void _showFundingSheet(BuildContext context, WalletFundingReady state) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'Payment link ready. Ref: ${state.reference}',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: _brand,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      action: SnackBarAction(
        label: 'Open',
        textColor: Colors.white,
        onPressed: () {
          // Launch payment_link via url_launcher when added
        },
      ),
    ));
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            _ProfileMenuItem(
              icon: Icons.person_outline_rounded,
              label: 'My Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(
                      seedFirstName: _firstName,
                      seedLastName:  _lastName,
                      seedPhone:     _phone,
                      seedDob:       _dob,
                    ),
                  ),
                );
              },
            ),
            _ProfileMenuItem(
              icon: Icons.lock_outline_rounded,
              label: 'Change Password',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                );
              },
            ),
            _ProfileMenuItem(
              icon: Icons.airplane_ticket_rounded,
              label: 'Offline Travel Passes',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OfflineTravelPassesPage()),
                );
              },
            ),
            _ProfileMenuItem(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpSupportPage()),
                );
              },
            ),
            const Divider(height: 24),
            _ProfileMenuItem(
              icon: Icons.logout_rounded,
              label: 'Logout',
              color: Colors.red.shade600,
              onTap: () async {
                Navigator.pop(context); // close the bottom sheet
                await ApiClient.instance.clearTokens();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (_) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }


}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _TierBadge extends StatelessWidget {
  final String tier;
  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final label = tier == 'premium'
        ? '⭐ Premium'
        : tier == 'standard'
            ? '✦ Standard'
            : 'Basic';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FundButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FundButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Color(0xff0b845c), size: 18),
            const SizedBox(width: 5),
            Text(
              'Fund Wallet',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xff0b845c),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xff2d2d2d),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransactionTile({required this.tx});

  IconData _iconFor(String? type) {
    switch (type?.toLowerCase()) {
      case 'airtime':
        return Icons.phone_android_rounded;
      case 'data':
        return Icons.wifi_rounded;
      case 'electricity':
        return Icons.bolt_rounded;
      case 'betting':
        return Icons.sports_soccer_rounded;
      case 'travel':
        return Icons.directions_bus_rounded;
      case 'fund':
      case 'funding':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  Color _colorFor(String? type) {
    switch (type?.toLowerCase()) {
      case 'airtime':
        return const Color(0xff4a90d9);
      case 'data':
        return const Color(0xff9b59b6);
      case 'electricity':
        return const Color(0xffe67e22);
      case 'betting':
        return const Color(0xffe74c3c);
      case 'travel':
        return const Color(0xff0b845c);
      case 'fund':
      case 'funding':
        return const Color(0xff27ae60);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = tx['type'] as String?;
    final description = tx['description'] as String? ?? type ?? 'Transaction';
    final amountKobo = (tx['amount'] as num?)?.toDouble() ?? 0;
    final amountNgn = amountKobo / 100;
    final isCredit = tx['direction'] == 'credit' || (tx['type'] == 'fund');
    final status = tx['status'] as String? ?? 'success';
    final color = _colorFor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(type), color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: const Color(0xff1a1a1a),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  status == 'pending' ? 'Pending' : _timeAgo(tx['created_at']),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: status == 'pending'
                        ? Colors.orange.shade600
                        : Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}₦${(amountNgn).toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isCredit ? const Color(0xff0b845c) : const Color(0xff1a1a1a),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}

class _FundingSheet extends StatefulWidget {
  final TextEditingController amountCtrl;
  final String initialProvider;
  final void Function(double amount, String provider) onFund;

  const _FundingSheet({
    required this.amountCtrl,
    required this.initialProvider,
    required this.onFund,
  });

  @override
  State<_FundingSheet> createState() => _FundingSheetState();
}

class _FundingSheetState extends State<_FundingSheet> {
  late String _provider;
  static const _brand = Color(0xff0b845c);

  @override
  void initState() {
    super.initState();
    _provider = widget.initialProvider;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Fund Wallet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xff1a1a1a),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select a payment method and enter amount',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),

            // ── Payment Method Cards ──
            Text(
              'Payment Method',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: const Color(0xff1a1a1a),
              ),
            ),
            const SizedBox(height: 12),
            _ProviderTile(
              icon: Icons.account_balance_rounded,
              iconColor: const Color(0xff1565c0),
              iconBg: const Color(0xffe3f2fd),
              title: 'Bank Transfer',
              subtitle: 'Transfer from any bank account instantly',
              selected: _provider == 'bank_transfer',
              onTap: () => setState(() => _provider = 'bank_transfer'),
            ),
            const SizedBox(height: 10),
            _ProviderTile(
              icon: Icons.credit_card_rounded,
              iconColor: const Color(0xffe67e00),
              iconBg: const Color(0xfffff8e1),
              title: 'Flutterwave',
              subtitle: 'Pay with card, bank transfer or USSD',
              selected: _provider == 'flutterwave',
              onTap: () => setState(() => _provider = 'flutterwave'),
            ),
            const SizedBox(height: 10),
            _ProviderTile(
              icon: Icons.swap_horiz_rounded,
              iconColor: const Color(0xff2e7d32),
              iconBg: const Color(0xffe8f5e9),
              title: 'Monnify',
              subtitle: 'Virtual account — instant settlement',
              selected: _provider == 'monnify',
              onTap: () => setState(() => _provider = 'monnify'),
            ),
            const SizedBox(height: 24),

            // ── Amount Input ──
            Text(
              'Amount',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: const Color(0xff1a1a1a),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xfff8f9fa),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '₦',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _brand,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: widget.amountCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xff1a1a1a),
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: Colors.grey.shade400,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Quick amount chips
            Wrap(
              spacing: 8,
              children: [1000, 2000, 5000, 10000, 20000].map((amt) {
                return GestureDetector(
                  onTap: () => widget.amountCtrl.text = amt.toString(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _brand.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _brand.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '₦${amt ~/ 1000}k',
                      style: GoogleFonts.plusJakartaSans(
                        color: _brand,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  final text = widget.amountCtrl.text.trim();
                  final amount = double.tryParse(text);
                  if (amount == null || amount < 100) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Minimum amount is ₦100',
                          style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red.shade700,
                    ));
                    return;
                  }
                  Navigator.pop(context);
                  widget.onFund(amount, _provider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Continue to Payment',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Payment Provider Tile ────────────────────────────────────────────────────

class _ProviderTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ProviderTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  static const _brand = Color(0xff0b845c);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _brand.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _brand : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: _brand.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xff1a1a1a),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: _brand,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
              )
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _ProfileMenuItem(
      {required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xff1a1a1a);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: c, size: 22),
      title: Text(label,
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600, fontSize: 14, color: c)),
      onTap: onTap,
    );
  }
}

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _anim, child: widget.child);
  }
}
