import 'package:flutter/material.dart';
import '../../core/services/pin_service.dart';

class PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlock;

  const PinLockScreen({
    super.key,
    required this.onUnlock,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final PinService _pinService = PinService();
  final List<String> _enteredPin = [];
  String? _errorMessage;
  int _failedAttempts = 0;
  bool _isVerifying = false;

  void _onNumberPressed(String number) {
    if (_enteredPin.length >= 6) return;
    if (_isVerifying) return;

    setState(() {
      _enteredPin.add(number);
      _errorMessage = null;
    });

    if (_enteredPin.length == 6) {
      _verifyPin();
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty && !_isVerifying) {
      setState(() {
        _enteredPin.removeLast();
        _errorMessage = null;
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isVerifying = true;
    });

    final pin = _enteredPin.join('');
    final isValid = await _pinService.verifyPin(pin);

    if (isValid) {
      widget.onUnlock();
    } else {
      setState(() {
        _failedAttempts++;
        _errorMessage = 'Incorrect PIN. Try again.';
        _enteredPin.clear();
        _isVerifying = false;
      });

      if (_failedAttempts >= 5) {
        // Show warning after 5 failed attempts
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Too many failed attempts. Please wait before trying again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Enter PIN',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your 6-digit PIN to continue',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // PIN Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < _enteredPin.length
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // Number Pad
                  Column(
                    children: [
                      _buildNumberRow(['1', '2', '3']),
                      const SizedBox(height: 16),
                      _buildNumberRow(['4', '5', '6']),
                      const SizedBox(height: 16),
                      _buildNumberRow(['7', '8', '9']),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 80, height: 80), // Spacer
                          _buildNumberButton('0'),
                          _buildDeleteButton(),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: numbers.map((num) => _buildNumberButton(num)).toList(),
    );
  }

  Widget _buildNumberButton(String number) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onNumberPressed(number),
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onDeletePressed,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.backspace,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}





