import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

class PinDialog extends StatefulWidget {
  final String expectedPin;
  final Function(String) onVerify;
  final String title;

  const PinDialog({
    super.key,
    required this.expectedPin,
    required this.onVerify,
    this.title = 'Enter Admin PIN',
  });

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _controller.text;
    if (pin == widget.expectedPin) {
      widget.onVerify(pin);
      Navigator.of(context).pop();
    } else {
      setState(() {
        _error = 'Incorrect PIN';
      });
      _controller.clear();
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.darkSurface,
      title: Text(
        widget.title,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 8,
              color: AppColors.textPrimary,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              errorText: _error,
              errorStyle: const TextStyle(color: AppColors.deniedRed),
            ),
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_error != null) {
                setState(() => _error = null);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Verify'),
        ),
      ],
    );
  }
}

Future<bool?> showPinDialog(
  BuildContext context, {
  required String expectedPin,
  required Function(String) onVerify,
  String title = 'Enter Admin PIN',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => PinDialog(
      expectedPin: expectedPin,
      onVerify: onVerify,
      title: title,
    ),
  );
  return result ?? false;
}