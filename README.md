# RE_bHaptics Mod

REFramework 기반 레지던트 이블 시리즈용 bHaptics 햅틱 수트 모드

## 📋 현재 상태

**Phase 1: 이벤트 감지 시스템** (개발 중)

- [x] 프로젝트 구조 설정
- [x] 이벤트 버스 시스템
- [x] 체력 변화 감지
- [x] 피격 방향 감지
- [x] 무기 발사 감지
- [ ] 아이템 사용 감지
- [ ] 환경 이벤트 감지

## 🎮 지원 게임

| 게임 | 상태 | 비고 |
|------|------|------|
| Resident Evil 7 | 🟡 테스트 필요 | RE7 전용 설정 완료 |
| Resident Evil Village (RE8) | 🟡 테스트 필요 | RE8 전용 설정 완료 |
| Resident Evil 2 Remake | 🔴 미지원 | 설정 필요 |
| Resident Evil 4 Remake | 🔴 미지원 | 설정 필요 |

## 📦 설치 방법

### 1. REFramework 설치

1. [REFramework Releases](https://github.com/praydog/REFramework/releases)에서 게임에 맞는 버전 다운로드
2. `dinput8.dll`을 게임 폴더에 복사

### 2. 모드 설치

```bash
# 스크립트 폴더 복사
cp -r scripts/* "[게임폴더]/reframework/autorun/"
```

### 3. 폴더 구조 확인

```
[게임폴더]/
├── re7.exe (또는 re8.exe)
├── dinput8.dll                    ← REFramework
└── reframework/
    └── autorun/
        ├── core/
        │   ├── init.lua           ← 메인 진입점
        │   ├── config.lua
        │   ├── logger.lua
        │   └── event_bus.lua
        ├── detectors/
        │   ├── health_detector.lua
        │   ├── damage_detector.lua
        │   └── weapon_detector.lua
        └── games/
            ├── re7.lua
            └── re8.lua
```

## 🕹️ 사용 방법

1. 게임 실행
2. `Insert` 키로 REFramework 메뉴 열기
3. `Script-generated UI` → `RE_bHaptics` 확인
4. 이벤트 토글 및 디버그 창 활성화 가능

## 🔧 개발

### 이벤트 탐색

1. REFramework 메뉴 → `DeveloperTools` → `Object Explorer`
2. 관심 있는 클래스 검색 (예: `Player`, `Damage`)
3. TDB Methods 우클릭 → `Hook All Methods`
4. 게임에서 동작 수행
5. `Hooked Methods`에서 호출된 메서드 확인

### 새 게임 추가

1. `scripts/games/` 폴더에 새 설정 파일 생성
2. `init.lua`에 게임 로딩 조건 추가

## 📝 감지 가능한 이벤트

| 이벤트명 | 설명 | 데이터 |
|----------|------|--------|
| `player_hit` | 플레이어 피격 | damage, health_percent, severity |
| `player_hit_direction` | 방향별 피격 | damage, direction (front/back/left/right) |
| `gun_fire` | 총 발사 | weapon_name, weapon_type |
| `gun_reload` | 재장전 | weapon_name |
| `melee_attack` | 근접 공격 | weapon_name |
| `heartbeat` | 심장박동 | health_percent, intensity |
| `heal` | 회복 | amount, health_percent |

## 🔜 다음 단계 (Phase 2)

- bHaptics Player 연동
- 햅틱 패턴 매핑
- WebSocket 통신 구현

## 📚 참고 자료

- [REFramework Documentation](https://cursey.github.io/reframework-book/)
- [bHaptics Developer Portal](https://portal.bhaptics.com)

## 📄 라이선스

MIT License
