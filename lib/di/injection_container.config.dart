// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter_steps_tracker/core/data/data_sources/cache_helper.dart'
    as _i278;
import 'package:flutter_steps_tracker/core/data/data_sources/database.dart'
    as _i92;
import 'package:flutter_steps_tracker/di/app_module.dart' as _i461;
import 'package:flutter_steps_tracker/features/bottom_navbar/data/repositories/bottom_navbar_repository_impl.dart'
    as _i1023;
import 'package:flutter_steps_tracker/features/bottom_navbar/domain/repositories/bottom_navbar_repository.dart'
    as _i958;
import 'package:flutter_steps_tracker/features/bottom_navbar/domain/use_cases/earn_reward_use_case.dart'
    as _i27;
import 'package:flutter_steps_tracker/features/bottom_navbar/domain/use_cases/get_exchanges_history_use_case.dart'
    as _i795;
import 'package:flutter_steps_tracker/features/bottom_navbar/domain/use_cases/get_rewards_use_case.dart'
    as _i830;
import 'package:flutter_steps_tracker/features/bottom_navbar/domain/use_cases/get_user_data_use_case.dart'
    as _i862;
import 'package:flutter_steps_tracker/features/bottom_navbar/domain/use_cases/get_users_use_case.dart'
    as _i963;
import 'package:flutter_steps_tracker/features/bottom_navbar/domain/use_cases/set_exchange_history_use_case.dart'
    as _i636;
import 'package:flutter_steps_tracker/features/bottom_navbar/domain/use_cases/set_steps_and_points_use_case.dart'
    as _i102;
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/manager/exchanges_history/exchanges_history_cubit.dart'
    as _i150;
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/manager/home/home_cubit.dart'
    as _i430;
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/manager/leaderboard/leaderboard_cubit.dart'
    as _i787;
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/manager/rewards/rewards_cubit.dart'
    as _i451;
import 'package:flutter_steps_tracker/features/intro/data/data_sources/auth_local_data_source.dart'
    as _i425;
import 'package:flutter_steps_tracker/features/intro/data/data_sources/auth_remote_data_source.dart'
    as _i514;
import 'package:flutter_steps_tracker/features/intro/data/repositories/auth_repository_impl.dart'
    as _i895;
import 'package:flutter_steps_tracker/features/intro/data/services/auth_services.dart'
    as _i796;
import 'package:flutter_steps_tracker/features/intro/domain/repositories/auth_repository.dart'
    as _i1002;
import 'package:flutter_steps_tracker/features/intro/domain/use_cases/auth_status_use_case.dart'
    as _i726;
import 'package:flutter_steps_tracker/features/intro/domain/use_cases/sign_in_anonymously_use_case.dart'
    as _i17;
import 'package:flutter_steps_tracker/features/intro/presentation/manager/auth_actions/auth_cubit.dart'
    as _i481;
import 'package:flutter_steps_tracker/features/intro/presentation/manager/auth_status/auth_status_cubit.dart'
    as _i763;
import 'package:flutter_steps_tracker/utilities/locale/cubit/utility_cubit.dart'
    as _i962;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final appModule = _$AppModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => appModule.prefs,
      preResolve: true,
    );
    gh.factory<_i962.UtilityCubit>(() => _i962.UtilityCubit());
    gh.singleton<_i425.AuthLocalDataSource>(
        () => _i425.AuthLocalDataSourceImpl(gh<_i460.SharedPreferences>()));
    gh.singleton<_i796.AuthBase>(() => _i796.Auth());
    gh.singleton<_i92.Database>(() => _i92.FireStoreDatabase());
    gh.singleton<_i278.CacheHelper>(
        () => _i278.CacheHelperImpl(gh<_i460.SharedPreferences>()));
    gh.singleton<_i958.BottomNavbarRepository>(
        () => _i1023.BottomNavbarRepositoryImpl(
              gh<_i92.Database>(),
              gh<_i425.AuthLocalDataSource>(),
            ));
    gh.singleton<_i514.AuthRemoteDataSource>(
        () => _i514.AuthRemoteDataSourceImpl(authBase: gh<_i796.AuthBase>()));
    gh.factory<_i27.EarnARewardUseCase>(
        () => _i27.EarnARewardUseCase(gh<_i958.BottomNavbarRepository>()));
    gh.factory<_i795.GetHistoryExchangesUseCase>(() =>
        _i795.GetHistoryExchangesUseCase(gh<_i958.BottomNavbarRepository>()));
    gh.factory<_i830.GetRewardsUseCase>(
        () => _i830.GetRewardsUseCase(gh<_i958.BottomNavbarRepository>()));
    gh.factory<_i963.GetUsersUseCase>(
        () => _i963.GetUsersUseCase(gh<_i958.BottomNavbarRepository>()));
    gh.factory<_i862.GetUserDataUseCase>(
        () => _i862.GetUserDataUseCase(gh<_i958.BottomNavbarRepository>()));
    gh.factory<_i636.SetExchangeHistoryUseCase>(() =>
        _i636.SetExchangeHistoryUseCase(gh<_i958.BottomNavbarRepository>()));
    gh.factory<_i102.SetStepsAndPointsUseCase>(() =>
        _i102.SetStepsAndPointsUseCase(gh<_i958.BottomNavbarRepository>()));
    gh.factory<_i787.LeaderboardCubit>(
        () => _i787.LeaderboardCubit(gh<_i963.GetUsersUseCase>()));
    gh.factory<_i150.ExchangesHistoryCubit>(() =>
        _i150.ExchangesHistoryCubit(gh<_i795.GetHistoryExchangesUseCase>()));
    gh.singleton<_i1002.AuthRepository>(() => _i895.AuthRepositoryImpl(
          gh<_i514.AuthRemoteDataSource>(),
          gh<_i425.AuthLocalDataSource>(),
          gh<_i92.Database>(),
        ));
    gh.factory<_i451.RewardsCubit>(() => _i451.RewardsCubit(
          gh<_i830.GetRewardsUseCase>(),
          gh<_i862.GetUserDataUseCase>(),
          gh<_i27.EarnARewardUseCase>(),
        ));
    gh.factory<_i430.HomeCubit>(() => _i430.HomeCubit(
          gh<_i636.SetExchangeHistoryUseCase>(),
          gh<_i102.SetStepsAndPointsUseCase>(),
          gh<_i862.GetUserDataUseCase>(),
        ));
    gh.factory<_i726.AuthStatusUseCase>(
        () => _i726.AuthStatusUseCase(gh<_i1002.AuthRepository>()));
    gh.factory<_i17.SignInAnonymouslyUseCase>(() =>
        _i17.SignInAnonymouslyUseCase(
            authRepository: gh<_i1002.AuthRepository>()));
    gh.singleton<_i763.AuthStatusCubit>(
        () => _i763.AuthStatusCubit(gh<_i726.AuthStatusUseCase>()));
    gh.singleton<_i481.AuthCubit>(
        () => _i481.AuthCubit(gh<_i17.SignInAnonymouslyUseCase>()));
    return this;
  }
}

class _$AppModule extends _i461.AppModule {}
