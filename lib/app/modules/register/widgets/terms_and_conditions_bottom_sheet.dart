import 'package:crypted_app/core/locale/constant.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/size_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TermsAndConditionsBottomSheet extends StatelessWidget {
  const TermsAndConditionsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: ColorsManager.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Radiuss.large),
          topRight: Radius.circular(Radiuss.large),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(Paddings.large),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: ColorsManager.borderColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Constants.kTermsAndConditions.tr,
                  style: StylesManager.semiBold(
                    fontSize: FontSize.large,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(Icons.close, color: ColorsManager.grey),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Paddings.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: Constants.kTermsOfService.tr,
                    content: _getTermsOfServiceContent(),
                  ),
                  SizedBox(height: Sizes.size24),
                  _buildSection(
                    title: Constants.kPrivacy.tr,
                    content: _getPrivacyPolicyContent(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: StylesManager.bold(
            fontSize: FontSize.xLarge,
            color: ColorsManager.primary,
          ),
        ),
        SizedBox(height: Sizes.size12),
        content,
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: Paddings.normal,
        bottom: Paddings.small,
      ),
      child: Text(
        title,
        style: StylesManager.semiBold(
          fontSize: FontSize.medium,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Paddings.normal),
      child: Text(
        text,
        style: StylesManager.regular(
          fontSize: FontSize.small,
          color: ColorsManager.grey,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: Paddings.small,
        left: Paddings.normal,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: StylesManager.regular(
              fontSize: FontSize.small,
              color: ColorsManager.grey,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: StylesManager.regular(
                fontSize: FontSize.small,
                color: ColorsManager.grey,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getTermsOfServiceContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildParagraph(
          '${Constants.kLastUpdated.tr}: November 2, 2025',
        ),

        _buildSectionTitle('1. ${Constants.kAcceptance.tr}'),
        _buildParagraph(
          'By creating an account and using Crypted, you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree to these terms, please do not use our services.',
        ),

        _buildSectionTitle('2. ${Constants.kUserAccounts.tr}'),
        _buildParagraph(
          'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You must:',
        ),
        _buildBulletPoint('Provide accurate and complete information during registration'),
        _buildBulletPoint('Maintain the security of your password and account'),
        _buildBulletPoint('Notify us immediately of any unauthorized use of your account'),
        _buildBulletPoint('Be at least 13 years old to use this service'),

        _buildSectionTitle('3. ${Constants.kPrivacyAndDataProtection.tr}'),
        _buildParagraph(
          'We are committed to protecting your privacy and complying with applicable data protection laws, including GDPR (General Data Protection Regulation) and CCPA (California Consumer Privacy Act). We:',
        ),
        _buildBulletPoint('Encrypt all messages end-to-end to ensure your conversations remain private'),
        _buildBulletPoint('Collect only the minimum data necessary to provide our services'),
        _buildBulletPoint('Never sell your personal information to third parties'),
        _buildBulletPoint('Allow you to access, export, and delete your data at any time'),
        _buildBulletPoint('Store your data securely using industry-standard encryption'),
        _buildParagraph(
          'Under GDPR, you have the right to access, rectify, erase, restrict processing, data portability, and object to processing of your personal data. Under CCPA, California residents have the right to know what personal information is collected, delete personal information, and opt-out of the sale of personal information (though we do not sell personal information).',
        ),

        _buildSectionTitle('4. ${Constants.kUserContent.tr}'),
        _buildParagraph(
          'You retain all rights to the content you share on Crypted. By using our service, you grant us a limited license to:',
        ),
        _buildBulletPoint('Store and transmit your messages and media'),
        _buildBulletPoint('Process your data to provide and improve our services'),
        _buildBulletPoint('Create backups for data recovery purposes'),
        _buildParagraph(
          'You are solely responsible for the content you share and must ensure it complies with applicable laws and does not infringe on others\' rights.',
        ),

        _buildSectionTitle('5. ${Constants.kProhibitedActivities.tr}'),
        _buildParagraph(
          'You agree not to use Crypted for any unlawful purpose or in any way that could harm our service or other users. Prohibited activities include:',
        ),
        _buildBulletPoint('Sharing illegal, harmful, threatening, or abusive content'),
        _buildBulletPoint('Harassing, stalking, or threatening other users'),
        _buildBulletPoint('Impersonating others or misrepresenting your identity'),
        _buildBulletPoint('Distributing spam, malware, or viruses'),
        _buildBulletPoint('Attempting to gain unauthorized access to our systems'),
        _buildBulletPoint('Violating intellectual property rights'),
        _buildBulletPoint('Sharing explicit content involving minors'),

        _buildSectionTitle('6. ${Constants.kIntellectualProperty.tr}'),
        _buildParagraph(
          'Crypted and its original content, features, and functionality are owned by us and are protected by international copyright, trademark, and other intellectual property laws. You may not copy, modify, distribute, or create derivative works without our express written permission.',
        ),

        _buildSectionTitle('7. ${Constants.kTermination.tr}'),
        _buildParagraph(
          'We reserve the right to suspend or terminate your account at any time if you violate these terms or engage in activities that harm our service or other users. Upon termination:',
        ),
        _buildBulletPoint('Your access to the service will be immediately revoked'),
        _buildBulletPoint('You may request a copy of your data within 30 days'),
        _buildBulletPoint('Your data will be deleted according to our data retention policy'),

        _buildSectionTitle('8. ${Constants.kDisclaimerOfWarranties.tr}'),
        _buildParagraph(
          'Crypted is provided "as is" without warranties of any kind, either express or implied. We do not guarantee that the service will be uninterrupted, secure, or error-free. While we implement strong security measures, no method of transmission over the internet is 100% secure.',
        ),

        _buildSectionTitle('9. ${Constants.kLimitationOfLiability.tr}'),
        _buildParagraph(
          'To the fullest extent permitted by law, Crypted shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, or any loss of data, use, goodwill, or other intangible losses resulting from:',
        ),
        _buildBulletPoint('Your use or inability to use the service'),
        _buildBulletPoint('Unauthorized access to or alteration of your data'),
        _buildBulletPoint('Any conduct or content of third parties on the service'),

        _buildSectionTitle('10. ${Constants.kGoverningLaw.tr}'),
        _buildParagraph(
          'These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in which we operate, without regard to its conflict of law provisions. Any disputes arising from these terms or your use of the service shall be resolved through binding arbitration.',
        ),

        _buildSectionTitle('11. Changes to Terms'),
        _buildParagraph(
          'We reserve the right to modify these terms at any time. We will notify you of any material changes by posting the new terms within the app and via email. Your continued use of Crypted after such modifications constitutes your acceptance of the updated terms.',
        ),

        _buildSectionTitle('12. ${Constants.kContactInformation.tr}'),
        _buildParagraph(
          'If you have any questions about these Terms of Service or our Privacy Policy, please contact us at:',
        ),
        _buildBulletPoint('Email: support@crypted.com'),
        _buildBulletPoint('Privacy Officer: privacy@crypted.com'),
        _buildBulletPoint('GDPR/CCPA Requests: dataprotection@crypted.com'),
      ],
    );
  }

  Widget _getPrivacyPolicyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildParagraph(
          '${Constants.kLastUpdated.tr}: November 2, 2025',
        ),

        _buildSectionTitle('1. Information We Collect'),
        _buildParagraph(
          'We collect information you provide directly to us when you create an account and use our services:',
        ),
        _buildBulletPoint('Account Information: Name, email address, profile picture, and phone number (optional)'),
        _buildBulletPoint('Content: Messages, photos, videos, and files you share through our service'),
        _buildBulletPoint('Usage Data: Information about how you use our app, including device information, IP address, and app interactions'),
        _buildBulletPoint('Location Data: With your permission, we may collect location information for location-sharing features'),

        _buildSectionTitle('2. How We Use Your Information'),
        _buildParagraph(
          'We use the information we collect to:',
        ),
        _buildBulletPoint('Provide, maintain, and improve our services'),
        _buildBulletPoint('Send you technical notices and support messages'),
        _buildBulletPoint('Respond to your requests and questions'),
        _buildBulletPoint('Detect, prevent, and address fraud and security issues'),
        _buildBulletPoint('Comply with legal obligations'),
        _buildParagraph(
          'We do NOT use your information to:',
        ),
        _buildBulletPoint('Sell to third parties for marketing purposes'),
        _buildBulletPoint('Read the contents of your encrypted messages'),
        _buildBulletPoint('Display targeted advertisements'),

        _buildSectionTitle('3. Data Security and Encryption'),
        _buildParagraph(
          'Security is at the core of Crypted. We implement multiple layers of protection:',
        ),
        _buildBulletPoint('End-to-End Encryption: All messages are encrypted using industry-standard encryption protocols, ensuring only you and your intended recipient can read them'),
        _buildBulletPoint('Secure Storage: Your data is stored on secure servers protected by firewalls and encryption'),
        _buildBulletPoint('Transport Security: All data transmission uses TLS/SSL encryption'),
        _buildBulletPoint('Regular Security Audits: We conduct regular security assessments to identify and address vulnerabilities'),

        _buildSectionTitle('4. Your Rights Under GDPR'),
        _buildParagraph(
          'If you are located in the European Economic Area (EEA), you have the following rights:',
        ),
        _buildBulletPoint('Right to Access: Request a copy of your personal data'),
        _buildBulletPoint('Right to Rectification: Correct inaccurate or incomplete data'),
        _buildBulletPoint('Right to Erasure: Request deletion of your personal data ("right to be forgotten")'),
        _buildBulletPoint('Right to Restrict Processing: Limit how we use your data'),
        _buildBulletPoint('Right to Data Portability: Receive your data in a machine-readable format'),
        _buildBulletPoint('Right to Object: Object to processing of your personal data'),
        _buildBulletPoint('Right to Withdraw Consent: Withdraw consent at any time without affecting prior processing'),
        _buildParagraph(
          'To exercise any of these rights, please contact our Data Protection Officer at dataprotection@crypted.com.',
        ),

        _buildSectionTitle('5. Your Rights Under CCPA'),
        _buildParagraph(
          'If you are a California resident, you have the following rights under the California Consumer Privacy Act:',
        ),
        _buildBulletPoint('Right to Know: Request information about the personal information we collect, use, and disclose'),
        _buildBulletPoint('Right to Delete: Request deletion of your personal information'),
        _buildBulletPoint('Right to Opt-Out: Opt-out of the sale of personal information (we do not sell personal information)'),
        _buildBulletPoint('Right to Non-Discrimination: We will not discriminate against you for exercising your CCPA rights'),
        _buildParagraph(
          'To submit a request, contact us at dataprotection@crypted.com or call 1-800-XXX-XXXX. We will verify your identity before processing your request.',
        ),

        _buildSectionTitle('6. Data Retention'),
        _buildParagraph(
          'We retain your personal information only as long as necessary to provide our services and comply with legal obligations:',
        ),
        _buildBulletPoint('Account Information: Retained while your account is active and for 30 days after account deletion'),
        _buildBulletPoint('Messages: Stored until deleted by you or until your account is permanently deleted'),
        _buildBulletPoint('Backup Data: Retained for 30 days to allow for data recovery'),
        _buildBulletPoint('Legal Compliance: Some data may be retained longer if required by law'),

        _buildSectionTitle('7. Sharing Your Information'),
        _buildParagraph(
          'We do not sell your personal information. We may share your information only in the following limited circumstances:',
        ),
        _buildBulletPoint('With Your Consent: When you explicitly authorize us to share information'),
        _buildBulletPoint('Service Providers: With trusted third-party services that help us operate our app (e.g., cloud hosting, analytics) under strict confidentiality agreements'),
        _buildBulletPoint('Legal Requirements: When required by law, court order, or government request'),
        _buildBulletPoint('Safety and Protection: To protect the rights, safety, and property of Crypted, our users, or the public'),

        _buildSectionTitle('8. International Data Transfers'),
        _buildParagraph(
          'Your information may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place, including:',
        ),
        _buildBulletPoint('Standard Contractual Clauses approved by the European Commission'),
        _buildBulletPoint('Adequacy decisions for countries with adequate data protection'),
        _buildBulletPoint('Privacy Shield certification (where applicable)'),

        _buildSectionTitle('9. Children\'s Privacy'),
        _buildParagraph(
          'Crypted is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If we become aware that a child under 13 has provided us with personal information, we will take steps to delete such information.',
        ),

        _buildSectionTitle('10. Cookies and Tracking'),
        _buildParagraph(
          'We use minimal tracking technologies to improve user experience:',
        ),
        _buildBulletPoint('Essential Cookies: Required for app functionality'),
        _buildBulletPoint('Analytics: Anonymous usage statistics to improve our service'),
        _buildBulletPoint('No Third-Party Advertising Cookies: We do not use cookies for advertising purposes'),

        _buildSectionTitle('11. Changes to Privacy Policy'),
        _buildParagraph(
          'We may update this Privacy Policy from time to time. We will notify you of significant changes by:',
        ),
        _buildBulletPoint('Posting the updated policy in the app'),
        _buildBulletPoint('Sending you an email notification'),
        _buildBulletPoint('Requiring acceptance before continued use (for material changes)'),

        _buildSectionTitle('12. Contact Us'),
        _buildParagraph(
          'For questions about this Privacy Policy or to exercise your rights:',
        ),
        _buildBulletPoint('Email: privacy@crypted.com'),
        _buildBulletPoint('Data Protection Officer: dataprotection@crypted.com'),
        _buildBulletPoint('Mailing Address: [Your Company Address]'),
        _buildBulletPoint('GDPR Representative (EU): [EU Representative Contact]'),
        _buildBulletPoint('Phone: 1-800-XXX-XXXX (CCPA requests)'),
      ],
    );
  }
}
