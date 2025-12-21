// 레거시 호환을 위한 re-export 파일
// 새 코드에서는 models/saju_info.dart와 services/saju_storage_service.dart를 직접 사용하세요.

export 'models/saju_info.dart';
export 'services/saju_storage_service.dart';

// 레거시 함수들 - 기존 코드와의 호환성 유지용
import 'models/saju_info.dart';
import 'services/saju_storage_service.dart';

/// @deprecated 대신 sajuStorage.loadSajuList()를 사용하세요.
Future<List<SajuInfo>> loadSajuList() => sajuStorage.loadSajuList();

/// @deprecated 대신 sajuStorage.saveSajuList()를 사용하세요.
Future<void> saveSajuList(List<SajuInfo> list) => sajuStorage.saveSajuList(list);

/// @deprecated 대신 sajuStorage.addSaju()를 사용하세요.
Future<void> addSaju(SajuInfo saju) => sajuStorage.addSaju(saju);

/// @deprecated 대신 sajuStorage.deleteSaju()를 사용하세요.
Future<void> deleteSaju(SajuInfo target) => sajuStorage.deleteSaju(target);
