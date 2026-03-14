import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/shared/widgets/fees_feature_guard.dart';

// ==================== COLOR CONSTANTS ====================
const Color kPrimaryColor = Color(0xFF2A2E45);
const Color kSecondaryColor = Color(0xFF6C5CE7);
const Color kAccentColor = Color(0xFF00B894);
const Color kSoftPurple = Color(0xFFA29BFE);
const Color kSoftPink = Color(0xFFFF7675);
const Color kSoftOrange = Color(0xFFFDCB6E);
const Color kSoftBlue = Color(0xFF74B9FF);
const Color kBackgroundStart = Color(0xFFE8EEF9);
const Color kBackgroundEnd = Color(0xFFF5F0FF);
const Color kCardColor = Colors.white;
const Color kTextPrimary = Color(0xFF2D3436);
const Color kTextSecondary = Color(0xFF636E72);
const Color kSuccessColor = Color(0xFF059669);
const Color kWarningColor = Color(0xFFF59E0B);
const Color kErrorColor = Color(0xFFEF4444);

class ParentFeePaymentScreen extends StatefulWidget {
  final Map<String, dynamic> fee;

  const ParentFeePaymentScreen({Key? key, required this.fee}) : super(key: key);

  @override
  State<ParentFeePaymentScreen> createState() => _FeePaymentScreenState();
}

class _FeePaymentScreenState extends State<ParentFeePaymentScreen> {
  // Payment method selection
  int _selectedPaymentMethod = 0; // 0: Credit Card, 1: Bank Transfer, 2: Cash

  // Payment form controllers
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  // Bank transfer controllers
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _referenceNumberController = TextEditingController();

  // Form visibility
  bool _showPaymentForm = true;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 0,
      'icon': Icons.credit_card_rounded,
      'title': 'Credit / Debit Card',
      'subtitle': 'Pay with Visa, Mastercard, Amex',
      'color': kAccentColor,
    },
    {
      'id': 1,
      'icon': Icons.account_balance_rounded,
      'title': 'Bank Transfer',
      'subtitle': 'Direct transfer from your bank',
      'color': kSecondaryColor,
    },
    {
      'id': 2,
      'icon': Icons.payments_rounded,
      'title': 'Cash',
      'subtitle': 'Pay at school office (generate receipt)',
      'color': kSoftOrange,
    },
  ];

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _referenceNumberController.dispose();
    super.dispose();
  }

  // Helper method to get initials safely
  String _getInitials(String name) {
    if (name.isEmpty) return '';
    List<String> parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  // Safe extraction methods
  String _getChildName() {
    return widget.fee['childName'] ?? 'Unknown';
  }

  String _getClassName() {
    return widget.fee['className'] ?? 'Not Assigned';
  }

  double _getTotalFee() {
    final value = widget.fee['totalFee'];
    if (value is num) return value.toDouble();
    return 0.0;
  }

  double _getPaidAmount() {
    final value = widget.fee['paidAmount'];
    if (value is num) return value.toDouble();
    return 0.0;
  }

  double _getDueAmount() {
    final value = widget.fee['dueAmount'];
    if (value is num) return value.toDouble();
    return 0.0;
  }

  String _getDueDate() {
    return widget.fee['dueDate'] ?? 'N/A';
  }

  String _getFeeType() {
    return widget.fee['feeType'] ?? 'Tuition Fee';
  }

  double _getLateFee() {
    final value = widget.fee['lateFee'];
    if (value is num) return value.toDouble();
    return 0.0;
  }

  void _processPayment() {
    // Validate based on payment method
    if (_selectedPaymentMethod == 0) {
      // Credit card validation
      if (_cardNumberController.text.isEmpty ||
          _cardHolderController.text.isEmpty ||
          _expiryDateController.text.isEmpty ||
          _cvvController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all card details'),
            backgroundColor: kErrorColor,
          ),
        );
        return;
      }

      if (_cardNumberController.text.length < 16) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid card number'),
            backgroundColor: kErrorColor,
          ),
        );
        return;
      }
    } else if (_selectedPaymentMethod == 1) {
      // Bank transfer validation
      if (_bankNameController.text.isEmpty ||
          _accountNumberController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all bank transfer details'),
            backgroundColor: kErrorColor,
          ),
        );
        return;
      }
    }

    setState(() {
      _isProcessing = true;
    });

    // Simulate payment processing
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      String successMessage = '';
      switch (_selectedPaymentMethod) {
        case 0:
          successMessage =
              'Your card payment of \$${_getDueAmount().toStringAsFixed(2)} has been processed successfully.';
          break;
        case 1:
          successMessage =
              'Bank transfer initiated. Please complete the transfer using the provided details.';
          break;
        case 2:
          successMessage =
              'Payment receipt generated. Please pay \$${_getDueAmount().toStringAsFixed(2)} at the school office.';
          break;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                _selectedPaymentMethod == 2
                    ? Icons.receipt_rounded
                    : Icons.check_circle_rounded,
                color: _selectedPaymentMethod == 2
                    ? kWarningColor
                    : kSuccessColor,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _selectedPaymentMethod == 2
                      ? 'Payment Receipt'
                      : 'Payment Successful',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(successMessage),
              const SizedBox(height: 16),
              if (_selectedPaymentMethod == 1) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kSoftBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bank Details:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('Bank:', 'First National Bank'),
                      _buildDetailRow('Account:', '1234567890'),
                      _buildDetailRow(
                        'Reference:',
                        _referenceNumberController.text.isNotEmpty
                            ? _referenceNumberController.text
                            : 'N/A',
                      ),
                    ],
                  ),
                ),
              ] else if (_selectedPaymentMethod == 2) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kSoftOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Receipt Details:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Receipt No:',
                        'RCP-${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8)}',
                      ),
                      _buildDetailRow(
                        'Amount:',
                        '\$${_getDueAmount().toStringAsFixed(2)}',
                      ),
                      _buildDetailRow('Due Date:', _getDueDate()),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              style: TextButton.styleFrom(
                foregroundColor: _selectedPaymentMethod == 2
                    ? kWarningColor
                    : kSuccessColor,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: kTextSecondary, fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String childName = _getChildName();
    final String className = _getClassName();
    final double totalFee = _getTotalFee();
    final double paidAmount = _getPaidAmount();
    final double dueAmount = _getDueAmount();
    final double lateFee = _getLateFee();
    final double totalPayable = dueAmount + lateFee;

    return FeesFeatureGuard(
      child: Scaffold(
        backgroundColor: kBackgroundEnd,
        appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kPrimaryColor, kSecondaryColor],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
            splashRadius: 20,
            tooltip: 'Go back',
          ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: kAccentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.payment_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'SECURE PAYMENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Make Payment',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        toolbarHeight: 80,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.help_outline_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () {
                _showHelpDialog();
              },
              splashRadius: 20,
              tooltip: 'Help',
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Child Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Child Avatar
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [kSoftPurple, kSoftBlue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(childName),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  childName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: kTextPrimary,
                                  ),
                                ),
                                Text(
                                  className,
                                  style: TextStyle(
                                    color: kTextSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: lateFee > 0
                                  ? kErrorColor.withOpacity(0.1)
                                  : kSuccessColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  lateFee > 0
                                      ? Icons.warning_rounded
                                      : Icons.check_circle_rounded,
                                  color: lateFee > 0
                                      ? kErrorColor
                                      : kSuccessColor,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  lateFee > 0 ? 'Late Fee' : 'On Time',
                                  style: TextStyle(
                                    color: lateFee > 0
                                        ? kErrorColor
                                        : kSuccessColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Payment Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow('Fee Type', _getFeeType(), kTextPrimary),
                      _buildInfoRow(
                        'Total Fee',
                        '\$${totalFee.toStringAsFixed(2)}',
                        kTextPrimary,
                      ),
                      _buildInfoRow(
                        'Paid Amount',
                        '\$${paidAmount.toStringAsFixed(2)}',
                        kSuccessColor,
                      ),
                      if (lateFee > 0)
                        _buildInfoRow(
                          'Late Fee',
                          '\$${lateFee.toStringAsFixed(2)}',
                          kErrorColor,
                        ),
                      const Divider(height: 30),
                      _buildInfoRow(
                        'Payable Now',
                        '\$${totalPayable.toStringAsFixed(2)}',
                        kAccentColor,
                        isTotal: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Payment Method Selection
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Payment Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(_paymentMethods.length, (index) {
                        final method = _paymentMethods[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _PaymentMethodCard(
                            icon: method['icon'],
                            title: method['title'],
                            subtitle: method['subtitle'],
                            selected: _selectedPaymentMethod == method['id'],
                            color: method['color'],
                            onTap: () {
                              setState(() {
                                _selectedPaymentMethod = method['id'];
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Payment Form based on selected method
                if (_selectedPaymentMethod == 0)
                  _buildCreditCardForm()
                else if (_selectedPaymentMethod == 1)
                  _buildBankTransferForm()
                else if (_selectedPaymentMethod == 2)
                  _buildCashPaymentForm(),

                const SizedBox(height: 30),

                // Pay Button
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _selectedPaymentMethod == 0
                            ? kAccentColor
                            : (_selectedPaymentMethod == 1
                                  ? kSecondaryColor
                                  : kSoftOrange),
                        (_selectedPaymentMethod == 0
                                ? kAccentColor
                                : (_selectedPaymentMethod == 1
                                      ? kSecondaryColor
                                      : kSoftOrange))
                            .withOpacity(0.8),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_selectedPaymentMethod == 0
                                    ? kAccentColor
                                    : (_selectedPaymentMethod == 1
                                          ? kSecondaryColor
                                          : kSoftOrange))
                                .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isProcessing ? null : _processPayment,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: _isProcessing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _selectedPaymentMethod == 0
                                    ? "Pay with Card"
                                    : (_selectedPaymentMethod == 1
                                          ? "Generate Transfer Details"
                                          : "Generate Receipt"),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, kSoftBlue.withOpacity(0.3)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kAccentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.help_rounded, color: kAccentColor, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment Help',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose your preferred payment method and follow the instructions. For any issues, contact the school finance office.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kTextSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildHelpItem(
                    Icons.credit_card_rounded,
                    'Card',
                    kAccentColor,
                  ),
                  _buildHelpItem(
                    Icons.account_balance_rounded,
                    'Bank',
                    kSecondaryColor,
                  ),
                  _buildHelpItem(Icons.payments_rounded, 'Cash', kSoftOrange),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Text('Got it'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: kTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCreditCardForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kAccentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.credit_card_rounded,
                  color: kAccentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Card Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Card Preview
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kPrimaryColor, kSecondaryColor],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  left: 16,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 25,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 40,
                        height: 25,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 16,
                  child: Text(
                    _cardNumberController.text.isEmpty
                        ? '**** **** **** ****'
                        : _formatCardNumber(_cardNumberController.text),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _cardHolderController.text.isEmpty
                            ? 'CARD HOLDER'
                            : _cardHolderController.text.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _expiryDateController.text.isEmpty
                            ? 'MM/YY'
                            : _expiryDateController.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            maxLength: 16,
            onChanged: (value) {
              setState(() {});
            },
            decoration: InputDecoration(
              labelText: 'Card Number',
              hintText: '1234 5678 9012 3456',
              prefixIcon: Icon(
                Icons.credit_card,
                color: kAccentColor,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kAccentColor, width: 2),
              ),
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cardHolderController,
            onChanged: (value) {
              setState(() {});
            },
            decoration: InputDecoration(
              labelText: 'Card Holder Name',
              hintText: 'John Doe',
              prefixIcon: Icon(Icons.person, color: kAccentColor, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kAccentColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _expiryDateController,
                  keyboardType: TextInputType.datetime,
                  maxLength: 5,
                  onChanged: (value) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'Expiry Date',
                    hintText: 'MM/YY',
                    prefixIcon: Icon(
                      Icons.calendar_today,
                      color: kAccentColor,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: kAccentColor, width: 2),
                    ),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _cvvController,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    prefixIcon: Icon(Icons.lock, color: kAccentColor, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: kAccentColor, width: 2),
                    ),
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCardNumber(String number) {
    if (number.length < 4) return number;
    String formatted = '';
    for (int i = 0; i < number.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += number[i];
    }
    return formatted;
  }

  Widget _buildBankTransferForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kSecondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  color: kSecondaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Bank Transfer Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // School Bank Account Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kSecondaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kSecondaryColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance,
                      color: kSecondaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'School Bank Account:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTransferDetail('Bank Name:', 'First National Bank'),
                _buildTransferDetail(
                  'Account Name:',
                  'Kobac School Fees Account',
                ),
                _buildTransferDetail('Account Number:', '1234567890'),
                _buildTransferDetail('Routing Number:', '021000021'),
                _buildTransferDetail('SWIFT Code:', 'FNBBUS33'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Your Bank Details
          const Text(
            'Your Bank Details',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _bankNameController,
            decoration: InputDecoration(
              labelText: 'Your Bank Name',
              hintText: 'Enter your bank name',
              prefixIcon: Icon(
                Icons.account_balance,
                color: kSecondaryColor,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kSecondaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _accountNumberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Your Account Number',
              hintText: 'Enter your account number',
              prefixIcon: Icon(Icons.numbers, color: kSecondaryColor, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kSecondaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _referenceNumberController,
            decoration: InputDecoration(
              labelText: 'Reference Number (Optional)',
              hintText: 'Enter reference number',
              prefixIcon: Icon(Icons.receipt, color: kSecondaryColor, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kSecondaryColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: kTextSecondary, fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCashPaymentForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kSoftOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.payments_rounded,
                  color: kSoftOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Cash Payment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kSoftOrange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kSoftOrange.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: kSoftOrange.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.info_rounded,
                        color: kSoftOrange,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Cash Payment Instructions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInstruction(
                  '1. Generate receipt by clicking the button below',
                ),
                _buildInstruction(
                  '2. Take the receipt to the school finance office',
                ),
                _buildInstruction('3. Pay the exact amount in cash'),
                _buildInstruction('4. Get your official payment receipt'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Amount Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kSoftOrange.withOpacity(0.1), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kSoftOrange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      color: kSoftOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Amount to Pay:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  '\$${(_getDueAmount() + _getLateFee()).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: kSoftOrange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    Color color, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: kTextSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? color : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: selected ? color.withOpacity(0.05) : Colors.transparent,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: selected ? color : kTextSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: selected ? color : kTextPrimary,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: selected
                            ? color.withOpacity(0.8)
                            : kTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
