import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  static Future<String> sendFriendRequest(String input, User user) async {
    if (input.contains('@')) {
      //contains란 @를 포함하는지 확인하는 메소드
      final query =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: input)
              .get();
      if (query.docs.isEmpty || query.docs.first.id == user.uid) {
        return "존재하지 않는 사용자입니다.";
      }
      return _sendFriendRequestToTarget(query.docs.first, user);
    } else {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(input).get();
      if (!doc.exists || doc.id == user.uid) {
        return "존재하지 않는 사용자입니다.";
      }
      return _sendFriendRequestToTarget(doc, user);
    }
  }

  static Future<String> _sendFriendRequestToTarget(
    dynamic target,
    User user,
  ) async {
    final targetUid = target.id;
    // 이미 친구인지, 이미 요청했는지 체크
    final alreadyFriend =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('friends')
            .doc(targetUid)
            .get();
    if (alreadyFriend.exists) {
      return "이미 친구입니다.";
    }
    final alreadyRequested =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUid)
            .collection('friend_requests_received')
            .doc(user.uid)
            .get();
    if (alreadyRequested.exists) {
      return "이미 요청을 보냈습니다.";
    }
    // 요청 생성
    await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid)
        .collection('friend_requests_received')
        .doc(user.uid)
        .set({
          'from': user.uid,
          'email': user.email,
          'timestamp': FieldValue.serverTimestamp(),
        });
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('friend_requests_sent')
        .doc(targetUid)
        .set({
          'to': targetUid,
          'email': target['email'],
          'timestamp': FieldValue.serverTimestamp(),
        });
    return "친구 요청을 보냈습니다.";
  }

  static Future<void> acceptFriendRequest(
    String fromUid,
    String fromEmail,
    User user,
  ) async {
    // 양쪽 friends에 추가
    final batch = FirebaseFirestore.instance.batch();
    final userFriendsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('friends')
        .doc(fromUid);
    final fromFriendsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(fromUid)
        .collection('friends')
        .doc(user.uid);
    batch.set(userFriendsRef, {'uid': fromUid, 'email': fromEmail});
    batch.set(fromFriendsRef, {'uid': user.uid, 'email': user.email});
    // 요청 삭제
    final receivedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('friend_requests_received')
        .doc(fromUid);
    final sentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(fromUid)
        .collection('friend_requests_sent')
        .doc(user.uid);
    batch.delete(receivedRef);
    batch.delete(sentRef);
    await batch.commit();
  }

  static Stream<List<Map<String, dynamic>>> receivedRequestsStream(
    String uid,
  ) async* {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('friend_requests_received');
    await for (final snap in ref.snapshots()) {
      yield snap.docs.map((doc) => {'uid': doc.id, ...doc.data()}).toList();
    }
  }

  static Stream<List<Map<String, dynamic>>> friendListStream(
    String uid,
  ) async* {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('friends');
    await for (final snap in ref.snapshots()) {
      yield snap.docs.map((doc) => doc.data()).toList();
    }
  }

  /// Firestore에서 uid로 사용자 이름을 불러오는 함수
  static Future<String?> getUserName(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data()?['name'] as String?;
    } catch (e) {
      return null;
    }
  }
}
