import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class UnreadMessagesController extends GetxController {
  var totalUnreadCount = 0.obs; // This will now represent unread PEOPLE count, not message count
  final Map<String, StreamSubscription<QuerySnapshot>?> _messageSubscriptions = {};
  final Map<String, bool> _chatHasUnreadMessages = {}; // Track which chats have unread messages

  // ⚠️ CRITICAL FIX: Prevent multiple startListeners calls
  bool _listenersStarted = false;

  @override
  void onInit() {
    super.onInit();
    print("[UnreadController] Starting initialization...");

    // ⚠️ CRITICAL FIX: Only start listeners if user is logged in
    final currentUID = FirebaseAuth.instance.currentUser?.uid;
    if (currentUID != null) {
      _setupRealTimeListeners();

      // Debug: Test database structure (only in debug mode)
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        _debugDatabaseStructure();
      }
    } else {
      print("[UnreadController] ⏳ Waiting for user login before starting listeners");
    }
  }

  /// Call this method after user login to start listeners
  void startListeners() {
    // ⚠️ CRITICAL FIX: Prevent multiple calls
    if (_listenersStarted) {
      print("[UnreadController] ⏭️ Listeners already started, skipping");
      return;
    }

    print("[UnreadController] 🚀 Starting listeners after login");
    _listenersStarted = true;
    _setupRealTimeListeners();
  }

  Future<void> _debugDatabaseStructure() async {
    final currentUID = FirebaseAuth.instance.currentUser?.uid;
    if (currentUID == null) return;

    try {
      print("[DEBUG] 🔬 Testing database structure for user: $currentUID");
      
      // Test: Get any message from any chat to see structure
      final testQuery = await FirebaseFirestore.instance
          .collection("Mesajlar")
          .limit(1)
          .get();

      if (testQuery.docs.isNotEmpty) {
        final chatDoc = testQuery.docs.first;
        print("[DEBUG] 📋 Sample chat ID: ${chatDoc.id}");
        print("[DEBUG] 📋 Sample chat data: ${chatDoc.data()}");
        
        // Test: Get any message from this chat
        final messageQuery = await FirebaseFirestore.instance
            .collection("Mesajlar")
            .doc(chatDoc.id)
            .collection("Chat")
            .limit(3)
            .get();
            
        print("[DEBUG] 📨 Found ${messageQuery.docs.length} sample messages in this chat");
        for (var msgDoc in messageQuery.docs) {
          final msgData = msgDoc.data();
          print("[DEBUG] 📄 Message: ${msgDoc.id}");
          print("[DEBUG] 📄 Fields: ${msgData.keys.toList()}");
          print("[DEBUG] 📄 userID: '${msgData['userID']}'");
          print("[DEBUG] 📄 isRead: '${msgData['isRead']}' (type: ${msgData['isRead'].runtimeType})");
          if (msgData['metin'] != null && msgData['metin'].toString().isNotEmpty) {
            print("[DEBUG] 📄 metin: '${msgData['metin'].toString().substring(0, msgData['metin'].toString().length.clamp(0, 30))}...'");
          }
          print("[DEBUG] 📄 ---");
        }
      } else {
        print("[DEBUG] ❌ No chats found in database");
      }
    } catch (e) {
      print("[DEBUG] 💥 Database structure test failed: $e");
    }
  }

  Future<void> refreshUnreadCount() async {
    print("[UnreadController] Manual refresh triggered");
    _cancelAllSubscriptions();
    await Future.delayed(Duration(milliseconds: 500));
    _setupRealTimeListeners();
  }

  void _setupRealTimeListeners() async {
    final currentUID = FirebaseAuth.instance.currentUser?.uid;
    if (currentUID == null) {
      print("[UnreadController] ❌ No current user found");
      return;
    }

    print("[UnreadController] 🚀 Setting up listeners for user: $currentUID");

    try {
      print("[UnreadController] 📡 Querying chats where userID1 = $currentUID");
      final snapshot1 = await FirebaseFirestore.instance
          .collection("Mesajlar")
          .where("userID1", isEqualTo: currentUID)
          .orderBy("timeStamp", descending: true)
          .get();

      print("[UnreadController] 📡 Querying chats where userID2 = $currentUID");
      final snapshot2 = await FirebaseFirestore.instance
          .collection("Mesajlar")
          .where("userID2", isEqualTo: currentUID)
          .orderBy("timeStamp", descending: true)
          .get();

      print("[UnreadController] 📊 Query results: userID1=${snapshot1.docs.length}, userID2=${snapshot2.docs.length}");

      List<QueryDocumentSnapshot> allChats = [];
      allChats.addAll(snapshot1.docs);
      allChats.addAll(snapshot2.docs);

      print("[UnreadController] 📋 Total chats found: ${allChats.length}");

      int validChatCount = 0;
      for (var chatDoc in allChats) {
        final chatData = chatDoc.data() as Map<String, dynamic>;
        final deletedList = List<String>.from(chatData["deleted"] ?? []);
        
        print("[UnreadController] 🔍 Processing chat: ${chatDoc.id}");
        print("[UnreadController] 📝 Chat data keys: ${chatData.keys.toList()}");
        print("[UnreadController] 🗑️ Deleted list: $deletedList");
        
        // Skip if chat is deleted for current user
        if (deletedList.contains(currentUID)) {
          print("[UnreadController] ⏭️ Skipping deleted chat: ${chatDoc.id}");
          continue;
        }

        validChatCount++;
        print("[UnreadController] ✅ Valid chat #$validChatCount: ${chatDoc.id}");
        _createMessageListener(chatDoc.id, currentUID);
      }
      
      print("[UnreadController] 🎯 Setup complete: $validChatCount valid chats");
    } catch (e) {
      print("[UnreadController] 💥 Error setting up listeners: $e");
      print("[UnreadController] 💥 Stack trace: ${StackTrace.current}");
    }
  }

  void _createMessageListener(String chatID, String currentUID) {
    print("[UnreadController] 🎧 Creating listener for chat: $chatID");
    print("[UnreadController] 🔍 Query: userID != $currentUID AND isRead = false");

    _messageSubscriptions[chatID] = FirebaseFirestore.instance
        .collection("Mesajlar")
        .doc(chatID)
        .collection("Chat")
        .where("userID", isNotEqualTo: currentUID)
        .where("isRead", isEqualTo: false)
        .orderBy("timeStamp", descending: true)
        .limit(50)
        .snapshots()
        .listen(
      (QuerySnapshot snapshot) {
        final unreadCount = snapshot.docs.length;
        final hasUnreadMessages = unreadCount > 0;
        
        print("[UnreadController] 📨 Chat $chatID: Found $unreadCount unread messages (has unread: $hasUnreadMessages)");
        
        // Update the chat's unread status
        _chatHasUnreadMessages[chatID] = hasUnreadMessages;
        
        // Debug: Print first few message details
        if (hasUnreadMessages) {
          for (int i = 0; i < snapshot.docs.length && i < 2; i++) {
            final msgData = snapshot.docs[i].data() as Map<String, dynamic>;
            print("[UnreadController] 📄 Message ${i+1}: userID=${msgData['userID']}, isRead=${msgData['isRead']}, metin='${msgData['metin']?.toString().substring(0, msgData['metin']?.toString().length.clamp(0, 20) ?? 0)}...'");
          }
          
          if (snapshot.docs.length > 2) {
            print("[UnreadController] 📄 ... and ${snapshot.docs.length - 2} more messages");
          }
        }
        
        _updateTotalPeopleCount();
      },
      onError: (error) {
        print("[UnreadController] 💥 Error in listener for chat $chatID: $error");
      },
    );
  }

  void _updateTotalPeopleCount() {
    // Count how many chats have unread messages (= how many people have unread messages)
    int peopleWithUnreadMessages = 0;
    
    for (String chatID in _chatHasUnreadMessages.keys) {
      if (_chatHasUnreadMessages[chatID] == true) {
        peopleWithUnreadMessages++;
      }
    }
    
    print("[UnreadController] 👥 People with unread messages: $peopleWithUnreadMessages out of ${_chatHasUnreadMessages.length} chats");
    print("[UnreadController] 🔄 Updating totalUnreadCount from ${totalUnreadCount.value} to $peopleWithUnreadMessages");
    totalUnreadCount.value = peopleWithUnreadMessages;
  }

  void _cancelAllSubscriptions() {
    for (var subscription in _messageSubscriptions.values) {
      subscription?.cancel();
    }
    _messageSubscriptions.clear();
    _chatHasUnreadMessages.clear();
    totalUnreadCount.value = 0;
    _listenersStarted = false; // ⚠️ CRITICAL FIX: Reset flag to allow restart
    print("[UnreadController] All subscriptions cancelled and counters reset");
  }

  @override
  void onClose() {
    _cancelAllSubscriptions();
    super.onClose();
  }
}