import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/transfer_bloc.dart';
import '../../../../core/services/biometric_service.dart';

class TransferPage extends StatefulWidget {
  const TransferPage({super.key});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage>
    with TickerProviderStateMixin {
  static const _brand = Color(0xff0b845c);
  static const _surface = Color(0xfff4f6f5);

  late TabController _tabController;
  // Bank transfer controllers
  final _accountCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _narrationCtrl = TextEditingController();
  // Wallet transfer controllers
  final _phoneCtrl = TextEditingController();
  final _walletAmountCtrl = TextEditingController();
  final _walletNarrationCtrl = TextEditingController();

  String? _selectedBankCode;
  String? _selectedBankName;
  String? _resolvedAccountName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<TransferBloc>().add(TransferLoadBanks());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _accountCtrl.dispose();
    _amountCtrl.dispose();
    _narrationCtrl.dispose();
    _phoneCtrl.dispose();
    _walletAmountCtrl.dispose();
    _walletNarrationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        title: Text(
          'Send Money',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Bank Transfer'),
            Tab(text: 'Flip Bills Wallet'),
          ],
        ),
        elevation: 0,
      ),
      body: BlocConsumer<TransferBloc, TransferState>(
        listener: (context, state) {
          if (state is TransferAccountResolved) {
            setState(() => _resolvedAccountName = state.accountName);
          }
          if (state is TransferSuccess) {
            _showSuccessSheet(context, state);
          }
          if (state is TransferFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message,
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          }
        },
        builder: (context, state) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildBankTransferTab(context, state),
              _buildWalletTransferTab(context, state),
            ],
          );
        },
      ),
    );
  }

  // ── Bank Transfer Tab ──────────────────────────────────────────────────────

  Widget _buildBankTransferTab(BuildContext context, TransferState state) {
    final banks = state is TransferBanksLoaded
        ? state.banks
        : state is TransferAccountResolved
            ? state.banks
            : <Map<String, dynamic>>[];

    final isResolvingAccount = state is TransferResolvingAccount;
    final isProcessing = state is TransferProcessing;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _SectionHeader(text: 'Recipient Details'),
          const SizedBox(height: 16),

          // Bank selector
          _BankDropdown(
            banks: banks,
            selectedCode: _selectedBankCode,
            selectedName: _selectedBankName,
            onChanged: (code, name) {
              setState(() {
                _selectedBankCode = code;
                _selectedBankName = name;
                _resolvedAccountName = null;
              });
              _tryResolveAccount(context);
            },
          ),
          const SizedBox(height: 14),

          // Account number
          TextField(
            controller: _accountCtrl,
            keyboardType: TextInputType.number,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) {
              setState(() => _resolvedAccountName = null);
              if (_accountCtrl.text.length == 10 && _selectedBankCode != null) {
                _tryResolveAccount(context);
              }
            },
            decoration: _inputDec(
              label: 'Account Number',
              hint: '10-digit NUBAN',
              suffix: isResolvingAccount
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _brand),
                    )
                  : null,
            ),
          ),

          // Resolved account name
          if (_resolvedAccountName != null) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xff0b845c).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _brand.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: _brand, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _resolvedAccountName!,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _brand),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),

          _SectionHeader(text: 'Transfer Details'),
          const SizedBox(height: 16),

          // Amount
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDec(
              label: 'Amount (₦)',
              hint: 'e.g. 5000',
              prefix: const Icon(Icons.attach_money_rounded,
                  color: _brand, size: 20),
            ),
          ),
          const SizedBox(height: 14),

          // Narration
          TextField(
            controller: _narrationCtrl,
            decoration: _inputDec(
              label: 'Narration',
              hint: 'What is this for? (optional)',
            ),
          ),
          const SizedBox(height: 28),

          // Send button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (isProcessing || isResolvingAccount)
                  ? null
                  : () => _submitBankTransfer(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      'Continue',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Wallet Transfer Tab ────────────────────────────────────────────────────

  Widget _buildWalletTransferTab(BuildContext context, TransferState state) {
    final isProcessing = state is TransferProcessing;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _brand.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _brand.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: _brand, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Send instantly to any Flip Bills wallet. Free, zero fees.',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: _brand,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(text: 'Recipient'),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDec(
              label: 'Phone Number',
              hint: '08012345678',
              prefix: const Icon(Icons.phone_rounded, color: _brand, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          _SectionHeader(text: 'Amount'),
          const SizedBox(height: 16),
          TextField(
            controller: _walletAmountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDec(
              label: 'Amount (₦)',
              hint: 'e.g. 2000',
              prefix: const Icon(Icons.attach_money_rounded,
                  color: _brand, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _walletNarrationCtrl,
            decoration: _inputDec(
              label: 'Narration',
              hint: 'What is this for? (optional)',
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isProcessing ? null : () => _submitWalletTransfer(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      'Send Money',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _tryResolveAccount(BuildContext context) {
    if (_accountCtrl.text.length == 10 && _selectedBankCode != null) {
      context.read<TransferBloc>().add(TransferResolveAccount(
            accountNumber: _accountCtrl.text,
            bankCode: _selectedBankCode!,
          ));
    }
  }

  Future<void> _submitBankTransfer(BuildContext context) async {
    final account = _accountCtrl.text.trim();
    final amountText = _amountCtrl.text.trim();
    final narration = _narrationCtrl.text.trim();

    if (_selectedBankCode == null) {
      _snack(context, 'Please select a bank');
      return;
    }
    if (account.length != 10) {
      _snack(context, 'Enter a valid 10-digit account number');
      return;
    }
    if (_resolvedAccountName == null) {
      _snack(context, 'Account not resolved yet. Please wait.');
      return;
    }
    final amount = int.tryParse(amountText);
    if (amount == null || amount < 100) {
      _snack(context, 'Enter a valid amount (minimum ₦100)');
      return;
    }

    final confirmed = await _showConfirmationSheet(
      context,
      accountName: _resolvedAccountName!,
      accountNumber: account,
      bankName: _selectedBankName ?? '',
      amount: amount,
      narration: narration.isEmpty ? 'Transfer' : narration,
    );
    if (!confirmed) return;

    final biometricOk = await BiometricService.instance.authenticate(
      reason: 'Confirm transfer of ₦$amount to $_resolvedAccountName',
    );
    if (!biometricOk) {
      _snack(context, 'Authentication failed. Transfer cancelled.');
      return;
    }

    if (context.mounted) {
      context.read<TransferBloc>().add(TransferSendBank(
            accountNumber: account,
            bankCode: _selectedBankCode!,
            accountName: _resolvedAccountName!,
            amountKobo: amount * 100,
            narration: narration.isEmpty ? 'Transfer' : narration,
          ));
    }
  }

  Future<void> _submitWalletTransfer(BuildContext context) async {
    final phone = _phoneCtrl.text.trim();
    final amountText = _walletAmountCtrl.text.trim();
    final narration = _walletNarrationCtrl.text.trim();

    if (phone.length < 10) {
      _snack(context, 'Enter a valid phone number');
      return;
    }
    final amount = int.tryParse(amountText);
    if (amount == null || amount < 100) {
      _snack(context, 'Enter a valid amount (minimum ₦100)');
      return;
    }

    final biometricOk = await BiometricService.instance.authenticate(
      reason: 'Confirm wallet transfer of ₦$amount',
    );
    if (!biometricOk) {
      _snack(context, 'Authentication failed.');
      return;
    }

    if (context.mounted) {
      context.read<TransferBloc>().add(TransferSendWallet(
            recipientPhone: phone,
            amountKobo: amount * 100,
            narration: narration.isEmpty ? 'Wallet Transfer' : narration,
          ));
    }
  }

  Future<bool> _showConfirmationSheet(
    BuildContext context, {
    required String accountName,
    required String accountNumber,
    required String bankName,
    required int amount,
    required String narration,
  }) async {
    final result = await showModalBottomSheet<bool>(
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
            const SizedBox(height: 20),
            Text('Confirm Transfer',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _ConfirmRow(label: 'To', value: accountName),
            _ConfirmRow(label: 'Account', value: accountNumber),
            _ConfirmRow(label: 'Bank', value: bankName),
            _ConfirmRow(label: 'Amount', value: '₦$amount'),
            _ConfirmRow(label: 'Narration', value: narration),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Color(0xff0b845c)),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.plusJakartaSans(
                            color: _brand, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brand,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Confirm',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  void _showSuccessSheet(BuildContext context, TransferSuccess state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _brand.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: _brand, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Transfer Successful!',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(state.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey.shade600, fontSize: 14)),
            if (state.reference.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Ref: ${state.reference}',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.grey.shade400, fontSize: 12)),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text('Done',
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  InputDecoration _inputDec({
    required String label,
    String? hint,
    Widget? prefix,
    Widget? suffix,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefix,
        suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.all(12), child: suffix) : null,
        filled: true,
        fillColor: Colors.white,
        labelStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _brand, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        counterText: '',
      );
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader({required this.text});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xff1a1a1a)),
      );
}

class _BankDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> banks;
  final String? selectedCode;
  final String? selectedName;
  final void Function(String code, String name) onChanged;

  const _BankDropdown({
    required this.banks,
    required this.selectedCode,
    required this.selectedName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: banks.isEmpty ? null : () => _showBankPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance_rounded,
                color: Color(0xff0b845c), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedName ?? (banks.isEmpty ? 'Loading banks…' : 'Select Bank'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: selectedName != null
                      ? const Color(0xff1a1a1a)
                      : Colors.grey.shade500,
                  fontWeight:
                      selectedName != null ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  void _showBankPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BankPickerSheet(
        banks: banks,
        onSelected: onChanged,
      ),
    );
  }
}

class _BankPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> banks;
  final void Function(String code, String name) onSelected;

  const _BankPickerSheet({required this.banks, required this.onSelected});

  @override
  State<_BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<_BankPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.banks;
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? widget.banks
            : widget.banks.where((b) {
                return (b['name'] as String).toLowerCase().contains(q);
              }).toList();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search banks…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: const Color(0xfff4f6f5),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final bank = _filtered[i];
                  return ListTile(
                    title: Text(bank['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSelected(
                          bank['code'] as String, bank['name'] as String);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  const _ConfirmRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.grey.shade500, fontSize: 13)),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}
