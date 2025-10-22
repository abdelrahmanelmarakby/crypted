// ignore_for_file: sort_child_properties_last

import 'package:crypted_app/app/data/models/help_message_model.dart';
import 'package:crypted_app/app/modules/help/controllers/help_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HelpView extends GetView<HelpController> {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Help & Support',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: Container(
        color: Color(0xFFFAFAFA),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFE5E5E5), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.help_outline_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Get Help',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'We\'re here to help you with any questions or issues you may have. Our team typically responds within 24 hours.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // Contact Form
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFE5E5E5), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Submit Help Request',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 24),

                        // Full Name Field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Full Name',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: controller.fullNameError.value != null
                                      ? Color(0xFFEF4444)
                                      : Color(0xFFE5E5E5),
                                  width: 1.5,
                                ),
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Enter your full name',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 16,
                                  ),
                                  prefixIcon: Container(
                                    margin: EdgeInsets.only(left: 16, right: 12),
                                    child: Icon(
                                      Icons.person_outline_rounded,
                                      color: Color(0xFF6B7280),
                                      size: 20,
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                controller: TextEditingController(text: controller.fullNameController.value),
                                onChanged: controller.updateFullName,
                              ),
                            ),
                            Obx(() => controller.fullNameError.value != null
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 6, left: 4),
                                    child: Text(
                                      controller.fullNameError.value!,
                                      style: TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                : SizedBox.shrink()),
                          ],
                        ),

                        SizedBox(height: 24),

                        // Email Field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email Address',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: controller.emailError.value != null
                                      ? Color(0xFFEF4444)
                                      : Color(0xFFE5E5E5),
                                  width: 1.5,
                                ),
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Enter your email address',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 16,
                                  ),
                                  prefixIcon: Container(
                                    margin: EdgeInsets.only(left: 16, right: 12),
                                    child: Icon(
                                      Icons.email_outlined,
                                      color: Color(0xFF6B7280),
                                      size: 20,
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                controller: TextEditingController(text: controller.emailController.value),
                                onChanged: controller.updateEmail,
                              ),
                            ),
                            Obx(() => controller.emailError.value != null
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 6, left: 4),
                                    child: Text(
                                      controller.emailError.value!,
                                      style: TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                : SizedBox.shrink()),
                          ],
                        ),

                        SizedBox(height: 24),

                        // Message Field with Character Counter
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Message',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: controller.messageError.value != null
                                      ? Color(0xFFEF4444)
                                      : Color(0xFFE5E5E5),
                                  width: 1.5,
                                ),
                              ),
                              child: TextField(
                                maxLines: 5,
                                decoration: InputDecoration(
                                  hintText: 'Describe your issue or question in detail...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 16,
                                  ),
                                  prefixIcon: Container(
                                    margin: EdgeInsets.only(left: 16, right: 12, top: 16),
                                    child: Icon(
                                      Icons.message_outlined,
                                      color: Color(0xFF6B7280),
                                      size: 20,
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                controller: TextEditingController(text: controller.messageController.value),
                                onChanged: controller.updateMessage,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 4),
                              child: Obx(() => Text(
                                '${controller.messageController.value.length}/500',
                                style: TextStyle(
                                  color: controller.messageController.value.length > 450
                                      ? Color(0xFFEF4444)
                                      : Color(0xFF6B7280),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              )),
                            ),
                          ],
                        ),

                        SizedBox(height: 32),

                        // Request Type Selection
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Request Type',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Color(0xFFE5E5E5), width: 1.5),
                              ),
                              child: Obx(() => DropdownButton<RequestType>(
                                value: controller.selectedRequestType.value,
                                onChanged: (RequestType? newValue) {
                                  if (newValue != null) {
                                    controller.updateRequestType(newValue);
                                  }
                                },
                                items: RequestType.values.map((RequestType type) {
                                  return DropdownMenuItem<RequestType>(
                                    value: type,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _getRequestTypeColor(type),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          type.displayName,
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                isExpanded: true,
                                underline: SizedBox(),
                                dropdownColor: Colors.white,
                                icon: Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF6B7280)),
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              )),
                            ),
                          ],
                        ),

                        SizedBox(height: 32),

                        // Priority Selection
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Priority Level',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Color(0xFFE5E5E5), width: 1.5),
                              ),
                              child: Obx(() => DropdownButton<String>(
                                value: controller.selectedPriority.value,
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    controller.updatePriority(newValue);
                                  }
                                },
                                items: ['low', 'medium', 'high', 'urgent'].map((String priority) {
                                  return DropdownMenuItem<String>(
                                    value: priority,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _getPriorityColor(priority),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          priority.toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                isExpanded: true,
                                underline: SizedBox(),
                                dropdownColor: Colors.white,
                                icon: Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF6B7280)),
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              )),
                            ),
                          ],
                        ),

                        SizedBox(height: 32),

                        // File Attachments Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attachments (Optional)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),

                            // Selected files display
                            Obx(() => controller.attachmentFiles.isNotEmpty
                                ? Container(
                                    margin: EdgeInsets.only(bottom: 16),
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Color(0xFFE2E8F0), width: 1),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.attach_file_rounded, color: Color(0xFF2563EB), size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Selected Files',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF374151),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        ...controller.attachmentFiles.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final filePath = entry.value;
                                          return Container(
                                            margin: EdgeInsets.only(bottom: 8),
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Color(0xFFE5E7EB)),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.05),
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFF2563EB).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Icon(
                                                    Icons.insert_drive_file_rounded,
                                                    color: Color(0xFF2563EB),
                                                    size: 16,
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    filePath.split('/').last,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black87,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () => controller.removeAttachment(index),
                                                  icon: Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
                                                  padding: EdgeInsets.zero,
                                                  constraints: BoxConstraints(),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  )
                                : SizedBox.shrink()),

                            // File selection buttons
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Color(0xFFE5E5E5), width: 1.5),
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: controller.pickFiles,
                                      icon: Icon(Icons.attach_file_rounded, size: 18, color: Color(0xFF2563EB)),
                                      label: Text(
                                        'Select Files',
                                        style: TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Color(0xFF2563EB),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Color(0xFFE5E5E5), width: 1.5),
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: controller.pickImages,
                                      icon: Icon(Icons.image_rounded, size: 18, color: Color(0xFF059669)),
                                      label: Text(
                                        'Select Images',
                                        style: TextStyle(
                                          color: Color(0xFF059669),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Color(0xFF059669),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: 40),

                        // Submit Button
                        Obx(() => Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: controller.isLoading.value ? Color(0xFF9CA3AF) : Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: controller.isLoading.value
                                ? []
                                : [
                                    BoxShadow(
                                      color: Color(0xFF2563EB).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: ElevatedButton(
                            onPressed: controller.isLoading.value ? null : () async {
                              await controller.submitHelpMessage();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: controller.isLoading.value
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Submitting...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send_rounded, size: 20),
                                      SizedBox(width: 12),
                                      Text(
                                        'Submit Request',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        )),

                        // Success Message
                        Obx(() => controller.isSubmitted.value
                            ? Container(
                                margin: EdgeInsets.only(top: 24),
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Color(0xFFD1FAE5), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF10B981).withOpacity(0.1),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Request Submitted Successfully!',
                                                style: TextStyle(
                                                  color: Color(0xFF065F46),
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Thank you for your request. We\'ll respond within 24 hours.',
                                                style: TextStyle(
                                                  color: Color(0xFF047857),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: controller.resetSubmission,
                                          icon: Icon(Icons.close_rounded, color: Color(0xFF10B981), size: 20),
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            : SizedBox.shrink()),

                        SizedBox(height: 32),

                        // User's Help Messages History
                        Obx(() => controller.userHelpMessages.isNotEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Recent Inquiries',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  ...controller.userHelpMessages.take(5).map((message) => Container(
                                        margin: EdgeInsets.only(bottom: 16),
                                        padding: EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Color(0xFFE5E5E5), width: 1),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.08),
                                              blurRadius: 20,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Header with request type and priority
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: _getRequestTypeColor(message.requestType),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    message.requestType.displayName,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: _getPriorityColor(message.priority),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    (message.priority ?? 'medium').toUpperCase(),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(message.status),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    message.status.toUpperCase(),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            SizedBox(height: 16),

                                            // User message
                                            Text(
                                              message.message,
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Colors.black87,
                                                height: 1.6,
                                              ),
                                            ),

                                            if (message.attachmentUrls != null && message.attachmentUrls!.isNotEmpty) ...[
                                              SizedBox(height: 16),
                                              Text(
                                                'Attachments',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF6B7280),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              ...message.attachmentUrls!.map((url) => Container(
                                                margin: EdgeInsets.only(bottom: 8),
                                                padding: EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFF9FAFB),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Color(0xFFE5E7EB)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.attach_file_rounded, size: 16, color: Color(0xFF2563EB)),
                                                    SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        url.split('/').last,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.black87,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                            ],

                                            SizedBox(height: 16),

                                            // Admin response if available
                                            if (message.response != null && message.response!.isNotEmpty) ...[
                                              Divider(height: 24, color: Color(0xFFE5E7EB)),
                                              Container(
                                                padding: EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFEFF6FF),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Color(0xFFBFDBFE), width: 1),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: Color(0xFF2563EB),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(Icons.reply_rounded, size: 16, color: Colors.white),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            'App Team Response',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Color(0xFF1E40AF),
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                          SizedBox(height: 8),
                                                          Text(
                                                            message.response!,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Colors.black87,
                                                              height: 1.6,
                                                            ),
                                                          ),
                                                          if (message.adminId != null) ...[
                                                            SizedBox(height: 8),
                                                            Text(
                                                              'Responded by: Admin ${message.adminId}',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Color(0xFF6B7280),
                                                                fontStyle: FontStyle.italic,
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],

                                            SizedBox(height: 16),

                                            // Date
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFFF3F4F6),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    '${message.createdAt.day}/${message.createdAt.month}/${message.createdAt.year}',
                                                    style: TextStyle(
                                                      color: Color(0xFF6B7280),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )),
                                  ],
                                )
                              : SizedBox.shrink()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods for color coding
  Color _getRequestTypeColor(RequestType type) {
    switch (type) {
      case RequestType.support:
        return Color(0xFF2563EB);
      case RequestType.inquiry:
        return Color(0xFF059669);
      case RequestType.bugReport:
        return Color(0xFFDC2626);
      case RequestType.featureRequest:
        return Color(0xFFEA580C);
      case RequestType.recommendation:
        return Color(0xFF7C3AED);
      case RequestType.complaint:
        return Color(0xFFDC2626);
      case RequestType.other:
        return Color(0xFF6B7280);
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'urgent':
        return Color(0xFFDC2626);
      case 'high':
        return Color(0xFFEA580C);
      case 'medium':
        return Color(0xFF2563EB);
      case 'low':
        return Color(0xFF059669);
      default:
        return Color(0xFF6B7280);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Color(0xFFEA580C);
      case 'in_progress':
        return Color(0xFF2563EB);
      case 'resolved':
        return Color(0xFF059669);
      case 'closed':
        return Color(0xFF6B7280);
      default:
        return Color(0xFF6B7280);
    }
  }
}
