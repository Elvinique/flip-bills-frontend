import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/checkout_bloc.dart';
import '../bloc/checkout_state.dart';
import '../../data/repositories/transit_aggregation_repository.dart';
import '../../../../../features/wallet/data/repositories/wallet_repository.dart';
import '../widgets/bus_seat_grid.dart';
import '../widgets/contextual_checkout_sheet.dart';
import '../widgets/offline_ticket_pass_card.dart';

class SearchAggregationPage extends StatefulWidget {
  const SearchAggregationPage({super.key});

  @override
  State<SearchAggregationPage> createState() => _SearchAggregationPageState();
}

class _SearchAggregationPageState extends State<SearchAggregationPage> {
  final TextEditingController _toController = TextEditingController(text: 'Abuja');
  final TransitAggregationRepository _vasRepo = TransitAggregationRepository();
  DateTime _travelDate = DateTime.now();
  double _walletBalance = 0.00;

  @override
  void dispose() {
    _toController.dispose();
    super.dispose();
  }
final WalletRepository _walletRepo = WalletRepository();

@override
void initState() {
  super.initState();
  _loadWalletBalance();
}

Future<void> _loadWalletBalance() async {
  final data = await _walletRepo.getBalance();
  if (data != null && mounted) {
    setState(() {
      _walletBalance = (data['balance_ngn'] as num).toDouble();
    });
  } else {

  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: const Color(0xff0b845c),
        elevation: 0,
        title: Text(
          'Flip Bills',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_toggle_off_rounded, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: BlocConsumer<CheckoutBloc, CheckoutState>(
        listener: (context, state) {
          if (state is CheckoutSuccess) {
            _showBookingConfirmation(context, state);
          } else if (state is CheckoutFailureReversal) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.orangeAccent.shade700,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPremiumWalletHeader(),
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text("Fintech Bill Utilities", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xff1a1d20))),
                      const SizedBox(height: 12),
                      _buildVasServiceGrid(),
                      const SizedBox(height: 28),
                      Text("Book Inter-State Travel", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xff1a1d20))),
                      const SizedBox(height: 12),
                      _buildSearchFormCard(),
                      const SizedBox(height: 24),
                      
                      if (state is CheckoutFailureReversal) ...[
                        OfflineTicketPassCard(ticketId: "FLIP-SECURE-849204", destination: _toController.text, seats: const [5, 6]),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            icon: const Icon(Icons.refresh_rounded, color: Color(0xff0b845c)),
                            label: const Text("Reset to Live Mode", style: TextStyle(color: Color(0xff0b845c), fontWeight: FontWeight.bold)),
                            onPressed: () => context.read<CheckoutBloc>().add(const UpdateSeatSelection([])),
                          ),
                        ),
                      ],

                      if (state is CheckoutSelectionActive) ...[
                        Text("Select Seats (Click 2)", style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 200,
                          child: BusSeatGrid(
                            totalRows: 4, seatsPerRow: 4, occupiedSeats: const [3, 7],
                            onSeatsChanged: (seats) => context.read<CheckoutBloc>().add(UpdateSeatSelection(seats)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (state.selectedSeats.isNotEmpty)
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff1a1d20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                                  builder: (_) => BlocProvider.value(
                                    value: context.read<CheckoutBloc>(),
                                    child: ContextualCheckoutSheet(
                                      destinationBoundary: _toController.text,
                                      baseSeatPrice: ((state.selectedManifest?['price_ngn'] as num?) ?? 12000.0).toDouble(),
                                      selectedSeats: state.selectedSeats,
                                    ),
                                  ),
                                );
                              },
                              child: const Text("PROCEED TO NATIVE CHECKOUT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ] else if (state is! CheckoutFailureReversal) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff0b845c), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: () => context.read<CheckoutBloc>().add(TriggerParallelSearch()),
                            child: state is CheckoutQueryingWorkers
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("SEARCH DISPATCHER ROUTES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 30),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumWalletHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      decoration: const BoxDecoration(
        color: Color(0xff0b845c),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Card(
        color: const Color(0xff116649),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("WALLET BALANCE", style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                    child: Text("Active Secure", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text("₦${_walletBalance.toStringAsFixed(2)}", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVasServiceGrid() {
    final List<Map<String, dynamic>> services = [
      {"title": "📱 Airtime Vending", "color": Colors.green.shade50, "borderColor": Colors.green.shade200, "action": () => _showNativeAirtimeSheet()},
      {"title": "⚡ Pay Electricity", "color": Colors.orange.shade50, "borderColor": Colors.orange.shade200, "action": () => _showNativeElectricitySheet()},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 2.2),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final s = services[index];
        return InkWell(
          onTap: s['action'],
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: s['color'],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: s['borderColor'], width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(s['title'], style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xff1a1d20))),
          ),
        );
      },
    );
  }

  Widget _buildSearchFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 16, offset: const Offset(0, 6))]),
      child: Column(
        children: [
          TextField(
            readOnly: true,
            controller: TextEditingController(text: 'Lagos (Jibowu Terminus)'),
            decoration: const InputDecoration(labelText: 'From', border: InputBorder.none, prefixIcon: Icon(Icons.radio_button_checked, color: Color(0xff0b845c))),
          ),
          const Divider(height: 12),
          TextField(
            controller: _toController,
            decoration: const InputDecoration(labelText: 'To (Destination State)', border: InputBorder.none, prefixIcon: Icon(Icons.location_on, color: Colors.orange)),
          ),
          const Divider(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Padding(
              padding: EdgeInsets.only(left: 10.0),
              child: Icon(Icons.calendar_month_rounded, color: Colors.blueAccent),
            ),
            title: Text("Departure Date", style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
            subtitle: Text("${_travelDate.day}/${_travelDate.month}/${_travelDate.year}", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
            onTap: () async {
              DateTime? picked = await showDatePicker(context: context, initialDate: _travelDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 60)));
              if (picked != null) setState(() => _travelDate = picked);
            },
          ),
        ],
      ),
    );
  }

  void _showNativeAirtimeSheet() {
    final phoneCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedOperator = "MTN";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 18),
                  Text("Airtime Top-Up", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 18),
                  
                  Text("SELECT NETWORK OPERATOR", style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ["MTN", "Airtel", "Glo", "9mobile"].map((op) {
                      bool isSel = selectedOperator == op;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedOperator = op),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xff0b845c) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSel ? const Color(0xff0b845c) : Colors.grey.shade300),
                          ),
                          child: Text(op, style: TextStyle(color: isSel ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "Mobile Number", hintText: "0803...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 14),
                  TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Amount (₦)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff0b845c), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                        if (phoneCtrl.text.isNotEmpty && amt > 0) {
                          Navigator.pop(context);
                          _showProcessingOverlay();
                          final success = await _vasRepo.purchaseAirtime(phone: phoneCtrl.text, amountKobo: (amt * 100).toInt(), network: selectedOperator);
                          Navigator.pop(this.context);
                          
                          if (success) {
                            setState(() => _walletBalance -= amt);
                            _showReceiptModal(title: "Airtime Vending Successful", sub: "Network transaction cleared safely via Flutterwave.", items: {
                              "Operator": selectedOperator,
                              "Phone Number": phoneCtrl.text,
                              "Vended Amount": "₦${amt.toStringAsFixed(2)}",
                              "Status": "Settled"
                            });
                          } else {
                            _showReceiptModal(title: "Transaction Failed", sub: "Render api pipeline connection timeout occurred.", items: {
                              "Status": "Failed/Reversed",
                              "Details": "Downstream endpoint latency anomaly detected."
                            }, isError: true);
                          }
                        }
                      },
                      child: Text("PURCHASE ${selectedOperator.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNativeElectricitySheet() {
    final meterCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 18),
              Text("Prepaid Utility Settlement", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 18),
              TextField(controller: meterCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Meter Number", hintText: "Enter 11-digit number", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 14),
              TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Utility Amount (₦)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffe65100), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                    if (meterCtrl.text.isNotEmpty && amt > 0) {
                      Navigator.pop(context);
                      _showProcessingOverlay();
                      final response = await _vasRepo.payElectricity(meterNumber: meterCtrl.text, amountKobo: (amt * 100).toInt(), disco: "AEDC");
                      Navigator.pop(this.context);
                      
                      if (response != null) {
                        setState(() => _walletBalance -= amt);
                        _showReceiptModal(title: "DisCo Utility Cleared", sub: "Token generated natively via standard DisCo infrastructure.", items: {
                          "Utility DisCo": "AEDC Prepaid",
                          "Meter Number": meterCtrl.text,
                          "Token Generated": "4820-1940-2048-1102",
                          "Energy Allocated": "42.5 kWh",
                          "Settled Value": "₦${amt.toStringAsFixed(2)}"
                        });
                      } else {
                        _showReceiptModal(title: "DisCo Endpoint Error", sub: "Utility pipeline failed to verify meter specifications.", items: {
                          "Meter Target": meterCtrl.text,
                          "Resolution": "Reversal fired down onto primary wallet pool."
                        }, isError: true);
                      }
                    }
                  },
                  child: const Text("VEND PREPAID POWER", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _showProcessingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xff0b845c))),
    );
  }

  void _showBookingConfirmation(BuildContext context, CheckoutSuccess state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: Color(0xff0b845c), size: 56),
              const SizedBox(height: 12),
              Text('Booking Confirmed!',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 20, fontWeight: FontWeight.w900,
                      color: const Color(0xff0d1b16))),
              const SizedBox(height: 4),
              Text(state.operatorName,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: const Color(0xff6b8078))),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  children: [
                    _receiptRow('Route',
                        '\${state.origin} → \${state.destination}'),
                    _receiptRow('Date', state.departureDate),
                    _receiptRow('Seats', state.seats.join(', ')),
                    _receiptRow('Booking ID', state.bookingId),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0b845c),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () => Navigator.pop(context),
                  child: Text('Done',
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold)),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xff0d1b16),
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  void _showReceiptModal({required String title, required String sub, required Map<String, String> items, bool isError = false}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: isError ? Colors.red.shade700 : const Color(0xff0b845c),
                size: 54,
              ),
              const SizedBox(height: 12),
              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xff1a1d20))),
              const SizedBox(height: 4),
              Text(sub, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  children: items.entries.map<Widget>((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                          Text(entry.value, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xff1a1d20), fontWeight: FontWeight.w900)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff1a1d20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CLOSE VOUCHER RECEIPT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
