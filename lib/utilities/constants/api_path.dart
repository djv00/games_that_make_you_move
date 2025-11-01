class APIPath {
  static String user(String uid) => 'users/$uid';
  static String users() => 'users/';

  static String setDailyStepsAndPoints(String uid, String id) =>
      'users/$uid/dailyPoints/$id';

  static String setMyReward(String uid, String id) => 'users/$uid/rewards/$id';

  static String myRewards(String uid) => 'users/$uid/rewards/';

  static String dailyStepsAndPointsStream(String uid) =>
      'users/$uid/dailyPoints/';

  static String rewards() => 'rewards/';

  static String exchangeHistory(String uid, String exchangeId) =>
      'users/$uid/exchanges/$exchangeId';

  static String exchangesHistory(String uid) => 'users/$uid/exchanges/';

  // 🌱 植物：固定一盆，叫 main
  static String plant(String uid) => 'users/$uid/plant/main';

  // 👇新增：植物状态放这里
  static String userPlant(String uid) => 'users/$uid/plant';
  static String userPlantWaterLogs(String uid) => 'users/$uid/plant/waterLogs/';

  // 如果你以后想看浇水记录可以用这个（先加上，不一定马上用）
  static String plantWaterLogs(String uid) => 'users/$uid/plant/main/waterLogs';

  // 单条浇水记录
  static String plantWaterLog(String uid, String logId) =>
      'users/$uid/plant/main/waterLogs/$logId';

}
