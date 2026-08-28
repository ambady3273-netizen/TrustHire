import 'package:flutter/material.dart';
import '../theme.dart';

class RootMenuScreen extends StatelessWidget {
  const RootMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Onboarding & KYC',
        '4 screens · signup to verified',
        '/splash',
        Icons.verified_user_outlined,
      ),
      (
        'Job Seeker flow',
        '4 screens · discover to get paid',
        '/jobFeed',
        Icons.search_rounded,
      ),
      (
        'Employer flow',
        '4 screens · post to release escrow',
        '/postJob',
        Icons.storefront_outlined,
      ),
      (
        'Admin dashboard',
        '2 screens · fraud & verification',
        '/adminFraud',
        Icons.shield_outlined,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/logo_mark.png',
                height: 34,
                width: 34,
              ),

              const SizedBox(height: 14),

              const Text(
                'TrustHire',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'UI/UX prototype — pick a flow to walk through it.',
                style: TextStyle(
                  color: Color(0xFFC9D2E6),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 28),

              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 14),

                  itemBuilder: (context, i) {
                    final item = items[i];

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),

                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          item.$3,
                        );
                      },

                      child: Container(
                        padding: const EdgeInsets.all(18),

                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.08,
                          ),

                          borderRadius:
                              BorderRadius.circular(16),

                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: 0.12,
                            ),
                          ),
                        ),

                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,

                              decoration: BoxDecoration(
                                color:
                                    AppColors.marigold.withValues(
                                  alpha: 0.12,
                                ),

                                borderRadius:
                                    BorderRadius.circular(12),
                              ),

                              child: Icon(
                                item.$4,
                                color: AppColors.marigold,
                                size: 22,
                              ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.$1,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                          FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),

                                  const SizedBox(height: 3),

                                  Text(
                                    item.$2,
                                    style: const TextStyle(
                                      color:
                                          Color(0xFFA9B4CC),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Icon(
                              Icons
                                  .arrow_forward_ios_rounded,
                              color: Colors.white54,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}