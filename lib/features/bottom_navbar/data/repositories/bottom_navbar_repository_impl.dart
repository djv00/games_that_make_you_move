import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_steps_tracker/core/data/data_sources/database.dart';
import 'package:flutter_steps_tracker/core/data/error/exceptions/application_exception.dart';
import 'package:flutter_steps_tracker/core/data/error/failures/application_failure.dart';
import 'package:flutter_steps_tracker/core/data/models/steps_and_points_model.dart';
import 'package:flutter_steps_tracker/core/data/models/user_model.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/data/models/exchange_history_model.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/data/models/reward_model.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/domain/repositories/bottom_navbar_repository.dart';
import 'package:flutter_steps_tracker/features/intro/data/data_sources/auth_local_data_source.dart';
import 'package:injectable/injectable.dart';

@Singleton(as: BottomNavbarRepository)
class BottomNavbarRepositoryImpl implements BottomNavbarRepository {
  final Database _database;
  final AuthLocalDataSource _authLocalDataSource;

  BottomNavbarRepositoryImpl(
      this._database,
      this._authLocalDataSource,
      );

  Failure _asFailure(Object e) {
    if (e is ApplicationException) {
      return firebaseExceptionsDecoder(e);
    }
    return GenericFailure(message: 'Something went wrong!');
  }

  // ✅ 统一兜底用户
  Future<UserModel?> _currentUserOrNull() async {
    // 1) 本地
    final cached = await _authLocalDataSource.currentUser();
    if (cached != null && cached.uid.isNotEmpty) {
      return cached;
    }

    // 2) FirebaseAuth
    final fb.FirebaseAuth auth = fb.FirebaseAuth.instance;
    fb.User? fbUser = auth.currentUser;

    // 🟣 没有就匿名登录
    if (fbUser == null) {
      final cred = await auth.signInAnonymously();
      fbUser = cred.user;
    }

    if (fbUser == null) {
      return null;
    }

    final String uid = fbUser.uid;

    try {
      // 3) Firestore 拉一遍
      UserModel remoteUser;
      try {
        remoteUser = await _database.getUserStream(uid).first;
      } catch (_) {
        // 没有就创建
        remoteUser = UserModel(
          uid: uid,
          name: fbUser.displayName ?? 'Guest',
          totalSteps: 0,
          healthPoints: 0,
        );
        await _database.setUserData(remoteUser);
      }

      // 4) 写回本地
      await _authLocalDataSource.persistAuth(remoteUser);
      return remoteUser;
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------
  // Rewards
  // ------------------------------------------------
  @override
  Stream<List<RewardModel>> rewardsStream() {
    return _database.rewardsStream();
  }

  // ------------------------------------------------
  // Exchanges
  // ------------------------------------------------
  @override
  Future<Either<Failure, bool>> setExchangeHistory(
      ExchangeHistoryModel exchangeHistory,
      ) async {
    try {
      final user = await _currentUserOrNull();
      if (user == null || user.uid.isEmpty) {
        return Left(GenericFailure(message: 'Unauthorized (exchange)'));
      }
      await _database.setExchangeHistory(exchangeHistory, user.uid);
      return const Right(true);
    } catch (e) {
      return Left(_asFailure(e));
    }
  }

  @override
  Future<Either<Failure, Stream<List<ExchangeHistoryModel>>>>
  exchangesHistoryStream() async {
    try {
      final user = await _currentUserOrNull();
      if (user == null || user.uid.isEmpty) {
        return Left(
            GenericFailure(message: 'Unauthorized (exchanges stream)'));
      }
      final stream = _database.exchangeHistoryStream(user.uid);
      return Right(stream);
    } catch (e) {
      return Left(_asFailure(e));
    }
  }

  // ------------------------------------------------
  // Steps & points
  // ------------------------------------------------
  @override
  Future<Either<Failure, bool>> setStepsAndPoints(int steps) async {
    try {
      final user = await _currentUserOrNull();
      if (user == null || user.uid.isEmpty) {
        return Left(GenericFailure(message: 'Unauthorized (steps)'));
      }

      final int healthPoints = (steps ~/ 100) * 5;

      await _database.setDailySteps(
        StepsAndPointsModel(
          id: documentIdForDailyUse(),
          steps: steps,
          points: healthPoints,
        ),
        user.uid,
      );

      final myRewards = await _database.myRewardsStream(user.uid).first;
      final int usedPoints =
      myRewards.fold<int>(0, (acc, r) => acc + r.points);
      final int totalHealthPoints = healthPoints - usedPoints;

      final updated = UserModel(
        uid: user.uid,
        name: user.name,
        totalSteps: steps,
        healthPoints: totalHealthPoints,
      );
      await _database.setUserData(updated);
      await _authLocalDataSource.persistAuth(updated);

      return const Right(true);
    } catch (e) {
      return Left(_asFailure(e));
    }
  }

  // ------------------------------------------------
  // Single user
  // ------------------------------------------------
  @override
  Future<Either<Failure, UserModel>> getUserData() async {
    try {
      final user = await _currentUserOrNull();
      if (user == null) {
        return Left(GenericFailure(message: 'Unauthorized (getUserData)'));
      }
      return Right(user);
    } catch (e) {
      return Left(_asFailure(e));
    }
  }

  @override
  Future<Either<Failure, Stream<UserModel>>> getRealTimeUserData() async {
    try {
      final user = await _currentUserOrNull();
      if (user == null || user.uid.isEmpty) {
        return Left(GenericFailure(message: 'Unauthorized (user stream)'));
      }
      return Right(_database.getUserStream(user.uid));
    } catch (e) {
      return Left(_asFailure(e));
    }
  }

  // ------------------------------------------------
  // Earn reward  ✅这里加写exchange
  // ------------------------------------------------
  @override
  Future<Either<Failure, bool>> earnAReward(RewardModel reward) async {
    try {
      final user = await _currentUserOrNull();
      if (user == null || user.uid.isEmpty) {
        return Left(GenericFailure(message: 'Unauthorized (earn reward)'));
      }

      // 1. 写入我的奖励
      // 如果你的 RewardModel 没有 copyWith，就把这一行改成
      // await _database.setRewardOrder(reward..id = documentIdFromLocalGenerator(), user.uid);
      await _database.setRewardOrder(
        reward.copyWith(id: documentIdFromLocalGenerator()),
        user.uid,
      );

      // 2. 扣积分
      final realUser = await _database.getUserStream(user.uid).first;
      await _database.setUserData(
        realUser.copyWith(
          healthPoints: realUser.healthPoints - reward.points,
        ),
      );

      // 3. 同步写兑换历史（Exchanges）
      await _database.setExchangeHistory(
        ExchangeHistoryModel(
          id: '', // 交给 Database 那层去兜id
          title: reward.name,
          points: reward.points,
          date: DateTime.now().toIso8601String(),
        ),
        user.uid,
      );

      return const Right(true);
    } catch (e) {
      return Left(_asFailure(e));
    }
  }

  // ------------------------------------------------
  // Leaderboard
  // ------------------------------------------------
  @override
  Future<Either<Failure, Stream<List<UserModel>>>> usersStream() async {
    try {
      // 先保证当前用户存在
      await _currentUserOrNull();
      return Right(_database.usersStream());
    } catch (e) {
      return Left(_asFailure(e));
    }
  }
}
