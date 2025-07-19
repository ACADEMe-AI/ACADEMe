// controllers/community_controller.dart
import 'package:flutter/material.dart';
import '../models/community_model.dart';

class CommunityController extends ChangeNotifier {
  List<CommunityModel> _communities = [];
  List<CommunityModel> _filteredCommunities = [];
  String _searchQuery = '';
  int _currentTabIndex = 0;

  // Getters
  List<CommunityModel> get communities => _filteredCommunities;
  String get searchQuery => _searchQuery;
  int get currentTabIndex => _currentTabIndex;

  // Initialize controller
  void initialize() {
    _communities = CommunityModel.getSampleCommunities();
    _filteredCommunities = List.from(_communities);
    notifyListeners();
  }

  // Handle search functionality
  void searchCommunities(String query) {
    _searchQuery = query;
    
    if (query.isEmpty) {
      _filteredCommunities = List.from(_communities);
    } else {
      _filteredCommunities = _communities
          .where((community) =>
              community.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    
    notifyListeners();
  }

  // Handle tab changes
  void changeTab(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  // Handle navigation to Ask Me screen
  void navigateToAskMe(BuildContext context) {
    // This would typically import and navigate to AskMeScreen
    // For now, keeping the same navigation logic as original
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _filteredCommunities = List.from(_communities);
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}