import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/pin_service.dart';
import '../../data/repositories/transaction_repository.dart';
import 'onboarding_screen.dart';
import 'pin_lock_screen.dart';
import 'main_navigation.dart';

class AppWrapper extends ConsumerStatefulWidget {
  const AppWrapper({super.key});

  @override
  ConsumerState<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends ConsumerState<AppWrapper> {
  final PinService _pinService = PinService();
  bool _isChecking = true;
  bool _showOnboarding = false;
  bool _showPinLock = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    // Check if onboarding is needed (no transactions)
    final transactionRepo = TransactionRepository();
    final transactions = await transactionRepo.getAllTransactions(limit: 1);
    
    final hasPin = await _pinService.hasPin();
    final shouldShowLock = hasPin ? await _pinService.shouldShowLock() : false;

    if (mounted) {
      setState(() {
        _showOnboarding = transactions.isEmpty;
        _showPinLock = hasPin && shouldShowLock;
        _isChecking = false;
      });
    }
  }

  void _onOnboardingComplete() {
    setState(() {
      _showOnboarding = false;
    });
    // Check PIN after onboarding
    _checkPinLock();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-check state when returning to this screen
    if (!_isChecking && !_showOnboarding && !_showPinLock) {
      _checkInitialState();
    }
  }

  void _onPinUnlock() {
    setState(() {
      _showPinLock = false;
    });
  }

  Future<void> _checkPinLock() async {
    final hasPin = await _pinService.hasPin();
    final shouldShowLock = hasPin ? await _pinService.shouldShowLock() : false;
    
    if (mounted) {
      setState(() {
        _showPinLock = shouldShowLock;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showOnboarding) {
      return OnboardingScreen(onComplete: _onOnboardingComplete);
    }

    if (_showPinLock) {
      return PinLockScreen(onUnlock: _onPinUnlock);
    }

    return const MainNavigation();
  }
}

