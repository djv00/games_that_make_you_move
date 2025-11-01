import 'package:flutter/foundation.dart';
import 'package:flutter_steps_tracker/core/data/models/steps_and_points_model.dart';
import 'package:flutter_steps_tracker/core/data/models/user_model.dart';
import 'package:flutter_steps_tracker/core/data/services/firestore_services.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/data/models/exchange_history_model.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/data/models/reward_model.dart';
import 'package:flutter_steps_tracker/utilities/constants/api_path.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

abstract class Database {
  Future<void> setUserData(UserModel user);

  Future<void> setExchangeHistory(
      ExchangeHistoryModel history,
      String uid,
      );

  Future<void> setDailySteps(
      StepsAndPointsModel stepsAndPoints,
      String uid,
      );

  Future<void> setRewardOrder(
      RewardModel reward,
      String uid,
      );

  Stream<UserModel> getUserStream(String uid);

  Stream<List<RewardModel>> rewardsStream();

  Stream<List<UserModel>> usersStream();

  Stream<List<RewardModel>> myRewardsStream(String uid);

  Stream<List<StepsAndPointsModel>> dailyPointsStream(
      String uid,
      String currentId,
      );

  Stream<List<ExchangeHistoryModel>> exchangeHistoryStream(String uid);
}

/// 统一日期 id
String documentIdForDailyUse() =>
    DateFormat('yyyy-MM-dd').format(DateTime.now());

String documentIdFromLocalGenerator() => DateTime.now().toIso8601String();

@Singleton(as: Database)
class FireStoreDatabase implements Database {
  final _service = FirestoreService.instance;

  // 安全构建
  T? _safeBuild<T>(
      Map<String, dynamic> data,
      String documentId,
      T Function(Map<String, dynamic> data, String documentId) builder,
      String debugSource,
      ) {
    try {
      return builder(data, documentId);
    } catch (e, st) {
      debugPrint(
          '[DB] $debugSource -> build error on doc=$documentId, data=$data, error=$e');
      debugPrint(st.toString());
      return null;
    }
  }

  // 过滤掉 null
  List<T> _nonNullList<T>(List<T?> list) =>
      list.where((e) => e != null).cast<T>().toList();

  @override
  Future<void> setUserData(UserModel user) async {
    await _service.setData(
      path: APIPath.user(user.uid),
      data: user.toMap(),
    );
  }

  @override
  Future<void> setExchangeHistory(
      ExchangeHistoryModel history,
      String uid,
      ) async {
    // 没有 id 就生成一个
    final String docId =
    (history.id.isEmpty) ? DateTime.now().toIso8601String() : history.id;

    // 因为模型没 copyWith，这里手动塞回去
    final data = history.toMap();
    data['id'] = docId;

    await _service.setData(
      path: APIPath.exchangeHistory(uid, docId),
      data: data,
    );
  }

  @override
  Stream<List<RewardModel>> rewardsStream() => _service
      .collectionStream(
    path: APIPath.rewards(),
    builder: (data, documentId) => _safeBuild<RewardModel>(
      data,
      documentId,
          (d, id) => RewardModel.fromMap(d, id),
      'rewardsStream',
    ),
  )
      .map(_nonNullList);

  @override
  Stream<List<ExchangeHistoryModel>> exchangeHistoryStream(String uid) =>
      _service
          .collectionStream(
        path: APIPath.exchangesHistory(uid),
        builder: (data, documentId) =>
            _safeBuild<ExchangeHistoryModel>(
              data,
              documentId,
                  (d, id) => ExchangeHistoryModel.fromMap(d, id),
              'exchangeHistoryStream',
            ),
      )
          .map(_nonNullList);

  @override
  Stream<List<StepsAndPointsModel>> dailyPointsStream(
      String uid,
      String currentId,
      ) =>
      _service
          .collectionStream(
        path: APIPath.dailyStepsAndPointsStream(uid),
        builder: (data, documentId) =>
            _safeBuild<StepsAndPointsModel>(
              data,
              documentId,
                  (d, id) => StepsAndPointsModel.fromMap(d, id),
              'dailyPointsStream',
            ),
        queryBuilder: (query) => query.where(
          'id',
          isNotEqualTo: currentId,
        ),
      )
          .map(_nonNullList);

  @override
  Future<void> setDailySteps(
      StepsAndPointsModel stepsAndPoints,
      String uid,
      ) async =>
      _service.setData(
        path: APIPath.setDailyStepsAndPoints(uid, stepsAndPoints.id),
        data: stepsAndPoints.toMap(),
      );

  @override
  Future<void> setRewardOrder(RewardModel reward, String uid) async =>
      _service.setData(
        path: APIPath.setMyReward(uid, reward.id),
        data: reward.toMap(),
      );

  @override
  Stream<List<RewardModel>> myRewardsStream(String uid) => _service
      .collectionStream(
    path: APIPath.myRewards(uid),
    builder: (data, documentId) => _safeBuild<RewardModel>(
      data,
      documentId,
          (d, id) => RewardModel.fromMap(d, id),
      'myRewardsStream',
    ),
  )
      .map(_nonNullList);

  @override
  Stream<List<UserModel>> usersStream() => _service
      .collectionStream(
    path: APIPath.users(),
    builder: (data, documentId) => _safeBuild<UserModel>(
      data,
      documentId,
          (d, id) => UserModel.fromMap(d, id),
      'usersStream',
    ),
  )
      .map(_nonNullList);

  @override
  Stream<UserModel> getUserStream(String uid) =>
      _service.documentStream(
        path: APIPath.user(uid),
        builder: (data, documentId) {
          final u = _safeBuild<UserModel>(
            data,
            documentId,
                (d, id) => UserModel.fromMap(d, id),
            'getUserStream',
          );
          if (u != null) return u;
          return UserModel(
            uid: documentId,
            name: 'Guest',
            totalSteps: 0,
            healthPoints: 0,
          );
        },
      );
}
