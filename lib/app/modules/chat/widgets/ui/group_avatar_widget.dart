import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypted_app/app/data/models/user_model.dart';
import 'package:crypted_app/core/themes/color_manager.dart';
import 'package:crypted_app/core/themes/styles_manager.dart';

/// UI-007: Group Avatar Collage
/// Displays a collage of member avatars instead of a generic group icon

class GroupAvatarWidget extends StatelessWidget {
  final List<SocialMediaUser> members;
  final String? groupImageUrl;
  final double size;
  final VoidCallback? onTap;

  const GroupAvatarWidget({
    super.key,
    required this.members,
    this.groupImageUrl,
    this.size = 48,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // If group has a custom image, show that
    if (groupImageUrl != null && groupImageUrl!.isNotEmpty) {
      return GestureDetector(
        onTap: onTap,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: groupImageUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildPlaceholder(),
            errorWidget: (context, url, error) => _buildCollage(),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: _buildCollage(),
    );
  }

  Widget _buildCollage() {
    final displayMembers = members.take(4).toList();
    final memberCount = displayMembers.length;

    if (memberCount == 0) {
      return _buildPlaceholder();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorsManager.primary.withValues(alpha: 0.1),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildAvatarLayout(displayMembers),
    );
  }

  Widget _buildAvatarLayout(List<SocialMediaUser> displayMembers) {
    switch (displayMembers.length) {
      case 1:
        return _SingleAvatar(member: displayMembers[0], size: size);
      case 2:
        return _TwoAvatars(members: displayMembers, size: size);
      case 3:
        return _ThreeAvatars(members: displayMembers, size: size);
      default:
        return _FourAvatars(
          members: displayMembers,
          size: size,
          extraCount: members.length > 4 ? members.length - 4 : 0,
        );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorsManager.primary.withValues(alpha: 0.2),
      ),
      child: Icon(
        Icons.group,
        size: size * 0.5,
        color: ColorsManager.primary,
      ),
    );
  }
}

class _SingleAvatar extends StatelessWidget {
  final SocialMediaUser member;
  final double size;

  const _SingleAvatar({required this.member, required this.size});

  @override
  Widget build(BuildContext context) {
    return _MemberAvatar(member: member, size: size);
  }
}

class _TwoAvatars extends StatelessWidget {
  final List<SocialMediaUser> members;
  final double size;

  const _TwoAvatars({required this.members, required this.size});

  @override
  Widget build(BuildContext context) {
    final halfSize = size / 2;
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          child: ClipPath(
            clipper: _LeftHalfClipper(),
            child: _MemberAvatar(member: members[0], size: size),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: ClipPath(
            clipper: _RightHalfClipper(),
            child: _MemberAvatar(member: members[1], size: size),
          ),
        ),
        // Divider line
        Positioned.fill(
          child: CustomPaint(
            painter: _DiagonalLinePainter(),
          ),
        ),
      ],
    );
  }
}

class _ThreeAvatars extends StatelessWidget {
  final List<SocialMediaUser> members;
  final double size;

  const _ThreeAvatars({required this.members, required this.size});

  @override
  Widget build(BuildContext context) {
    final smallSize = size * 0.55;
    return Stack(
      children: [
        // Top avatar
        Positioned(
          top: 0,
          left: (size - smallSize) / 2,
          child: _MemberAvatar(member: members[0], size: smallSize),
        ),
        // Bottom left
        Positioned(
          bottom: 0,
          left: 0,
          child: _MemberAvatar(member: members[1], size: smallSize),
        ),
        // Bottom right
        Positioned(
          bottom: 0,
          right: 0,
          child: _MemberAvatar(member: members[2], size: smallSize),
        ),
      ],
    );
  }
}

class _FourAvatars extends StatelessWidget {
  final List<SocialMediaUser> members;
  final double size;
  final int extraCount;

  const _FourAvatars({
    required this.members,
    required this.size,
    this.extraCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final smallSize = size * 0.48;
    final gap = size * 0.04;

    return Stack(
      children: [
        // Top left
        Positioned(
          top: 0,
          left: 0,
          child: _MemberAvatar(member: members[0], size: smallSize),
        ),
        // Top right
        Positioned(
          top: 0,
          right: 0,
          child: _MemberAvatar(member: members[1], size: smallSize),
        ),
        // Bottom left
        Positioned(
          bottom: 0,
          left: 0,
          child: _MemberAvatar(member: members[2], size: smallSize),
        ),
        // Bottom right - show count if extra members
        Positioned(
          bottom: 0,
          right: 0,
          child: extraCount > 0
              ? _ExtraCountAvatar(count: extraCount, size: smallSize)
              : _MemberAvatar(member: members[3], size: smallSize),
        ),
      ],
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final SocialMediaUser member;
  final double size;

  const _MemberAvatar({required this.member, required this.size});

  @override
  Widget build(BuildContext context) {
    final imageUrl = member.imageUrl;
    final name = member.fullName ?? '';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getColorFromName(name),
        border: Border.all(
          color: Colors.white,
          width: size > 30 ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildInitials(name, size),
              errorWidget: (context, url, error) => _buildInitials(name, size),
            )
          : _buildInitials(name, size),
    );
  }

  Widget _buildInitials(String name, double size) {
    final initials = _getInitials(name);
    return Center(
      child: Text(
        initials,
        style: StylesManager.bold(
          fontSize: size * 0.35,
          color: Colors.white,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getColorFromName(String name) {
    if (name.isEmpty) return ColorsManager.primary;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }
}

class _ExtraCountAvatar extends StatelessWidget {
  final int count;
  final double size;

  const _ExtraCountAvatar({required this.count, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorsManager.grey,
        border: Border.all(
          color: Colors.white,
          width: size > 30 ? 1.5 : 1,
        ),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: StylesManager.bold(
            fontSize: size * 0.3,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _LeftHalfClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _RightHalfClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width, 0),
      Offset(0, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Larger group avatar for headers/profiles
class GroupAvatarLarge extends StatelessWidget {
  final List<SocialMediaUser> members;
  final String? groupImageUrl;
  final String? groupName;
  final double size;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;

  const GroupAvatarLarge({
    super.key,
    required this.members,
    this.groupImageUrl,
    this.groupName,
    this.size = 80,
    this.onTap,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          GroupAvatarWidget(
            members: members,
            groupImageUrl: groupImageUrl,
            size: size,
          ),
          if (onEditTap != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: onEditTap,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: size * 0.2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Mini avatars row for showing group members
class GroupMembersAvatarRow extends StatelessWidget {
  final List<SocialMediaUser> members;
  final int maxDisplay;
  final double avatarSize;
  final double overlap;

  const GroupMembersAvatarRow({
    super.key,
    required this.members,
    this.maxDisplay = 5,
    this.avatarSize = 32,
    this.overlap = 8,
  });

  @override
  Widget build(BuildContext context) {
    final displayMembers = members.take(maxDisplay).toList();
    final extraCount = members.length - maxDisplay;

    return SizedBox(
      height: avatarSize,
      child: Stack(
        children: [
          for (int i = 0; i < displayMembers.length; i++)
            Positioned(
              left: i * (avatarSize - overlap),
              child: _MemberAvatar(
                member: displayMembers[i],
                size: avatarSize,
              ),
            ),
          if (extraCount > 0)
            Positioned(
              left: displayMembers.length * (avatarSize - overlap),
              child: _ExtraCountAvatar(
                count: extraCount,
                size: avatarSize,
              ),
            ),
        ],
      ),
    );
  }
}
