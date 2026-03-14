import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';

/// Wraps a fee/payment screen. If the school has fees disabled, shows a message and pops.
/// Use for AdminFeesScreen, PaymentsScreen, StudentFeesScreen, etc.
class FeesFeatureGuard extends StatelessWidget {
  final Widget child;

  const FeesFeatureGuard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final enabled = context.watch<AuthProvider>().feesEnabled;
    if (enabled) return child;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.payments_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Fees and payments are not enabled for your school.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
