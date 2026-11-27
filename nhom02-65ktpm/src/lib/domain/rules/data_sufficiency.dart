import '../../core/constants/app_config.dart';
import 'weekly_stats.dart';

/// Tiêu chí "đủ dữ liệu" (mục 7.2): tuần có ít nhất 4 ngày có ghi nhận.
///
/// Không đủ dữ liệu -> báo cáo vẫn hiện số liệu thô nhưng KHÔNG sinh nhận xét
/// và KHÔNG đề xuất thử thách dựa trên tuần đó.
class DataSufficiency {
  DataSufficiency._();

  static bool isSufficient(
    WeeklyStats stats, {
    int minLoggedDays = AppConfig.minLoggedDaysForSufficientWeek,
  }) {
    return stats.loggedDays >= minLoggedDays;
  }
}
