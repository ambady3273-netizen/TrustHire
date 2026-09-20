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

  bool    _codeSent       = false;
  bool    _loading        = false;
  String  _verificationId = '';
  String? _error;
  bool    _showSetupBanner = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  /// Detect whether the error is the "provider disabled" error
  bool _isProviderDisabled(String? msg) {
    final m = (msg ?? '').toLowerCase();
    return m.contains('disabled') ||
        m.contains('not allowed') ||
        m.contains('operation-not-allowed');
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading         = true;
      _error           = null;
      _showSetupBanner = false;
    });

    final phone = '+91${_phoneCtrl.text.trim()}';

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential cred) async {
        await _signInWithCred(cred);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        final isDisabled = _isProviderDisabled(e.message);
        setState(() {
          _error           = isDisabled ? null : (e.message ?? 'Verification failed.');
          _showSetupBanner = isDisabled;
          _loading         = false;
        });
      },
      codeSent: (String vId, int? resendToken) {
        if (!mounted) return;
        setState(() {
          _verificationId = vId;
          _codeSent       = true;
          _loading        = false;
        });
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
      // AuthGate handles routing automatically — no navigation needed.
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

              // ── Setup banner — shown when phone auth is disabled ──
              if (_showSetupBanner) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF0A500)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.settings_outlined,
                              color: Color(0xFFF0A500), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Phone Login Not Enabled',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB07800),
                                fontSize: 14),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'To enable Phone OTP login, follow these steps:',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7A5200),
                            fontSize: 13),
                      ),
                      SizedBox(height: 8),
                      _Step(
                          n: '1',
                          text:
                              'Go to console.firebase.google.com'),
                      _Step(
                          n: '2',
                          text:
                              'Select project: trusthire-fa302'),
                      _Step(
                          n: '3',
                          text:
                              'Authentication → Sign-in method'),
                      _Step(
                          n: '4',
                          text:
                              'Click "Phone" → toggle Enable → Save'),
                      SizedBox(height: 8),
                      Text(
                        'Then come back and try again.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7A5200),
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

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
                TextFormField(
                  controller:   _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength:    10,
                  decoration: InputDecoration(
                    labelText:  'Mobile Number',
                    prefixText: '+91 ',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    filled:     true,
                    fillColor:  Colors.white,
                    border:     OutlineInputBorder(
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
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Send OTP',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ] else ...[
                TextFormField(
                  controller:   _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength:    6,
                  textAlign:    TextAlign.center,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 14),
                  decoration: InputDecoration(
                    hintText:  '------',
                    filled:    true,
                    fillColor: Colors.white,
                    border:    OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Verify & Login',
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
                              _error    = null;
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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

/// Step widget used in the setup banner.
class _Step extends StatelessWidget {
  final String n;
  final String text;
  const _Step({required this.n, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color:  Color(0xFFF0A500),
              shape:  BoxShape.circle,
            ),
            child: Center(
              child: Text(n,
                  style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   11,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12.5, color: Color(0xFF7A5200))),
          ),
        ],
      ),
    );
  }
}
