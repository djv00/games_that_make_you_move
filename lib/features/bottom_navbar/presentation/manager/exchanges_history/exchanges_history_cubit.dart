import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_steps_tracker/core/domain/use_cases/use_case.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/data/models/exchange_history_model.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/domain/use_cases/get_exchanges_history_use_case.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/manager/exchanges_history/exchanges_history_state.dart';
import 'package:flutter_steps_tracker/generated/l10n.dart';
import 'package:flutter_steps_tracker/utilities/constants/api_path.dart';
import 'package:injectable/injectable.dart';

@injectable
class ExchangesHistoryCubit extends Cubit<ExchangesHistoryState> {
  final GetHistoryExchangesUseCase _getExchangesHistoryUseCase;

  StreamSubscription<List<ExchangeHistoryModel>>? _sub;

  ExchangesHistoryCubit(this._getExchangesHistoryUseCase)
      : super(const ExchangesHistoryState.initial());

  Future<void> getExchangesHistory() async {
    emit(const ExchangesHistoryState.loading());

    final result = await _getExchangesHistoryUseCase(NoParams());
    result.fold(
          (_) {
        emit(
          ExchangesHistoryState.error(
            message: S.current.somethingWentWrong,
          ),
        );
      },
          (exchangesStream) {
        // 防止重复订阅
        _sub?.cancel();
        _sub = exchangesStream.listen(
          onExchangesReceived,
          onError: onExchangesError,
        );
      },
    );
  }

  void onExchangesReceived(List<ExchangeHistoryModel> exchanges) {
    debugPrint('Exchanges Length: ${exchanges.length}');
    emit(ExchangesHistoryState.loaded(exchanges: exchanges));
  }

  void onExchangesError(Object error) {
    debugPrint('onExchangesError: $error');
    emit(
      ExchangesHistoryState.error(
        message: S.current.somethingWentWrong,
      ),
    );
  }

  /// 删除一条兑换记录：点 “Done” 时调这个
  Future<void> deleteExchange(String id) async {
    try {
      // 1. 保证有用户
      final user = FirebaseAuth.instance.currentUser ??
          (await FirebaseAuth.instance.signInAnonymously()).user!;
      final uid = user.uid;

      // 2. 删 Firestore: users/{uid}/exchanges/{id}
      await FirebaseFirestore.instance
          .doc('${APIPath.exchangesHistory(uid)}$id')
          .delete();

      // 3. 这里不用手动 emit，因为我们上面订阅的是流，
      // Firestore 删掉之后会自己触发 onExchangesReceived
    } catch (e, st) {
      debugPrint('deleteExchange error: $e\n$st');
      // 给个轻量的错误态即可
      emit(
        ExchangesHistoryState.error(
          message: S.current.somethingWentWrong,
        ),
      );
      // 删失败的话再拉一遍，防止前端显示不一致
      await getExchangesHistory();
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
