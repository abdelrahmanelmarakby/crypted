// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher_string.dart';
class HtmlTextWidget extends StatelessWidget {
  const HtmlTextWidget({
    super.key,
    required this.text,
  });
  final String text;
  @override
  Widget build(BuildContext context) {
    return Html(
      shrinkWrap: true,
      data: text,
      style: {
        "body": Style(
          fontSize: FontSize(14),
          color: Colors.black,
        ),
      },
      onLinkTap: (url, attributes, element) {
        if (url != null) launchUrlString(url);
      },
    );
  }
}
