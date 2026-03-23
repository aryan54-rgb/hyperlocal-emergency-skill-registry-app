// ============================================================
// SUPPORT MODAL - Globally accessible FAQ + disclaimer
// Glassmorphism slide-up panel
// ============================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../core/constants.dart';

class SupportModal extends StatelessWidget {
  const SupportModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SupportModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonBlue.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ---- Handle bar ----
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.darkDivider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // ---- Header ----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppGradients.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.help_outline, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Text(
                  'Support & FAQ',
                  style: AppTextStyles.headline2(),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // ---- Emergency Disclaimer ----
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.neonRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.neonRed.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.neonRed, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ALWAYS CALL 112 FIRST',
                              style: AppTextStyles.bodyBold().copyWith(
                                color: AppColors.neonRed,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'This app connects you with trained neighbours — it does NOT replace emergency services. In any life-threatening situation, call 112 immediately.',
                              style: AppTextStyles.body()
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'FREQUENTLY ASKED QUESTIONS',
                  style: AppTextStyles.caption().copyWith(
                    letterSpacing: 2,
                    color: AppColors.neonBlue,
                  ),
                ),
                const SizedBox(height: 16),

                ..._faqs.map((faq) => _FaqTile(
                      question: faq['q']!,
                      answer: faq['a']!,
                    )),

                const SizedBox(height: 24),
                const Divider(color: AppColors.darkDivider),
                const SizedBox(height: 16),

                // ---- Contact ----
                Text(
                  'CONTACT US',
                  style: AppTextStyles.caption().copyWith(
                    letterSpacing: 2,
                    color: AppColors.neonBlue,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final uri = Uri(
                      scheme: 'mailto',
                      path: AppConstants.contactEmail,
                      queryParameters: {'subject': 'Emergency Registry App Support'},
                    );
                    if (await canLaunchUrl(uri)) launchUrl(uri);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.darkDivider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mail_outline,
                            color: AppColors.neonCyan, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppConstants.contactEmail,
                            style: AppTextStyles.body().copyWith(
                              color: AppColors.neonCyan,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.neonCyan,
                            ),
                          ),
                        ),
                        const Icon(Icons.open_in_new,
                            color: AppColors.textMuted, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'What is the Emergency Skill Registry?',
      'a':
          'It\'s a platform connecting people in emergencies with trained volunteers in their neighbourhood — within the critical 5–10 minute window before professional help arrives.',
    },
    {
      'q': 'Is my personal information safe?',
      'a':
          'Your data is stored securely and used solely for emergency matching. We follow data minimisation principles and your contact details are shared only during active emergency searches.',
    },
    {
      'q': 'Who can register as a volunteer?',
      'a':
          'Anyone with a verifiable emergency skill — CPR certification, first aid training, medical profession, firefighting, lifeguarding, and more.',
    },
    {
      'q': 'How quickly can I find help?',
      'a':
          'Our system matches you with volunteers in real time. Average response time is under 90 seconds.',
    },
    {
      'q': 'Can I opt out after registering?',
      'a':
          'Yes. Contact us at the email below to update your availability status or remove your profile entirely.',
    },
  ];
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? AppColors.neonBlue.withOpacity(0.4)
              : AppColors.darkDivider,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          onExpansionChanged: (v) => setState(() => _expanded = v),
          title: Text(
            widget.question,
            style: AppTextStyles.bodyBold().copyWith(fontSize: 13),
          ),
          iconColor: AppColors.neonBlue,
          collapsedIconColor: AppColors.textMuted,
          children: [
            Text(
              widget.answer,
              style: AppTextStyles.body().copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
