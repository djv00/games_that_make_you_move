import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_steps_tracker/core/domain/use_cases/use_case.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/data/models/reward_model.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/domain/use_cases/earn_reward_use_case.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/domain/use_cases/get_rewards_use_case.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/domain/use_cases/get_user_data_use_case.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/manager/rewards/rewards_state.dart';
import 'package:flutter_steps_tracker/generated/l10n.dart';
import 'package:injectable/injectable.dart';

@injectable
class RewardsCubit extends Cubit<RewardsState> {
  final GetRewardsUseCase _getRewardsUseCase;
  final GetUserDataUseCase _getUserDataUseCase;
  final EarnARewardUseCase _earnARewardUseCase;

  late Stream<List<RewardModel>> _rewardsStream;

  RewardsCubit(
      this._getRewardsUseCase,
      this._getUserDataUseCase,
      this._earnARewardUseCase,
      ) : super(const RewardsState.initial());

  // 拿当前用户的积分
  Future<void> getUserPoints() async {
    emit(const RewardsState.loading());
    final result = await _getUserDataUseCase(NoParams());
    result.fold(
          (failure) => emit(
        RewardsState.userDataError(message: S.current.somethingWentWrong),
      ),
          (userStream) => userStream.listen(
            (user) => emit(
          RewardsState.userDataLoaded(points: user.healthPoints),
        ),
      ),
    );
  }

  // 兑换奖励（下面的 use case/仓库里已经会顺便写 exchanges 了）
  Future<void> earnAReward(RewardModel reward) async {
    emit(const RewardsState.earnLoading());
    final result = await _earnARewardUseCase(reward);
    emit(
      result.fold(
            (failure) =>
            RewardsState.earnError(message: S.current.somethingWentWrong),
            (_) => const RewardsState.earnLoaded(),
      ),
    );
  }

  // 奖励列表
  void getRewards() {
    emit(const RewardsState.loading());
    _rewardsStream = _getRewardsUseCase(NoParams());
    _rewardsStream.listen(onRewardsReceived).onError(onRewardsError);
  }

  void onRewardsReceived(List<RewardModel> rewards) {
    debugPrint('Rewards Length: ${rewards.length}');
    emit(RewardsState.loaded(rewards: rewards));
  }

  void onRewardsError(error) {
    debugPrint('onRewardsError: $error');
    emit(RewardsState.error(message: S.current.somethingWentWrong));
  }
}
