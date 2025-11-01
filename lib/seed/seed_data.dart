import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

/// 开发期种子：只往 Firestore 里塞“新模型结构”的数据
class SeedData {
  static Future<void> runAll() async {
    final uid = await _ensureCurrentUserUid();
    await _seedRewards();                 // 全局奖励
    await _seedUsersForLeaderboard(uid);  // 排行榜用户（含当前这个人）
    await _seedExchangesFor(uid);         // 当前用户的兑换历史
    await _seedTodayPoints(uid);          // 当前用户今天的 dailyPoints
  }

  /// 有当前用户就用当前用户，没有就匿名登录一个
  static Future<String> _ensureCurrentUserUid() async {
    final auth = fb.FirebaseAuth.instance;
    var user = auth.currentUser;
    if (user == null) {
      final cred = await auth.signInAnonymously();
      user = cred.user;
    }
    return user!.uid;
  }

  // ----------------- 1) rewards -----------------
  static Future<void> _seedRewards() async {
    final col = FirebaseFirestore.instance.collection('rewards');
    final batch = FirebaseFirestore.instance.batch();

    final rewards = <String, Map<String, dynamic>>{
      'reward_starbucks': {
        'name': 'Starbucks Coffee',
        'points': 150,
        'description': 'One tall size coffee',
        'qrCode': 'https://dummy.qr/1',
      },
      'reward_donut': {
        'name': 'Donut Coupon',
        'points': 80,
        'description': 'Fresh donut from Tims',
        'qrCode': 'https://dummy.qr/2',
      },
      'reward_protein': {
        'name': 'Protein Bar',
        'points': 120,
        'description': 'Healthy workout protein bar',
        'qrCode': 'https://dummy.qr/3',
      },
      'reward_amazon': {
        'name': 'Amazon Gift Card',
        'points': 500,
        'description': 'Shop anything you want',
        'qrCode': 'https://dummy.qr/4',
      },
      'reward_movie': {
        'name': 'Movie Ticket',
        'points': 350,
        'description': 'One ticket for Cineplex',
        'qrCode': 'https://dummy.qr/5',
      },
    };

    for (final e in rewards.entries) {
      batch.set(col.doc(e.key), e.value, SetOptions(merge: true));
    }

    await batch.commit();
  }

  // ----------------- 2) users (排行榜 + 当前用户) -----------------
  static Future<void> _seedUsersForLeaderboard(String currentUid) async {
    final col = FirebaseFirestore.instance.collection('users');
    final now = DateTime.now().toIso8601String();

    // 当前登录的这个人
    await col.doc(currentUid).set({
      'uid': currentUid,
      'name': 'Jiangyu',
      'totalSteps': 12500,
      'healthPoints': 500,
      'totalCalories': 0,
      'updatedAt': now,
    }, SetOptions(merge: true));

    // 下面这几个是排行榜假数据，注意都是“新字段名字”
    final fakeUsers = [
      {
        'uid': 'user_alice',
        'name': 'Alice',
        'totalSteps': 18200,
        'healthPoints': 420,
        'totalCalories': 0,
      },
      {
        'uid': 'user_bob',
        'name': 'Bob',
        'totalSteps': 15600,
        'healthPoints': 360,
        'totalCalories': 0,
      },
      {
        'uid': 'user_charlie',
        'name': 'Charlie',
        'totalSteps': 9800,
        'healthPoints': 270,
        'totalCalories': 0,
      },
      {
        'uid': 'user_emily',
        'name': 'Emily',
        'totalSteps': 21100,
        'healthPoints': 600,
        'totalCalories': 0,
      },
    ];

    for (final u in fakeUsers) {
      await col.doc(u['uid'] as String).set({
        ...u,
        'updatedAt': now,
      }, SetOptions(merge: true));
    }
  }

  // ----------------- 3) 当前用户的兑换记录 -----------------
  static Future<void> _seedExchangesFor(String uid) async {
    final sub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('exchangesHistory');

    // 已经有就不重复塞
    final exists = await sub.limit(1).get();
    if (exists.docs.isNotEmpty) return;

    final now = DateTime.now();

    final dataList = [
      {
        'title': 'Redeemed: Starbucks Coffee',
        'points': 150,
        'date': now.toIso8601String(),
      },
      {
        'title': 'Redeemed: Donut Coupon',
        'points': 80,
        'date': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'title': 'Redeemed: Protein Bar',
        'points': 120,
        'date': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
    ];

    for (final d in dataList) {
      await sub.add(d);
    }
  }

  // ----------------- 4) dailyPoints (给今天补个 0 结构) -----------------
  static Future<void> _seedTodayPoints(String uid) async {
    final today = DateTime.now();
    final ymd =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('dailyPoints')
        .doc(ymd);

    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set({
        'date': ymd,
        'steps': 0,
        'points': 0,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }
}
