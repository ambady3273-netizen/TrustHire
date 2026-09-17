import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme.dart';

// ─────────────────────────────────────────────────────────────
// PhoneLoginScreen — Firebase Phone Auth with OTP
// ─────────────────────────────────────────────────────────────

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() =>
      _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();
  final _formKey   = GlobalKey<FormState>();

  bool   _codeSent   = false;
  bool   _loading    = false;
  String _verificationId = '';
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final phone = '+91${_phoneCtrl.text.trim()}';

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential cred) async {
        // Auto-verified on Android
        await _signInWithCred(cred);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          setState(() {
            _error   = e.message ?? 'Verification failed.';
            _loading = false;
          });
        }
      },
      codeSent: (String vId, int? resendToken) {
        if (mounted) {
          setState(() {
            _verificationId = vId;
            _codeSent       = true;
            _loading        = false;
          });
        }
      },
      codeAutoRetrievalTimeout: (String vId) {
        _verificationId = vId;
      },
    );
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit OTP.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final cred = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode:        _otpCtrl.text.trim(),
    );
    await _signInWithCred(cred);
  }

  Future<void> _signInWithCred(PhoneAuthCredential cred) async {
    try {
      await FirebaseAuth.instance.signInWithCredential(cred);
      // AuthGate handles navigation automatically on sign-in
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context, '/authGate', (r) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _error   = e.message ?? 'Invalid OTP.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Login with Phone')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Icon(Icons.phone_android,
                  size: 56, color: AppColors.teal),
              const SizedBox(height: 16),
              Text(
                _codeSent
                    ? 'Enter the 6-digit OTP sent to\n+91 ${_phoneCtrl.text}'
                    : 'Enter your mobile number to receive OTP',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink),
              ),
              const SizedBox(height: 24),

              if (!_codeSent) ...[
                // ── Phone field ────────────────────────────
                TextFormField(
                  controller:  _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength:   10,
                  decoration: InputDecoration(
                    labelText:   'Mobile Number',
                    prefixText:  '+91 ',
                    prefixIcon:  const Icon(Icons.phone_outlined),
                    filled:      true,
                    fillColor:   Colors.white,
                    border:      OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length != 10) {
                      return 'Enter a valid 10-digit mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width:  double.infinity,
                  height: 52,
                  child:  ElevatedButton(
                    onPressed: _loading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Send OTP',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ] else ...[
                // ── OTP field ──────────────────────────────
                TextFormField(
                  controller:   _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength:    6,
                  textAlign:    TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 12),
                  decoration: InputDecoration(
                    hintText:  '000000',
                    filled:    true,
                    fillColor: Colors.white,
                    border:    OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width:  double.infinity,
                  height: 52,
                  child:  ElevatedButton(
                    onPressed: _loading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Verify OTP',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                              _codeSent = false;
                              _otpCtrl.clear();
                              _error = null;
                            }),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Change number'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.mute),
                  ),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:        AppColors.coralLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.coral, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color:    AppColors.coral,
                                fontSize: 12.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
