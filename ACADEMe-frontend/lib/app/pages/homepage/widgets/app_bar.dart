import 'package:flutter/material.dart';
import '../../../../localization/l10n.dart';

class HomeAppBar extends StatelessWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onHamburgerTap;
  final String name;
  final String photoUrl;

  const HomeAppBar({
    super.key,
    required this.onProfileTap,
    required this.onHamburgerTap,
    required this.name,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.only(top: 38.0, left: 18, right: 18, bottom: 0),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: onProfileTap,
            child: Hero(
              tag: 'profile_avatar',
              child: CircleAvatar(
                radius: 30,
                backgroundImage: photoUrl.startsWith('http')
                    ? NetworkImage(photoUrl) as ImageProvider
                    : AssetImage(photoUrl),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  L10n.getTranslatedText(context, 'Hello'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            width: 40,
            height: 40,
            child: IconButton(
              icon: const Icon(
                Icons.menu,
                color: Colors.black,
                size: 20,
              ),
              onPressed: onHamburgerTap,
            ),
          ),
        ],
      ),
    );
  }
}
