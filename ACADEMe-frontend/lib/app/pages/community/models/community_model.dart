// models/community_model.dart
import 'package:flutter/material.dart';

class CommunityModel {
  final String title;
  final IconData icon;
  final Color color;
  final String members;

  const CommunityModel({
    required this.title,
    required this.icon,
    required this.color,
    required this.members,
  });

  // Static method to get sample communities data
  static List<CommunityModel> getSampleCommunities() {
    return [
      CommunityModel(
        title: "Machine Learning",
        icon: Icons.campaign,
        color: Colors.red,
        members: "1233",
      ),
      CommunityModel(
        title: "Computer Science",
        icon: Icons.insert_drive_file,
        color: Colors.blue,
        members: "9890",
      ),
      CommunityModel(
        title: "Biotechnology",
        icon: Icons.science,
        color: Colors.green,
        members: "665",
      ),
      CommunityModel(
        title: "Mathematics",
        icon: Icons.functions,
        color: Colors.indigo,
        members: "99908",
      ),
    ];
  }
}
