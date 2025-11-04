import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/font_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutView extends StatefulWidget {
  const AboutView({super.key});

  @override
  State<AboutView> createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  String appVersion = '';
  String appBuildNumber = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
    _loadAppInfo();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = packageInfo.version;
      appBuildNumber = packageInfo.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: ColorsManager.primary,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    'About Crypted',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: FontSize.large,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ColorsManager.primary,
                          ColorsManager.primary.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Icon(
                          Icons.lock_outline,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App Logo and Name
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: ColorsManager.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(
                                Icons.message_outlined,
                                size: 60,
                                color: ColorsManager.primary,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Crypted',
                              style: StylesManager.bold(
                                fontSize: 32,
                                color: ColorsManager.black,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Secure Encrypted Messaging',
                              style: StylesManager.regular(
                                fontSize: FontSize.medium,
                                color: ColorsManager.grey,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Version $appVersion ($appBuildNumber)',
                              style: StylesManager.regular(
                                fontSize: FontSize.small,
                                color: ColorsManager.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 40),

                      // Description
                      _buildSectionTitle('About This App'),
                      SizedBox(height: 12),
                      Text(
                        'Crypted is a secure, encrypted messaging application that prioritizes your privacy and security. With end-to-end encryption, your conversations remain private and protected.',
                        style: StylesManager.regular(
                          fontSize: FontSize.medium,
                          color: ColorsManager.black.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.justify,
                      ),

                      SizedBox(height: 32),

                      // Features
                      _buildSectionTitle('Key Features'),
                      SizedBox(height: 16),
                      _buildFeatureItem(
                        icon: Icons.lock,
                        title: 'End-to-End Encryption',
                        description: 'Your messages are secured with military-grade encryption',
                      ),
                      _buildFeatureItem(
                        icon: Icons.history,
                        title: 'Stories & Status',
                        description: 'Share moments with 24-hour expiring stories',
                      ),
                      _buildFeatureItem(
                        icon: Icons.group,
                        title: 'Group Chats',
                        description: 'Connect with multiple people at once securely',
                      ),
                      _buildFeatureItem(
                        icon: Icons.video_call,
                        title: 'Voice & Video Calls',
                        description: 'High-quality encrypted calls with your contacts',
                      ),
                      _buildFeatureItem(
                        icon: Icons.cloud_upload,
                        title: 'Cloud Backup',
                        description: 'Safely backup your conversations and media',
                      ),

                      SizedBox(height: 32),

                      // Credits
                      _buildSectionTitle('Credits'),
                      SizedBox(height: 16),
                      _buildInfoCard(
                        icon: Icons.code,
                        title: 'Development',
                        subtitle: 'Built with Flutter & Firebase',
                      ),
                      _buildInfoCard(
                        icon: Icons.security,
                        title: 'Security',
                        subtitle: 'Industry-standard encryption protocols',
                      ),
                      _buildInfoCard(
                        icon: Icons.favorite,
                        title: 'Made with Love',
                        subtitle: 'Crafted with care for your privacy',
                      ),

                      SizedBox(height: 32),

                      // Contact & Social
                      _buildSectionTitle('Get in Touch'),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSocialButton(
                            icon: Icons.email,
                            label: 'Email',
                            onTap: () => _launchUrl('mailto:support@crypted.app'),
                          ),
                          _buildSocialButton(
                            icon: Icons.language,
                            label: 'Website',
                            onTap: () => _launchUrl('https://crypted.app'),
                          ),
                          _buildSocialButton(
                            icon: Icons.privacy_tip,
                            label: 'Privacy',
                            onTap: () => Get.toNamed('/privacy'),
                          ),
                        ],
                      ),

                      SizedBox(height: 32),

                      // Legal
                      Center(
                        child: Column(
                          children: [
                            Text(
                              '© 2024 Crypted. All rights reserved.',
                              style: StylesManager.regular(
                                fontSize: FontSize.small,
                                color: ColorsManager.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () => Get.toNamed('/privacy'),
                                  child: Text(
                                    'Privacy Policy',
                                    style: TextStyle(
                                      fontSize: FontSize.small,
                                      color: ColorsManager.primary,
                                    ),
                                  ),
                                ),
                                Text('•', style: TextStyle(color: ColorsManager.grey)),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Terms of Service',
                                    style: TextStyle(
                                      fontSize: FontSize.small,
                                      color: ColorsManager.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: StylesManager.semiBold(
        fontSize: FontSize.xLarge,
        color: ColorsManager.black,
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: ColorsManager.primary, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: StylesManager.semiBold(
                    fontSize: FontSize.medium,
                    color: ColorsManager.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: StylesManager.regular(
                    fontSize: FontSize.small,
                    color: ColorsManager.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorsManager.navbarColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: ColorsManager.primary, size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: StylesManager.semiBold(
                    fontSize: FontSize.medium,
                    color: ColorsManager.black,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: StylesManager.regular(
                    fontSize: FontSize.small,
                    color: ColorsManager.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: ColorsManager.primary.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: ColorsManager.primary, size: 32),
            SizedBox(height: 8),
            Text(
              label,
              style: StylesManager.medium(
                fontSize: FontSize.small,
                color: ColorsManager.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
