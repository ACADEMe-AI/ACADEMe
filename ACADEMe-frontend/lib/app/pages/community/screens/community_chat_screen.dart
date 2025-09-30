// community_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../../api_endpoints.dart';
import '../../../auth/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class CommunityChatScreen extends StatefulWidget {
  const CommunityChatScreen({super.key});

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final DatabaseReference _messagesRef =
      FirebaseDatabase.instance.ref().child('community_messages');
  final DatabaseReference _usersRef =
      FirebaseDatabase.instance.ref().child('community_users');
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _userId;
  String? _userName;
  String? _userPhotoUrl;
  String? _userEmail;
  String? _studentClass;
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic> _allUsers = {};
  bool _isLoading = true;
  bool _isFirebaseAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      // Get user data from secure storage
      _userId = await _secureStorage.read(key: "user_id");
      _userName = await _secureStorage.read(key: "user_name") ?? "Anonymous";
      _userPhotoUrl = await _secureStorage.read(key: "photo_url") ??
          "https://www.w3schools.com/w3images/avatar2.png";
      _userEmail = await _secureStorage.read(key: "user_email");
      _studentClass = await _secureStorage.read(key: "student_class");

      if (_userId == null || _userId!.isEmpty) {
        throw Exception("User ID not found");
      }

      debugPrint("Initializing chat for user: $_userId");

      // Initialize Firebase authentication
      await _initializeFirebaseAuth();

      // Fetch all users from backend
      await _fetchAllUsers();

      // Listen to messages
      _listenToMessages();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Error initializing user: $e");
      _showErrorDialog("Failed to initialize chat. Please try again.");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeFirebaseAuth() async {
    try {
      final firebaseAuthService = FirebaseAuthService();
      
      debugPrint("Starting Firebase authentication...");
      
      // Authenticate with Firebase using custom token
      _isFirebaseAuthenticated = await firebaseAuthService.authenticateWithFirebase();

      if (!_isFirebaseAuthenticated) {
        throw Exception("Firebase authentication failed");
      }

      // Wait for auth state to propagate
      await Future.delayed(const Duration(milliseconds: 1000));

      // Get the authenticated Firebase user
      final firebaseUser = firebaseAuthService.getCurrentFirebaseUser();
      if (firebaseUser == null) {
        throw Exception("No Firebase user after authentication");
      }

      debugPrint("Firebase Auth UID: ${firebaseUser.uid}");
      debugPrint("Backend User ID: $_userId");

      // Verify they match
      if (firebaseUser.uid != _userId) {
        debugPrint("Warning: Firebase UID doesn't match backend user ID");
      }

      // CREATE/UPDATE user in Realtime Database
      // This creates the user record if it doesn't exist
      debugPrint("Creating/updating user in Realtime Database...");
      
      final userRef = _usersRef.child(firebaseUser.uid);
      
      try {
        // Check if user exists (optional - for logging)
        final snapshot = await userRef.get();
        if (!snapshot.exists) {
          debugPrint("Creating NEW user in Realtime Database");
        } else {
          debugPrint("Updating EXISTING user in Realtime Database");
        }
        
        // Set user data (creates or updates)
        await userRef.set({
          'name': _userName ?? 'Anonymous',
          'photoUrl': _userPhotoUrl ?? 'https://www.w3schools.com/w3images/avatar2.png',
          'lastSeen': ServerValue.timestamp,
          'isOnline': true,
          'email': _userEmail ?? '',
          'studentClass': _studentClass ?? '',
        });

        debugPrint("User data written to Realtime Database successfully");

        // Set up disconnect handlers
        await userRef.child('isOnline').onDisconnect().set(false);
        await userRef.child('lastSeen').onDisconnect().set(ServerValue.timestamp);
        
        debugPrint("Disconnect handlers configured");

      } catch (dbError) {
        debugPrint("Database write error: $dbError");
        throw Exception("Failed to write to Realtime Database: $dbError");
      }

    } catch (e) {
      debugPrint("Firebase auth error: $e");
      _isFirebaseAuthenticated = false;
      rethrow;
    }
  }

  Future<void> _fetchAllUsers() async {
    try {
      final String? accessToken = await _secureStorage.read(key: "access_token");
      if (accessToken == null) return;

      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.allUsers),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        for (var user in users) {
          _allUsers[user['id']] = {
            'name': user['name'],
            'photoUrl': user['photo_url'],
            'email': user['email'],
            'studentClass': user['student_class'],
          };
        }
        debugPrint("Fetched ${_allUsers.length} users from backend");
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
    }
  }

  void _listenToMessages() {
    if (!_isFirebaseAuthenticated) {
      debugPrint("Cannot listen to messages - not authenticated");
      return;
    }

    debugPrint("Setting up message listener...");

    _messagesRef.orderByChild('timestamp').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        final messages = <Map<String, dynamic>>[];

        data.forEach((key, value) {
          final senderId = value['senderId'] ?? '';
          final userData = _allUsers[senderId] ??
              {
                'name': value['senderName'] ?? 'Unknown User',
                'photoUrl': value['senderPhotoUrl'] ??
                    'https://www.w3schools.com/w3images/avatar2.png',
                'email': '',
                'studentClass': '',
              };

          messages.add({
            'id': key,
            'senderId': senderId,
            'senderName': userData['name'],
            'senderPhotoUrl': userData['photoUrl'],
            'message': value['message'] ?? '',
            'timestamp': value['timestamp'] ?? 0,
            'type': value['type'] ?? 'text',
            'userEmail': userData['email'],
            'studentClass': userData['studentClass'],
          });
        });

        // Sort by timestamp
        messages.sort((a, b) => (a['timestamp'] as num).compareTo(b['timestamp'] as num));

        setState(() => _messages = messages);

        // Auto-scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }, onError: (error) {
      debugPrint("Error listening to messages: $error");
      _showErrorDialog("Connection error. Please check your internet.");
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _userId == null || !_isFirebaseAuthenticated) {
      return;
    }

    try {
      final messageData = {
        'senderId': _userId,
        'senderName': _userName,
        'senderPhotoUrl': _userPhotoUrl,
        'message': _messageController.text.trim(),
        'timestamp': ServerValue.timestamp,
        'type': 'text',
      };

      await _messagesRef.push().set(messageData);
      _messageController.clear();
    } catch (e) {
      debugPrint("Error sending message: $e");
      _showErrorDialog("Failed to send message. Please try again.");
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      final message = _messages.firstWhere((msg) => msg['id'] == messageId);
      if (message['senderId'] != _userId) {
        _showErrorDialog("You can only delete your own messages.");
        return;
      }

      await _messagesRef.child(messageId).remove();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.getTranslatedText(context, 'Message deleted'))),
        );
      }
    } catch (e) {
      debugPrint("Error deleting message: $e");
      _showErrorDialog("Failed to delete message.");
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.getTranslatedText(context, 'Error')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(L10n.getTranslatedText(context, 'OK')),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(num timestamp) {
    if (timestamp == 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return L10n.getTranslatedText(context, 'Just now');
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${L10n.getTranslatedText(context, 'min ago')}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${L10n.getTranslatedText(context, 'hr ago')}';
    } else {
      return DateFormat('MMM dd, HH:mm').format(date);
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['senderId'] == _userId;
    final timestamp = _formatTimestamp(message['timestamp'] as num);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            GestureDetector(
              onTap: () => _showUserProfile(message),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(message['senderPhotoUrl']),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 2),
                    child: Row(
                      children: [
                        Text(
                          message['senderName'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        if (message['studentClass'] != null &&
                            message['studentClass'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AcademeTheme.appColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Class ${message['studentClass']}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AcademeTheme.appColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                GestureDetector(
                  onLongPress: isMe
                      ? () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(L10n.getTranslatedText(context, 'Delete Message')),
                              content: Text(L10n.getTranslatedText(
                                  context, 'Are you sure you want to delete this message?')),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(L10n.getTranslatedText(context, 'Cancel')),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _deleteMessage(message['id']);
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    L10n.getTranslatedText(context, 'Delete'),
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? AcademeTheme.appColor : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['message'],
                          style: TextStyle(
                            fontSize: 15,
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timestamp,
                          style: TextStyle(
                            fontSize: 11,
                            color: isMe ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(message['senderPhotoUrl']),
            ),
          ],
        ],
      ),
    );
  }

  void _showUserProfile(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message['senderName']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(message['senderPhotoUrl']),
              ),
            ),
            const SizedBox(height: 16),
            if (message['userEmail'] != null)
              Text('Email: ${message['userEmail']}'),
            if (message['studentClass'] != null &&
                message['studentClass'].toString().isNotEmpty)
              Text('Class: ${message['studentClass']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(L10n.getTranslatedText(context, 'Close')),
          ),
        ],
      ),
    );
  }

  void _showOnlineUsers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.getTranslatedText(context, 'Community Members')),
        content: FutureBuilder<DatabaseEvent>(
          future: _usersRef.once(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return Text(L10n.getTranslatedText(context, 'No users found'));
            }

            final usersData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
            if (usersData == null) {
              return Text(L10n.getTranslatedText(context, 'No users found'));
            }

            final users = usersData.entries.toList();
            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final userData = user.value as Map<dynamic, dynamic>;
                  final isOnline = userData['isOnline'] == true;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        userData['photoUrl'] ??
                            'https://www.w3schools.com/w3images/avatar2.png',
                      ),
                    ),
                    title: Text(userData['name'] ?? 'Unknown'),
                    subtitle: Text(userData['email'] ?? ''),
                    trailing: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(L10n.getTranslatedText(context, 'Close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AcademeTheme.appColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              L10n.getTranslatedText(context, 'Community Chat'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${_messages.length} ${L10n.getTranslatedText(context, 'messages')}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people, color: Colors.white),
            onPressed: _showOnlineUsers,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(L10n.getTranslatedText(context, 'Community Guidelines')),
                  content: Text(L10n.getTranslatedText(context,
                      '• Be respectful and kind to all members\n• No spam or offensive content\n• Keep conversations appropriate for all ages')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(L10n.getTranslatedText(context, 'OK')),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isFirebaseAuthenticated
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(
                        L10n.getTranslatedText(context, 'Chat Unavailable'),
                        style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        L10n.getTranslatedText(
                            context, 'Please check your connection and try again'),
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeUser,
                        child: Text(L10n.getTranslatedText(context, 'Retry')),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: _messages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_bubble_outline,
                                      size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    L10n.getTranslatedText(context, 'No messages yet'),
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    L10n.getTranslatedText(
                                        context, 'Be the first to say hello!'),
                                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) =>
                                  _buildMessageBubble(_messages[index]),
                            ),
                    ),
                    _buildMessageInput(),
                  ],
                ),
    );
  }

 Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: L10n.getTranslatedText(context, 'Type a message...'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AcademeTheme.appColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    
    // Update user status on dispose
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      _usersRef.child(firebaseUser.uid).update({
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
      });
    }
    
    super.dispose();
  }
}
