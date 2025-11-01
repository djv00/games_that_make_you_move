
import '../../../data/models/plant_model.dart';

class PlantState {
  final bool loading;
  final PlantModel? plant;
  final int userPoints;   // 当前用户积分，方便按钮判断
  final String? error;

  const PlantState({
    this.loading = false,
    this.plant,
    this.userPoints = 0,
    this.error,
  });

  PlantState copyWith({
    bool? loading,
    PlantModel? plant,
    int? userPoints,
    String? error,
  }) {
    return PlantState(
      loading: loading ?? this.loading,
      plant: plant ?? this.plant,
      userPoints: userPoints ?? this.userPoints,
      error: error,
    );
  }
}
