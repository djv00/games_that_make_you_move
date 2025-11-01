import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_steps_tracker/features/bottom_navbar/presentation/manager/plant/plant_state.dart';


import '../../../../../utilities/constants/api_path.dart';
import '../../../data/models/plant_model.dart';

class PlantCubit extends Cubit<PlantState> {
  PlantCubit() : super(const PlantState());

  /// 进入页面时加载
  Future<void> load() async {
    emit(state.copyWith(loading: true));

    final uid = await _uid();
    final userRef = FirebaseFirestore.instance.doc(APIPath.user(uid));
    final plantRef = FirebaseFirestore.instance.doc(APIPath.plant(uid));

    final userSnap = await userRef.get();
    final plantSnap = await plantRef.get();

    final userPoints = (userSnap.data()?['healthPoints'] ?? 0) as int;

    PlantModel plant;
    if (plantSnap.exists) {
      plant = PlantModel.fromMap(plantSnap.data()!);
    } else {
      plant = PlantModel(level: 1, progress: 0);
      await plantRef.set(plant.toMap());
    }

    emit(
      state.copyWith(
        loading: false,
        plant: plant,
        userPoints: userPoints,
      ),
    );
  }

  /// 浇水：扣 5 分，加 25 进度，进度满100升一级清零
  Future<void> water() async {
    if (state.loading) return;
    if (state.userPoints < 5) {
      emit(state.copyWith(error: '积分不足（需要 5）'));
      return;
    }

    emit(state.copyWith(loading: true));

    final uid = await _uid();
    final userRef = FirebaseFirestore.instance.doc(APIPath.user(uid));
    final plantRef = FirebaseFirestore.instance.doc(APIPath.plant(uid));

    await FirebaseFirestore.instance.runTransaction((tx) async {
      // user
      final userSnap = await tx.get(userRef);
      final curHP = (userSnap.data()?['healthPoints'] ?? 0) as int;

      // plant
      final plantSnap = await tx.get(plantRef);
      final plantData = plantSnap.data() ?? {};
      final plant = PlantModel.fromMap(plantData);

      if (curHP < 5) {
        throw Exception('NOT_ENOUGH_POINTS');
      }

      // 业务：+25
      int newProgress = plant.progress + 25;
      int newLevel = plant.level;
      if (newProgress >= 100) {
        newLevel += 1;
        newProgress = 0;
      }

      tx.update(userRef, {
        'healthPoints': curHP - 5,
      });
      tx.set(plantRef, {
        'level': newLevel,
        'progress': newProgress,
        'lastWateredAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }).then((_) async {
      // 事务成功后再读一次刷新
      await load();
    }).catchError((e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    });
  }

  Future<String> _uid() async {
    final user = FirebaseAuth.instance.currentUser ??
        (await FirebaseAuth.instance.signInAnonymously()).user!;
    return user.uid;
  }
}
