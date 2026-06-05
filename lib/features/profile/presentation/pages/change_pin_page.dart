import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/repositories/profile_repository.dart';

/// Three-step flow:
/// 1. Enter current PIN
/// 2. Enter new PIN
/// 3. Confirm new PIN
class ChangePinPage extends StatefulWidget {
  const ChangePinPage({super.key});

  @override
  State<ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends State<ChangePinPage>
    with TickerProviderStateMixin {
  static const _brand = Color(0xff0b845c);
  static const _pinLength = 6;

  final _repo = ProfileRepository();

  // Step 0 = enter current PIN, 1 = enter new PIN, 2 = confirm new PIN
  int _step = 0;
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';
  bool _loading = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  String get _activePin {
    if (_step == 0) return _currentPin;
    if (_step == 1) return _newPin;
    return _confirmPin;
  }

  void _setActivePin(String v) {
    setState(() {
      if (_step == 0) {
        _currentPin = v;
      } else if (_step == 1) {
        _newPin = v;
      } else {
        _confirmPin = v;
      }
    });
  }

  void _onKey(String digit) {
    final pin = _activePin;
    if (pin.length >= _pinLength) return;
    final updated = pin + digit;
    _setActivePin(updated);
    if (updated.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 150), _onPinComplete);
    }
  }

  void _onDelete() {
    final pin = _activePin;
    if (pin.isEmpty) return;
    _setActivePin(pin.substring(0, pin.length - 1));
  }

  Future<void> _onPinComplete() async {
    if (_step == 0) {
      // Move to new PIN entry
      setState(() => _step = 1);
      return;
    }

    if (_step == 1) {
      // Validate new PIN is different
      if (_newPin == _currentPin) {
        _shake();
        _showError('New PIN must be different from current PIN');
        setState(() => _newPin = '');
        return;
      }
      setState(() => _step = 2);
      return;
    }

    // Step 2: confirm
    if (_confirmPin != _newPin) {
      _shake();
      _showError('PINs do not match. Please try again.');
      setState(() {
        _confirmPin = '';
        _newPin = '';
        _step = 1;
      });
      return;
    }

    // All good — call API
    setState(() => _loading = true);
    final result = await _repo.changePin(
      currentPin: _currentPin,
      newPin: _newPin,
      confirmPin: _confirmPin,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      _showSuccess();
    } else {
      _shake();
      _showError(result['message'] as String);
      // Reset to step 0 on failure so user can retry current PIN
      setState(() {
        _step = 0;
        _currentPin = '';
        _newPin = '';
        _confirmPin = '';
      });
    }
  }

  void _shake() {
    _shakeCtrl.forward(from: 0);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xffe8f5f0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: _brand, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'PIN Changed!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xff1a1a1a),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your transaction PIN has been updated successfully.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // dialog
                  Navigator.of(context).pop(); // page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _stepTitle {
    if (_step == 0) return 'Enter Current PIN';
    if (_step == 1) return 'Enter New PIN';
    return 'Confirm New PIN';
  }

  String get _stepSubtitle {
    if (_step == 0) return 'Enter your existing 6-digit transaction PIN';
    if (_step == 1) return 'Choose a new 6-digit PIN';
    return 'Re-enter your new PIN to confirm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _brand,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          'Change PIN',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () {
            if (_step > 0) {
              setState(() {
                _step--;
                if (_step == 0) _currentPin = '';
                if (_step == 1) _newPin = '';
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : Column(
              children: [
                // Step indicator
                Padding(
                  padding: const EdgeInsets.only(top: 32, bottom: 8),
                  child: _StepIndicator(step: _step),
                ),
                const SizedBox(height: 24),
                Text(
                  _stepTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xff1a1a1a),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _stepSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                // PIN dots
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) {
                    final offset =
                        _shakeAnim.value * 8 * ((_shakeAnim.value * 4).floor() % 2 == 0 ? 1 : -1);
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    );
                  },
                  child: _PinDots(filled: _activePin.length, total: _pinLength),
                ),
                const Spacer(),
                // Keypad
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: _Keypad(onKey: _onKey, onDelete: _onDelete),
                ),
                const SizedBox(height: 36),
              ],
            ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i == step;
        final done = i < step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: done || active
                ? const Color(0xff0b845c)
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _PinDots extends StatelessWidget {
  final int filled;
  final int total;
  const _PinDots({required this.filled, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isFilled = i < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? const Color(0xff0b845c) : Colors.transparent,
            border: Border.all(
              color: isFilled ? const Color(0xff0b845c) : Colors.grey.shade400,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}

class _Keypad extends StatelessWidget {
  final void Function(String) onKey;
  final VoidCallback onDelete;
  const _Keypad({required this.onKey, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];
    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: row.map((k) {
              if (k.isEmpty) return const SizedBox(width: 72, height: 60);
              if (k == 'del') {
                return _KeyButton(
                  onTap: onDelete,
                  child: const Icon(Icons.backspace_outlined,
                      size: 22, color: Color(0xff1a1a1a)),
                );
              }
              return _KeyButton(
                onTap: () => onKey(k),
                child: Text(
                  k,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff1a1a1a),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _KeyButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xfff4f6f5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(child: child),
      ),
    );
  }
}
