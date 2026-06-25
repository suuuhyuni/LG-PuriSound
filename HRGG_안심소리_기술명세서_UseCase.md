# HRGG - 안심소리 기술명세서 및 Use Case

작성일: 2026-06-09  
대상 디바이스: iOS, iPhone 15 Pro, 393 x 852px  
제품명: HRGG - 안심소리  
서비스 성격: AI 기반 층간소음 감지 및 사운드 마스킹 홈 디바이스 컨트롤러

## 1. 개요

### 1.1 목적

HRGG - 안심소리는 아파트 거주자가 층간 충격음, 교통 소음, 생활 대화음 등 반복적이고 예측 가능한 소음 스트레스를 줄일 수 있도록 돕는 모바일 컨트롤러 앱이다. 앱은 HRGG Speaker 디바이스와 연동하여 실시간 소음 모니터링, AI 소음 유형 분류, 자동 마스킹, 상황별 모드, 스케줄, 리포트, LED 및 알림 설정을 제공한다.

### 1.2 참고 자료 반영 사항

작업 폴더 내 PNG 레퍼런스 화면과 제공 프롬프트를 기준으로 다음 흐름을 명세화한다.

- 온보딩, 회원가입, 로그인, 디바이스 등록, 초기 설정
- 홈 대시보드, 실시간 모니터링, 노이즈 선택, 나의 모드, 커스텀 모드 편집
- 스케줄, AI 추천 스케줄, 리포트, LED, 민감도, 디바이스 관리, 알림, 마이페이지, 로그아웃 확인
- LG ThinQ 스타일의 밝은 카드형 UI, 중립 그레이 계층, 마젠타 포인트 컬러
- Light Mode와 Dark Mode의 색상 변수 기반 전환
- 노이즈 선택 화면의 실제 파형 미니 비주얼라이저
- 정보구조 변경: `나의 모드`는 마이페이지 내부 섹션이 아니라 하단 탭의 독립 메뉴로 제공

## 2. 정보구조 및 내비게이션

### 2.1 하단 탭 구조

기존 4탭 구조는 사용성 요구에 따라 5탭 구조로 변경한다.

1. 홈
2. 모니터링
3. 나의 모드
4. 리포트
5. 마이페이지

`나의 모드`는 모니터링과 리포트 사이에 위치한다. 사용자는 홈의 퀵 액션 또는 하단 탭을 통해 모드 화면에 직접 접근할 수 있다. 마이페이지에서는 `나의 모드` 가로 카드 섹션을 제거하고, 서비스 설정 목록의 `모드 관리` 항목만 유지할 수 있다.

### 2.2 주요 화면 목록

| 번호 | 화면명 | 역할 |
|---|---|---|
| 01 | Splash | 앱 진입, 시작하기/로그인 분기 |
| 02 | SignUp | 계정 생성 및 약관 동의 |
| 03 | Login | 인증 및 최초/재방문 분기 |
| 04 | DeviceRegister | HRGG Speaker 검색 및 등록 |
| 05 | InitialSetup | 기본 노이즈, 음량, 민감도, Local Zone 설정 |
| 06 | Home | 디바이스 상태, 자동 마스킹, 추천, 최근 활동 |
| 07 | Monitor | 실시간 dB, 주파수 분석, 개입 판단 상태 |
| 08 | NoiseSelect | AI/수동 마스킹 사운드 선택 및 재생 |
| 09 | MyModes | 독립 탭 메뉴. 상황별 모드 선택 및 관리 |
| 10 | ModeEdit | 커스텀 모드 상세 편집 |
| 11 | Schedule | 주간 스케줄 및 모드 연동 설정 |
| 12 | AIRecommend | AI 반복 소음 패턴 기반 스케줄 추천 |
| 13 | Report | 7일/30일 소음 통계 및 PDF 저장 |
| 14 | LED | 디바이스 LED 색상/밝기/연동 제어 |
| 15 | Sensitivity | 개입 민감도 및 자동 최적화 설정 |
| 16 | DeviceManage | 디바이스 상태, 권한, 재시작, 초기화 |
| 17 | Notifications | 소음/디바이스/리포트 알림 설정 |
| 18 | MyPage | 계정, 서비스 설정, 화면 설정, 앱 정보 |
| 19 | LogoutConfirm | 로그아웃 확인 Bottom Sheet |

## 3. 디자인 시스템 명세

### 3.1 테마 변수

모든 색상은 Figma Variables로 관리하며 Light/Dark 모드를 동일 컴포넌트에 적용한다.

| Token | Light | Dark |
|---|---:|---:|
| Primary Accent | `#E6007E` | `#E6007E` |
| Secondary Accent | `#C0006A` | `#FF3DAC` |
| Background | `#F7F7F7` | `#0D0D0D` |
| Surface Card | `#FFFFFF` | `#1C1C1E` |
| Surface Elevated | `#F0F0F5` | `#2C2C2E` |
| Border | `#E5E5EA` | `#3A3A3C` |
| Text Primary | `#1A1A1A` | `#F2F2F7` |
| Text Secondary | `#6D6D72` | `#AEAEB2` |
| Text Tertiary | `#AEAEB2` | `#6D6D72` |
| On Accent | `#FFFFFF` | `#FFFFFF` |

### 3.2 노이즈 및 상태 색상

| 분류 | 색상 | 용도 |
|---|---:|---|
| Brown Noise | `#A0522D` | 층간 충격음, 저주파 |
| Pink Noise | `#D96B8A` | 교통/실외기, 중고주파 |
| White Noise | `#7B8FA1` | 생활/대화음, 전 대역 |
| Active | `#34C759` | 연결됨, 정상, ON |
| Warning | `#FF9500` | 미연결, 권한 경고 |
| Error | `#FF3B30` | 인증 실패, 스피커 오류 |
| Inactive | `#C7C7CC` | OFF, 비활성 |

### 3.3 타이포그래피

기본 폰트는 Pretendard를 사용하고, 영문/시스템 fallback은 SF Pro Display를 사용한다.

| Style | Size | Weight | Usage |
|---|---:|---:|---|
| Display | 28px | 700 | 로그인 타이틀, 주요 수치 |
| Heading 1 | 22px | 600 | 화면 제목, 섹션 대표 제목 |
| Heading 2 | 17px | 600 | 카드 제목, 리스트 제목 |
| Body | 15px | 400 | 일반 본문 |
| Body Bold | 15px | 600 | 강조 본문, 버튼 |
| Caption | 13px | 400 | 보조 설명 |
| Micro | 11px | 500 | 칩, 상태 라벨 |

### 3.4 공통 컴포넌트

| 컴포넌트 | 명세 |
|---|---|
| Bottom Tab Bar | 높이 83px. 5탭: 홈, 모니터링, 나의 모드, 리포트, 마이페이지. 활성 아이콘/라벨은 `#E6007E`, 비활성은 Text Tertiary. |
| Standard Card | radius 16px, Surface Card, border 1px Border, shadow `0 2px 8px rgba(0,0,0,0.12)` |
| Noise Type Card | 좌측 5px 노이즈 컬러 스트라이프, 미니 파형, 텍스트, 라디오/체크 |
| Mode Card | 모드 컬러 기반 gradient, icon 48px, 설정 요약, 설명, 선택 시 3px 마젠타 ring |
| Primary CTA | height 54px, radius 12px, fill `#E6007E`, white 17px semibold |
| Secondary Button | height 54px, radius 12px, 1.5px magenta border, magenta label |
| Toggle | 51 x 31px, ON `#E6007E`, OFF `#C7C7CC`, 200ms spring |
| Chip/Badge | 상태/노이즈/모드/정보용. Chips radius 20px, Status badge radius 8px |
| Input Field | height 52px, radius 10px, focus border 2px magenta |
| Slider | track 4px, filled magenta, thumb 24px white with shadow |
| Theme Toggle | 홈 및 마이페이지 헤더에 표시. 전체 변수 모드 전환 |

## 4. 기능 명세

### 4.1 인증 및 계정

- 회원가입은 이름, 이메일, 비밀번호, 비밀번호 확인, 필수 약관 2개 동의를 요구한다.
- 이메일 중복 또는 형식 오류 발생 시 입력 필드에 red border와 인라인 에러 메시지를 표시한다.
- 로그인 성공 후 디바이스 등록 이력이 없으면 `DeviceRegister`로 이동한다.
- 로그인 성공 후 등록된 디바이스가 있으면 `Home`으로 이동한다.
- 로그아웃 시 로컬 세션만 종료하며, 디바이스는 기존 마스킹 설정을 유지한다.

### 4.2 디바이스 등록 및 관리

- 앱은 동일 Wi-Fi 환경에서 HRGG Speaker를 검색한다.
- 등록 시 마이크 권한, 스피커 권한 상태를 칩으로 표시한다.
- 디바이스를 찾지 못하면 orange warning banner를 노출한다.
- 권한 거부 시 red card와 `설정 열기` 버튼을 제공한다.
- 디바이스 관리 화면은 모델명, 펌웨어, Wi-Fi, 전원, 마이크 상태를 표시한다.
- 공장 초기화는 confirmation bottom sheet를 통해 재확인한다.

### 4.3 홈 대시보드

- 디바이스 연결 상태를 green dot chip으로 표시한다.
- 활성 모드 badge strip을 상단에 표시한다.
- Hero card는 waveform visualizer, 현재 dB, 활성 노이즈 칩, 자동 마스킹 toggle을 포함한다.
- 퀵 액션은 스케줄, 노이즈 선택, 리포트, 모드로 구성한다.
- AI 추천 배너는 반복 소음 예측 시 노출하며, 선택 시 `AIRecommend`로 이동한다.
- 최근 3개 이벤트를 소음 유형, 시간, dB, 처리 결과와 함께 표시한다.

### 4.4 실시간 모니터링

- dB gauge는 0~100dB 범위를 표시하고 green/orange/red zone으로 위험도를 시각화한다.
- 주파수 분석은 저주파, 중주파, 고주파 3개 그룹으로 표시한다.
- 소음 유형이 분류되면 해당 노이즈 컬러로 활성 밴드를 강조한다.
- 개입 판단 상태는 `감지 -> 5초 분석 중 -> 개입 결정` 타임라인으로 표시한다.
- 지속 시간이 설정된 민감도 임계값을 넘으면 마스킹을 시작한다.

### 4.5 노이즈 선택 및 재생

- AI 자동 선택 toggle이 ON이면 노이즈 타입 카드는 dimmed 상태가 되고 lock icon을 표시한다.
- AI 자동 선택 OFF 상태에서 사용자는 Brown/Pink/White Noise를 수동 선택할 수 있다.
- 각 노이즈 카드는 실제 미니 파형 비주얼라이저를 포함한다.
  - Brown Noise: 낮고 넓은 진폭, 저주파 강조
  - Pink Noise: 중간 높이의 유기적 파형
  - White Noise: 촘촘하고 균일한 고주파 패턴
- 음량 slider와 fade-in speed segmented control을 제공한다.
- `적용 및 재생` 시 디바이스에 noiseType, volume, fadeIn 값을 전송한다.

### 4.6 나의 모드

- `나의 모드`는 하단 탭의 독립 메뉴이며 모니터링과 리포트 사이에 위치한다.
- 화면은 2-column mode card grid로 구성한다.
- 기본 모드는 수면, 베이비, 집중, 교통 소음, 커스텀 모드를 제공한다.
- 선택된 모드는 magenta ring border와 `현재 활성` chip을 표시한다.
- 커스텀 모드 카드는 `모드 편집` text button을 제공한다.
- 적용 버튼을 누르면 선택된 모드 설정을 디바이스에 전송한다.

### 4.7 커스텀 모드 편집

- 사용자는 모드 이름, 아이콘, 마스킹 사운드, 음량, LED 색상, 민감도, 스케줄 연동을 편집할 수 있다.
- Preview card는 설정 변경에 따라 gradient, icon, 설정 요약을 즉시 반영한다.
- 저장 실패 시 `이전 설정 유지됨` 메시지와 `재시도` 버튼을 표시한다.

### 4.8 스케줄 및 AI 추천

- 스케줄은 요일, 시작/종료 시간, 연동 모드로 구성된다.
- AI 추천은 최근 7일 소음 데이터의 반복 패턴을 기반으로 생성한다.
- 추천 카드는 예상 시간, 소음 유형, 신뢰도, 추천 모드, 스케줄 등록/무시 액션을 포함한다.
- 추천을 등록하면 스케줄 화면이 pre-filled 상태로 열린다.

### 4.9 리포트

- 7일/30일 기간 tab을 제공한다.
- 요약 stat grid, 요일별 bar chart, 24h heatmap, 소음 유형 donut chart를 표시한다.
- 수집 데이터가 없으면 empty state와 `모니터링 시작` 버튼을 표시한다.
- PDF 저장은 현재 기간의 차트와 요약을 포함한다.
- 데이터 보관 용량 초과 시 `오래된 학습 데이터가 정리되었습니다` info banner를 표시한다.

### 4.10 LED, 민감도, 알림

- LED는 자동, 모드 연동, 수동 3가지 color mode를 제공한다.
- LED preview circle은 색상과 밝기 변경을 300ms interpolation으로 반영한다.
- 민감도는 낮음, 보통, 높음 기준을 slider와 segmented 값으로 제공한다.
- 알림은 시간 이후 소음, dB 초과, 디바이스 연결 끊김, 주간 리포트 준비 완료 항목을 제공한다.

### 4.11 마이페이지

- 마이페이지는 계정, 서비스 설정, 화면 설정, 앱 정보, 로그아웃/회원탈퇴로 구성한다.
- `나의 모드` 가로 카드 섹션은 제거한다.
- 서비스 설정 목록에는 마스킹 사운드, 스케줄, 민감도, LED, 알림, 디바이스 관리, 모드 관리 항목을 둘 수 있다.
- 화면 설정은 다크 모드 toggle과 `라이트 / 다크 / 시스템` segmented control을 제공한다.

## 5. 데이터 모델

### 5.1 User

| 필드 | 타입 | 설명 |
|---|---|---|
| id | string | 사용자 ID |
| name | string | 사용자 이름 |
| email | string | 이메일 |
| themePreference | enum | light, dark, system |
| createdAt | datetime | 가입일 |

### 5.2 Device

| 필드 | 타입 | 설명 |
|---|---|---|
| id | string | 디바이스 ID |
| name | string | 디바이스 이름 |
| model | string | 모델명 |
| firmwareVersion | string | 펌웨어 버전 |
| connectionStatus | enum | connected, disconnected, error |
| wifiStatus | enum | ok, warning, error |
| powerStatus | enum | ok, warning, error |
| micStatus | enum | ok, denied, error |
| speakerStatus | enum | ok, denied, error |

### 5.3 NoiseEvent

| 필드 | 타입 | 설명 |
|---|---|---|
| id | string | 이벤트 ID |
| timestamp | datetime | 감지 시간 |
| db | number | dB 값 |
| frequencyHz | number | 대표 주파수 |
| band | enum | low, mid, high |
| type | enum | brown, pink, white, unknown |
| result | enum | masked, loggedOnly, failed |
| durationSec | number | 지속 시간 |

### 5.4 MaskingSetting

| 필드 | 타입 | 설명 |
|---|---|---|
| autoSelect | boolean | AI 자동 선택 여부 |
| noiseType | enum | brown, pink, white |
| volume | number | 0~100 |
| fadeInSpeed | enum | soft, normal, instant |
| sensitivity | enum | low, normal, high |
| interventionThresholdSec | number | 개입 기준 지속 시간 |

### 5.5 ModePreset

| 필드 | 타입 | 설명 |
|---|---|---|
| id | string | 모드 ID |
| name | string | 모드명 |
| icon | string | 아이콘/emoji |
| type | enum | sleep, baby, focus, traffic, custom |
| noiseType | enum | brown, pink, white |
| volume | number | 0~100 |
| ledMode | enum | off, auto, mode, manual |
| ledColor | string | HEX 색상 |
| sensitivity | enum | low, normal, high |
| isActive | boolean | 현재 활성 여부 |

### 5.6 Schedule

| 필드 | 타입 | 설명 |
|---|---|---|
| id | string | 스케줄 ID |
| days | string[] | mon~sun |
| startTime | string | HH:mm |
| endTime | string | HH:mm |
| modeId | string | 연동 모드 |
| enabled | boolean | 활성 여부 |

## 6. API 명세 초안

### 6.1 인증

| Method | Endpoint | 설명 |
|---|---|---|
| POST | `/auth/signup` | 회원가입 |
| POST | `/auth/login` | 로그인 |
| POST | `/auth/logout` | 로그아웃 |
| GET | `/users/me` | 내 계정 조회 |
| PATCH | `/users/me` | 프로필 및 화면 설정 수정 |

### 6.2 디바이스

| Method | Endpoint | 설명 |
|---|---|---|
| GET | `/devices/discover` | 동일 Wi-Fi 디바이스 검색 |
| POST | `/devices/register` | 디바이스 등록 |
| GET | `/devices/{deviceId}` | 디바이스 상세 조회 |
| PATCH | `/devices/{deviceId}` | 디바이스 이름/설정 변경 |
| POST | `/devices/{deviceId}/restart` | 디바이스 재시작 |
| POST | `/devices/{deviceId}/factory-reset` | 공장 초기화 |
| GET | `/devices/{deviceId}/health` | Wi-Fi, 전원, 마이크, 스피커 상태 |

### 6.3 모니터링 및 마스킹

| Method | Endpoint | 설명 |
|---|---|---|
| GET | `/devices/{deviceId}/live` | 실시간 dB, 주파수, 감지 상태 스트림 |
| GET | `/devices/{deviceId}/events` | 최근 소음 이벤트 목록 |
| POST | `/devices/{deviceId}/masking/start` | 마스킹 시작 |
| POST | `/devices/{deviceId}/masking/stop` | 마스킹 중지 |
| PATCH | `/devices/{deviceId}/masking/settings` | 노이즈, 음량, fade-in, 민감도 설정 |

### 6.4 모드/스케줄/리포트

| Method | Endpoint | 설명 |
|---|---|---|
| GET | `/modes` | 모드 목록 조회 |
| POST | `/modes` | 커스텀 모드 생성 |
| PATCH | `/modes/{modeId}` | 모드 수정 |
| POST | `/modes/{modeId}/activate` | 모드 적용 |
| GET | `/schedules` | 스케줄 목록 |
| POST | `/schedules` | 스케줄 생성 |
| PATCH | `/schedules/{scheduleId}` | 스케줄 수정 |
| DELETE | `/schedules/{scheduleId}` | 스케줄 삭제 |
| GET | `/ai/recommendations` | AI 스케줄 추천 |
| POST | `/ai/recommendations/{id}/accept` | 추천 스케줄 등록 |
| GET | `/reports/noise` | 기간별 소음 리포트 |
| GET | `/reports/noise.pdf` | PDF 리포트 다운로드 |

## 7. 주요 인터랙션

| 인터랙션 | 동작 |
|---|---|
| 화면 전환 | horizontal push/pop, 300ms ease-out |
| Bottom Sheet | slide up 280ms, overlay fade 200ms |
| Theme Switch | color variable cross-fade 250ms |
| Toggle | spring 200ms, gray to magenta |
| Mode Selection | scale 0.97 to 1.00, ring fade-in 150ms |
| dB Gauge | 500ms 단위 smooth needle update |
| Waveform | idle 2s breathing, dB에 따라 amplitude 증가 |
| Bar Chart | 50ms stagger enter |
| Heatmap | row-by-row 30ms fade |
| LED Preview | color interpolation 300ms |
| Slider | 25/50/75/100% haptic feedback |

## 8. 에러 및 엣지 케이스

| 케이스 | 화면 | 처리 |
|---|---|---|
| 디바이스 미연결 | Home | orange banner, `재연결` 버튼 |
| 데이터 없음 | Report | empty illustration, `아직 수집된 데이터가 없습니다`, `모니터링 시작` |
| 권한 거부 | DeviceRegister | red card, `설정 열기` |
| 스피커 오류 | Home/Monitor | red banner, `재시도` |
| 분류 불가 소음 | Home/Monitor | `소음 유형 분류 중...` 후 `화이트 노이즈 자동 적용됨` toast |
| 용량 초과 | Report | info banner, 오래된 학습 데이터 정리 안내 |
| 네트워크 오류 | Logout | `네트워크 오류 · 로컬 세션이 종료되었습니다` toast |
| 설정 저장 실패 | Settings | `이전 설정 유지됨`, `재시도` 버튼 |

## 9. Use Case

### UC-01. 회원가입

| 항목 | 내용 |
|---|---|
| Actor | 신규 사용자 |
| Goal | 계정을 생성하고 로그인 화면으로 이동한다 |
| Precondition | 사용자가 앱을 처음 실행했다 |
| Trigger | Splash에서 `시작하기` 선택 |
| Main Flow | 1. 사용자가 이름, 이메일, 비밀번호를 입력한다. 2. 필수 약관 2개에 동의한다. 3. 앱이 입력값 유효성을 검증한다. 4. 사용자가 `다음`을 누른다. 5. 계정 생성 후 Login 화면으로 이동한다. |
| Alternate Flow | 이메일 중복 시 red border와 `이미 사용 중인 이메일입니다` 표시 |
| Postcondition | 사용자 계정이 생성된다 |

### UC-02. 로그인 및 최초 디바이스 등록 분기

| 항목 | 내용 |
|---|---|
| Actor | 사용자 |
| Goal | 앱에 로그인하고 적절한 초기 화면으로 이동한다 |
| Precondition | 사용자 계정이 존재한다 |
| Trigger | Login에서 `로그인` 선택 |
| Main Flow | 1. 이메일과 비밀번호를 입력한다. 2. 서버가 인증한다. 3. 등록된 디바이스가 없으면 DeviceRegister로 이동한다. 4. 등록된 디바이스가 있으면 Home으로 이동한다. |
| Alternate Flow | 인증 실패 시 `이메일 또는 비밀번호가 올바르지 않습니다` 표시 |
| Postcondition | 인증 세션이 생성된다 |

### UC-03. HRGG Speaker 등록

| 항목 | 내용 |
|---|---|
| Actor | 최초 사용자 |
| Goal | HRGG Speaker를 앱에 연결한다 |
| Precondition | 사용자가 로그인되어 있고 디바이스 전원이 켜져 있다 |
| Trigger | DeviceRegister에서 `디바이스 검색` 선택 |
| Main Flow | 1. 앱이 마이크/스피커 권한 상태를 확인한다. 2. 동일 Wi-Fi에서 디바이스를 검색한다. 3. 검색된 HRGG Speaker를 선택한다. 4. 등록을 완료한다. 5. InitialSetup으로 이동한다. |
| Alternate Flow | 디바이스 미검색 시 orange banner 표시. 권한 거부 시 red card와 `설정 열기` 제공 |
| Postcondition | 디바이스가 사용자 계정에 연결된다 |

### UC-04. 초기 마스킹 환경 설정

| 항목 | 내용 |
|---|---|
| Actor | 최초 사용자 |
| Goal | 기본 노이즈와 민감도, Local Zone을 설정한다 |
| Precondition | 디바이스 등록이 완료되었다 |
| Trigger | DeviceRegister 완료 |
| Main Flow | 1. Brown/Pink/White Noise 중 기본 노이즈를 선택한다. 2. 기본 음량을 조정한다. 3. 개입 민감도를 선택한다. 4. Local Zone을 선택한다. 5. `설정 완료`를 누른다. 6. Home으로 이동한다. |
| Alternate Flow | 저장 실패 시 `이전 설정 유지됨` 및 `재시도` 표시 |
| Postcondition | 기본 마스킹 설정이 디바이스에 저장된다 |

### UC-05. 자동 마스킹 켜기/끄기

| 항목 | 내용 |
|---|---|
| Actor | 사용자 |
| Goal | 실시간 소음 감지 기반 자동 마스킹을 제어한다 |
| Precondition | 디바이스가 연결되어 있다 |
| Trigger | Home hero card의 `자동 마스킹` toggle 조작 |
| Main Flow | 1. 사용자가 toggle을 ON으로 변경한다. 2. 앱이 디바이스에 자동 마스킹 활성 명령을 전송한다. 3. 상태 chip과 waveform이 활성 상태로 변경된다. 4. 소음 감지 시 AI가 적절한 노이즈를 선택해 재생한다. |
| Alternate Flow | 디바이스 미연결 시 orange banner와 `재연결` 버튼 표시 |
| Postcondition | 자동 마스킹 상태가 저장된다 |

### UC-06. 실시간 소음 모니터링

| 항목 | 내용 |
|---|---|
| Actor | 사용자 |
| Goal | 현재 소음 수준과 개입 판단 상태를 확인한다 |
| Precondition | 디바이스가 연결되어 있고 모니터링이 활성화되어 있다 |
| Trigger | 하단 탭 `모니터링` 선택 |
| Main Flow | 1. 앱이 live stream 데이터를 수신한다. 2. dB gauge가 현재 소음 수준을 표시한다. 3. 주파수 분석 카드가 활성 밴드를 강조한다. 4. 개입 판단 타임라인이 현재 단계를 표시한다. 5. 이벤트 발생 시 최근 이벤트 목록에 추가한다. |
| Alternate Flow | 스피커 오류 시 red banner와 `재시도` 제공 |
| Postcondition | 사용자는 현재 소음과 앱의 판단 상태를 이해한다 |

### UC-07. 마스킹 사운드 수동 선택

| 항목 | 내용 |
|---|---|
| Actor | 사용자 |
| Goal | AI 자동 선택 대신 원하는 노이즈를 직접 적용한다 |
| Precondition | 디바이스가 연결되어 있다 |
| Trigger | NoiseSelect에서 AI 자동 선택 OFF |
| Main Flow | 1. 사용자가 AI 자동 선택을 끈다. 2. Brown/Pink/White Noise 카드가 활성화된다. 3. 사용자가 노이즈 카드를 선택한다. 4. 미니 파형과 선택 표시가 갱신된다. 5. 음량과 fade-in을 조정한다. 6. `적용 및 재생`을 누른다. |
| Alternate Flow | 적용 실패 시 `이전 설정 유지됨` 및 `재시도` 표시 |
| Postcondition | 선택한 마스킹 사운드가 디바이스에서 재생된다 |

### UC-08. 나의 모드 선택 및 적용

| 항목 | 내용 |
|---|---|
| Actor | 사용자 |
| Goal | 상황별 모드를 빠르게 적용한다 |
| Precondition | 하나 이상의 모드 프리셋이 존재한다 |
| Trigger | 하단 탭 `나의 모드` 선택 |
| Main Flow | 1. 앱이 수면, 베이비, 집중, 교통 소음, 커스텀 모드를 표시한다. 2. 사용자가 원하는 모드를 선택한다. 3. 선택된 카드에 magenta ring과 `현재 활성` chip을 표시한다. 4. 사용자가 `적용`을 누른다. 5. 모드 설정이 디바이스에 반영된다. |
| Alternate Flow | 커스텀 모드 편집 필요 시 `모드 편집`으로 ModeEdit 이동 |
| Postcondition | 선택한 모드가 활성화된다 |

### UC-09. 커스텀 모드 편집

| 항목 | 내용 |
|---|---|
| Actor | 사용자 |
| Goal | 사용자 맞춤 마스킹 환경을 저장한다 |
| Precondition | 사용자가 MyModes에서 커스텀 모드를 선택했다 |
| Trigger | `모드 편집` 선택 |
| Main Flow | 1. 모드 이름과 아이콘을 수정한다. 2. 마스킹 사운드와 음량을 설정한다. 3. LED 색상과 민감도를 조정한다. 4. 스케줄 연동 여부를 설정한다. 5. Preview card로 결과를 확인한다. 6. `저장`을 누른다. |
| Alternate Flow | 저장 실패 시 `이전 설정 유지됨` 및 `재시도` 표시 |
| Postcondition | 커스텀 모드가 저장된다 |

### UC-10. AI 추천 스케줄 등록

| 항목 | 내용 |
|---|---|
| Actor | 사용자 |
| Goal | 반복 소음 패턴을 바탕으로 추천 스케줄을 등록한다 |
| Precondition | 최근 7일 이상 소음 이벤트가 수집되었다 |
| Trigger | Home AI 추천 배너 또는 AIRecommend 진입 |
| Main Flow | 1. 앱이 추천 카드와 패턴 heatmap을 표시한다. 2. 사용자가 추천 카드의 `스케줄 등록`을 선택한다. 3. Schedule 화면이 추천 값으로 pre-filled 된다. 4. 사용자가 요일/시간/모드를 확인한다. 5. 스케줄을 저장한다. |
| Alternate Flow | 사용자가 `무시`를 누르면 추천 상태를 dismissed로 저장 |
| Postcondition | 새 스케줄이 등록된다 |

### UC-11. 리포트 확인 및 PDF 저장

| 항목 | 내용 |
|---|---|
| Actor | 사용자 |
| Goal | 기간별 소음 패턴을 확인하고 저장한다 |
| Precondition | 소음 이벤트 데이터가 존재한다 |
| Trigger | 하단 탭 `리포트` 선택 |
| Main Flow | 1. 사용자가 7일 또는 30일을 선택한다. 2. 앱이 요약 통계, bar chart, heatmap, donut chart를 표시한다. 3. 사용자가 `PDF로 저장`을 누른다. 4. PDF 파일이 생성된다. |
| Alternate Flow | 데이터 없음 시 empty state와 `모니터링 시작` 표시 |
| Postcondition | 사용자는 소음 패턴을 확인하거나 리포트를 저장한다 |

### UC-12. LED 설정 변경

| 항목 | 내용 |
|---|---|
| Actor | 사용자 |
| Goal | 디바이스 LED의 색상, 밝기, 연동 방식을 조정한다 |
| Precondition | 디바이스가 등록되어 있다 |
| Trigger | MyPage 서비스 설정의 `LED 설정` 선택 |
| Main Flow | 1. LED 사용 toggle을 조정한다. 2. 자동/모드 연동/수동 중 하나를 선택한다. 3. 밝기 slider를 조정한다. 4. 필요 시 스케줄 동기화를 켠다. 5. 앱이 디바이스에 설정을 저장한다. |
| Alternate Flow | 수면 모드 연동 시 취침 시간에 자동으로 LED가 꺼진다 |
| Postcondition | LED 설정이 갱신된다 |

### UC-13. 민감도 설정

| 항목 | 내용 |
|---|---|
| Actor | 사용자 |
| Goal | 소음 개입 기준을 생활 환경에 맞게 조정한다 |
| Precondition | 디바이스가 등록되어 있다 |
| Trigger | MyPage 서비스 설정의 `민감도 설정` 선택 |
| Main Flow | 1. 사용자가 sensitivity slider를 조정한다. 2. 현재 기준 시간이 업데이트된다. 3. 설명 카드가 선택 값에 맞게 변경된다. 4. 자동 조정 toggle을 선택할 수 있다. 5. `저장`을 누른다. |
| Alternate Flow | 자동 조정 ON 시 누적 데이터 기반으로 임계값을 최적화한다 |
| Postcondition | 개입 기준이 저장된다 |

### UC-14. 알림 설정

| 항목 | 내용 |
|---|---|
| Actor | 사용자 |
| Goal | 필요한 소음/디바이스 알림만 받는다 |
| Precondition | 앱 알림 권한이 허용되어 있다 |
| Trigger | MyPage 서비스 설정의 `알림 설정` 선택 |
| Main Flow | 1. 사용자가 알림 항목별 toggle을 조정한다. 2. 시간 또는 dB chip 값을 설정한다. 3. Preview bubble로 알림 형태를 확인한다. 4. `저장`을 누른다. |
| Alternate Flow | 알림 권한이 거부되어 있으면 설정 안내를 표시한다 |
| Postcondition | 알림 정책이 저장된다 |

### UC-15. 로그아웃

| 항목 | 내용 |
|---|---|
| Actor | 사용자 |
| Goal | 계정 세션을 종료한다 |
| Precondition | 사용자가 로그인되어 있다 |
| Trigger | MyPage에서 `로그아웃` 선택 |
| Main Flow | 1. LogoutConfirm bottom sheet가 표시된다. 2. 사용자가 안내 문구를 확인한다. 3. `로그아웃`을 누른다. 4. 앱이 세션을 종료한다. 5. Login 화면으로 이동한다. |
| Alternate Flow | 네트워크 오류 시 로컬 세션을 종료하고 toast를 표시한다 |
| Postcondition | 앱 인증 세션이 종료된다. 디바이스 설정은 유지된다 |

## 10. 프로토타입 연결

| From | Action | To |
|---|---|---|
| 01_Splash | 시작하기 | 02_SignUp |
| 01_Splash | 로그인 | 03_Login |
| 02_SignUp | 다음 완료 | 03_Login |
| 03_Login | 인증 성공, 최초 | 04_DeviceRegister |
| 03_Login | 인증 성공, 재방문 | 06_Home |
| 04_DeviceRegister | 등록 완료 | 05_InitialSetup |
| 05_InitialSetup | 설정 완료 | 06_Home |
| 06_Home | 하단탭 모니터링 | 07_Monitor |
| 06_Home | 하단탭 나의 모드 | 09_MyModes |
| 06_Home | 하단탭 리포트 | 13_Report |
| 06_Home | 하단탭 마이페이지 | 18_MyPage |
| 06_Home | 퀵버튼 노이즈 선택 | 08_NoiseSelect |
| 06_Home | 퀵버튼 모드 | 09_MyModes |
| 06_Home | 퀵버튼 스케줄 | 11_Schedule |
| 06_Home | 퀵버튼 리포트 | 13_Report |
| 06_Home | AI 추천 배너 | 12_AIRecommend |
| 09_MyModes | 커스텀 모드 편집 | 10_ModeEdit |
| 09_MyModes | AI 추천 보기 | 12_AIRecommend |
| 12_AIRecommend | 스케줄 등록 | 11_Schedule |
| 18_MyPage | 마스킹 사운드 설정 | 08_NoiseSelect |
| 18_MyPage | 스케줄 관리 | 11_Schedule |
| 18_MyPage | 민감도 설정 | 15_Sensitivity |
| 18_MyPage | LED 설정 | 14_LED |
| 18_MyPage | 알림 설정 | 17_Notifications |
| 18_MyPage | 디바이스 관리 | 16_DeviceManage |
| 18_MyPage | 모드 관리 | 09_MyModes |
| 18_MyPage | 로그아웃 | 19_LogoutConfirm |
| 19_LogoutConfirm | 로그아웃 확인 | 03_Login |

## 11. Figma 제작 산출물 기준

### 11.1 Pages

1. Design System - color variables, typography, icons, components
2. Light Mode - 19 screens
3. Dark Mode - 19 screens
4. Prototype Flow - clickable flow and theme toggle
5. Error States - Light/Dark edge cases

### 11.2 Naming

- Frames: `01_Splash` ~ `19_LogoutConfirm`
- `09_ModeSelect`는 정보구조 변경을 반영해 `09_MyModes`로 명명 권장
- Components:
  - `Atoms/Button/Primary`
  - `Atoms/Button/Secondary`
  - `Atoms/Button/Icon`
  - `Molecules/Card/NoiseType`
  - `Molecules/Card/ModeCard`
  - `Organisms/Nav/BottomTab`
  - `Organisms/Nav/BottomTab_Dark`

### 11.3 Auto Layout 기준

- 모든 모바일 화면은 393 x 852px 프레임을 기준으로 구성한다.
- Safe area와 bottom tab 영역을 분리한다.
- 화면 본문은 vertical Auto Layout, gap 12~20px 범위로 관리한다.
- 카드 내부는 16px padding을 기본으로 하되, 폼 화면은 20px padding을 권장한다.
- 하단 고정 CTA는 content scroll과 겹치지 않도록 bottom safe padding을 확보한다.

## 12. 검수 기준

- Light/Dark mode에서 모든 텍스트 대비가 WCAG AA 수준을 충족한다.
- Theme toggle 시 모든 색상 토큰이 Figma Variables로 전환된다.
- 하단 탭은 5개이며 `나의 모드`가 `모니터링`과 `리포트` 사이에 위치한다.
- 마이페이지에는 `나의 모드` 가로 카드 섹션이 없다.
- Noise Select의 각 노이즈 카드에는 실제 파형 미니 비주얼라이저가 포함된다.
- 모든 interactive element는 default, pressed, disabled 상태를 가진다.
- 에러/엣지 케이스는 Light/Dark 양쪽 variant가 존재한다.
- Prototype Flow는 로그인, 최초 등록, 재방문, 설정, 추천, 로그아웃까지 연결된다.
