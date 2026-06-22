import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

class BusSearchPage extends StatefulWidget {
  const BusSearchPage({super.key});

  @override
  State<BusSearchPage> createState() => _BusSearchPageState();
}

class _BusSearchPageState extends State<BusSearchPage> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _passengers = 1;

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _search() {
    if (_originController.text.trim().isEmpty || _destinationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter origin and destination')),
      );
      return;
    }
    
    // Pass parameters via extra or query to results page
    context.push(
      '/travel/bus/results',
      extra: {
        'origin': _originController.text.trim(),
        'destination': _destinationController.text.trim(),
        'date': _selectedDate,
        'passengers': _passengers,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Bus'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: AppCard.standard(),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: _originController,
                    decoration: AppInput.field(
                      label: 'From (City/Terminal)',
                      prefix: const Icon(Icons.trip_origin, color: AppColors.brand),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _destinationController,
                    decoration: AppInput.field(
                      label: 'To (City/Terminal)',
                      prefix: const Icon(Icons.location_on, color: AppColors.error),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppColors.textSecondary),
                          const SizedBox(width: 16),
                          Text(
                            DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                            style: AppText.body(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Passengers', style: AppText.body()),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (_passengers > 1) setState(() => _passengers--);
                        },
                      ),
                      Text('$_passengers', style: AppText.h3()),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          if (_passengers < 5) setState(() => _passengers++);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _search,
              child: const Text('Search Available Buses'),
            ),
          ],
        ),
      ),
    );
  }
}
