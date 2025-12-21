# 커밋 메시지

## 주요 변경사항

### 1. GCS 대화 내용 불러오기 기능 추가
- `GPTService.loadChatHistory()` 함수 추가
- 앱 실행 시 APP_UID, 이름, 생년월일 기반으로 GCS에서 대화 내용 자동 로드
- POST 요청 방식으로 변경 및 session_id 지원
- 서버 응답 형식에 맞게 turns 데이터 파싱

### 2. 반응형 UI 구현
- `Saju_ChatScreen`에 반응형 레이아웃 추가
- 큰 화면(800px 이상)에서 좌우 분할 레이아웃 지원
- 좌측: 사주 목록 패널 (고정 너비 400px)
- 우측: 채팅 대화창 (확장 가능)
- 작은 화면에서는 기존 단일 레이아웃 유지

### 3. 월주 계산 로직 개선
- `CalculatorGanji.dart`의 `getWolJuFromDate()` 함수 개선
- `ganji_calculator.dart`의 `getWolJu()` 함수 추가
- 절기 기준 월 인덱스 계산 정확도 향상
- 소한 이전 날짜 처리 로직 개선

### 4. 코드 구조 개선
- 새로운 서비스 레이어 추가 (`services/`)
  - `ganji_calculator.dart`: 간지 계산 서비스
  - `daewoon_calculator.dart`: 대운 계산 서비스
  - `sipsin_calculator.dart`: 십성 계산 서비스
  - `saju_storage_service.dart`: 사주 데이터 저장/로드 서비스
- 새로운 모델 추가 (`models/`)
  - `saju_info.dart`: 사주 정보 모델
  - `selected_saju_data.dart`: 선택된 사주 데이터 모델
- 상수 정의 분리 (`constants/`)
  - `saju_constants.dart`: 사주 관련 상수
  - `storage_keys.dart`: SharedPreferences 키 상수

### 5. 화면 개선
- `home_screen.dart`: 홈 화면 UI/UX 개선
- `saju_list_screen.dart`: 사주 목록 화면 리팩토링
- `saju_input_screen.dart`: 사주 입력 화면 개선
- `saju_result_screen.dart`: 사주 결과 화면 개선
- `fortune_screen.dart`: 운세 화면 개선
- `LoginScreen.dart`: 로그인 화면 개선

### 6. 기타
- `Calcurator_ganji.dart` 파일 삭제 (오타 수정)
- `SajuProvider.dart`: 상태 관리 개선
- `SharedPreferences.dart`: 코드 정리 및 최적화

## 통계
- 18개 파일 수정
- 2,531줄 추가
- 2,095줄 삭제
- 5개 새 파일 추가

