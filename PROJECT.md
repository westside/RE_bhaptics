# RE Engine bHaptics Haptic Mod Project

## 프로젝트 개요

REFramework를 활용하여 레지던트 이블 시리즈(RE7, RE8 등) PC 게임에서 게임 이벤트를 감지하고, bHaptics 햅틱 수트와 연동하는 모드를 개발합니다.

### 목표
- **Phase 1**: 게임 이벤트 감지 시스템 구축 (현재 단계)
- **Phase 2**: bHaptics 연동 및 햅틱 패턴 매핑
- **Phase 3**: 사용자 설정 UI 및 최적화

### 지원 대상 게임
| 게임 | 실행 파일 | REFramework 버전 |
|------|-----------|------------------|
| Resident Evil 7 | re7.exe | RE7.zip |
| Resident Evil Village (RE8) | re8.exe | RE8.zip |
| Resident Evil 2 Remake | re2.exe | RE2.zip |
| Resident Evil 4 Remake | re4.exe | RE4.zip |

---

## 기술 스택

```
┌─────────────────────────────────────────────────────────┐
│                    bHaptics Player                       │
│                  (WebSocket Server)                      │
└─────────────────────────────────────────────────────────┘
                          ▲
                          │ WebSocket (ws://localhost:12345)
                          │
┌─────────────────────────────────────────────────────────┐
│              Bridge Layer (선택)                         │
│         Python/Node.js bHaptics SDK Wrapper              │
└─────────────────────────────────────────────────────────┘
                          ▲
                          │ IPC / File / Socket
                          │
┌─────────────────────────────────────────────────────────┐
│                REFramework Lua Script                    │
│              (이벤트 감지 & 트리거)                       │
└─────────────────────────────────────────────────────────┘
                          ▲
                          │ sdk.hook / sdk.get_managed_singleton
                          │
┌─────────────────────────────────────────────────────────┐
│                   RE Engine Game                         │
│               (RE7 / RE8 / RE2 / RE4)                   │
└─────────────────────────────────────────────────────────┘
```

---

## 프로젝트 구조

```
RE_bHaptics_Mod/
├── PROJECT.md                    # 이 문서
├── README.md                     # 사용자용 설치 가이드
│
├── scripts/                      # REFramework Lua 스크립트
│   ├── core/
│   │   ├── init.lua             # 메인 진입점
│   │   ├── config.lua           # 설정 관리
│   │   ├── logger.lua           # 로깅 유틸리티
│   │   └── event_bus.lua        # 이벤트 버스 시스템
│   │
│   ├── detectors/               # 이벤트 감지 모듈
│   │   ├── health_detector.lua  # 체력 변화 감지
│   │   ├── damage_detector.lua  # 피격 감지
│   │   ├── weapon_detector.lua  # 무기 발사 감지
│   │   ├── item_detector.lua    # 아이템 사용 감지
│   │   └── environment_detector.lua  # 환경 이벤트 감지
│   │
│   ├── games/                   # 게임별 설정
│   │   ├── re7.lua              # RE7 전용 클래스/메서드 정의
│   │   ├── re8.lua              # RE8 전용
│   │   ├── re2.lua              # RE2 전용
│   │   └── re4.lua              # RE4 전용
│   │
│   └── haptics/                 # 햅틱 연동 (Phase 2)
│       ├── bhaptics_client.lua  # bHaptics 통신
│       └── patterns.lua         # 햅틱 패턴 정의
│
├── bridge/                      # bHaptics 브릿지 (Python)
│   ├── requirements.txt
│   ├── bhaptics_bridge.py       # WebSocket 브릿지 서버
│   └── patterns/                # .tact 패턴 파일
│       ├── player_hit.tact
│       ├── gun_fire.tact
│       └── heartbeat.tact
│
├── docs/                        # 문서
│   ├── EVENTS.md               # 감지 가능한 이벤트 목록
│   ├── DEVELOPMENT.md          # 개발 가이드
│   └── TROUBLESHOOTING.md      # 문제 해결
│
└── tests/                       # 테스트
    ├── test_detectors.lua       # 감지 테스트
    └── test_events.md           # 수동 테스트 체크리스트
```

---

## Phase 1: 이벤트 감지 시스템

### 1.1 감지할 이벤트 목록

#### 🔴 필수 이벤트 (High Priority)

| 이벤트 | 설명 | 트리거 조건 | 예상 클래스/메서드 |
|--------|------|-------------|-------------------|
| `player_hit` | 플레이어 피격 | 체력 감소 | `app.HitController.onDamage` |
| `player_hit_direction` | 방향별 피격 | 피격 + 방향 | `app.DamageInfo.Direction` |
| `gun_fire` | 총 발사 | 무기 발사 | `app.WeaponGun.shoot` |
| `gun_reload` | 재장전 | 재장전 시작 | `app.WeaponGun.reload` |
| `heartbeat` | 심장박동 | 저체력 상태 | 체력 < 30% |

#### 🟡 중요 이벤트 (Medium Priority)

| 이벤트 | 설명 | 트리거 조건 |
|--------|------|-------------|
| `heal` | 회복 | 체력 증가 |
| `item_use` | 아이템 사용 | 인벤토리 아이템 사용 |
| `melee_attack` | 근접 공격 | 근접 무기 공격 |
| `block` | 방어 | 가드 동작 |
| `interact` | 상호작용 | 문/상자 열기 등 |

#### 🟢 부가 이벤트 (Low Priority)

| 이벤트 | 설명 | 트리거 조건 |
|--------|------|-------------|
| `footstep` | 발소리 | 이동 중 |
| `explosion_nearby` | 폭발 | 근처 폭발 |
| `enemy_near` | 적 근접 | 적과의 거리 |
| `ambient_tension` | 긴장감 | BGM/상황 기반 |

---

### 1.2 핵심 Lua 스크립트

#### `scripts/core/init.lua` - 메인 진입점

```lua
-- RE bHaptics Mod - Main Entry Point
-- Place in: [game_folder]/reframework/autorun/

local MOD_NAME = "RE_bHaptics"
local MOD_VERSION = "0.1.0"

-- 모듈 로드
local config = require("core/config")
local logger = require("core/logger")
local event_bus = require("core/event_bus")

-- 게임별 설정 로드
local game_name = reframework:get_game_name()
local game_config = nil

if game_name == "re7" then
    game_config = require("games/re7")
elseif game_name == "re8" then
    game_config = require("games/re8")
elseif game_name == "re2" then
    game_config = require("games/re2")
elseif game_name == "re4" then
    game_config = require("games/re4")
else
    logger.error("Unsupported game: " .. game_name)
    return
end

-- 감지 모듈 로드
local health_detector = require("detectors/health_detector")
local damage_detector = require("detectors/damage_detector")
local weapon_detector = require("detectors/weapon_detector")

-- 초기화
logger.info(MOD_NAME .. " v" .. MOD_VERSION .. " loaded for " .. game_name)

-- 감지 모듈 초기화
health_detector.init(game_config, event_bus)
damage_detector.init(game_config, event_bus)
weapon_detector.init(game_config, event_bus)

-- 이벤트 리스너 (디버그용)
event_bus.on("player_hit", function(data)
    logger.info("EVENT: player_hit | damage=" .. data.damage .. " | direction=" .. data.direction)
end)

event_bus.on("gun_fire", function(data)
    logger.info("EVENT: gun_fire | weapon=" .. data.weapon_name)
end)

event_bus.on("heartbeat", function(data)
    logger.info("EVENT: heartbeat | health_percent=" .. data.health_percent)
end)

logger.info("Event detection system initialized")
```

#### `scripts/core/event_bus.lua` - 이벤트 버스

```lua
-- Simple Event Bus for inter-module communication

local EventBus = {}
EventBus._listeners = {}

function EventBus.on(event_name, callback)
    if not EventBus._listeners[event_name] then
        EventBus._listeners[event_name] = {}
    end
    table.insert(EventBus._listeners[event_name], callback)
end

function EventBus.emit(event_name, data)
    local listeners = EventBus._listeners[event_name]
    if listeners then
        for _, callback in ipairs(listeners) do
            local success, err = pcall(callback, data)
            if not success then
                log.error("EventBus error on " .. event_name .. ": " .. tostring(err))
            end
        end
    end
end

function EventBus.off(event_name, callback)
    local listeners = EventBus._listeners[event_name]
    if listeners then
        for i, cb in ipairs(listeners) do
            if cb == callback then
                table.remove(listeners, i)
                return
            end
        end
    end
end

return EventBus
```

#### `scripts/core/logger.lua` - 로깅 유틸리티

```lua
-- Logger utility with levels

local Logger = {}
Logger.LEVEL = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4
}
Logger.current_level = Logger.LEVEL.DEBUG
Logger.prefix = "[RE_bHaptics]"

function Logger.debug(msg)
    if Logger.current_level <= Logger.LEVEL.DEBUG then
        log.info(Logger.prefix .. " [DEBUG] " .. msg)
    end
end

function Logger.info(msg)
    if Logger.current_level <= Logger.LEVEL.INFO then
        log.info(Logger.prefix .. " [INFO] " .. msg)
    end
end

function Logger.warn(msg)
    if Logger.current_level <= Logger.LEVEL.WARN then
        log.warn(Logger.prefix .. " [WARN] " .. msg)
    end
end

function Logger.error(msg)
    if Logger.current_level <= Logger.LEVEL.ERROR then
        log.error(Logger.prefix .. " [ERROR] " .. msg)
    end
end

return Logger
```

---

### 1.3 이벤트 감지 모듈

#### `scripts/detectors/health_detector.lua`

```lua
-- Health change detection module

local HealthDetector = {}
local event_bus = nil
local game_config = nil

-- State
local previous_health = nil
local previous_max_health = nil
local is_initialized = false
local low_health_threshold = 0.3  -- 30%
local heartbeat_active = false
local last_heartbeat_time = 0
local heartbeat_interval = 1.0  -- seconds

function HealthDetector.init(config, bus)
    game_config = config
    event_bus = bus
    
    -- 매 프레임 체력 감시
    re.on_frame(HealthDetector.on_frame)
    
    log.info("[HealthDetector] Initialized")
end

function HealthDetector.on_frame()
    local player = HealthDetector.get_player()
    if not player then return end
    
    local current_health = HealthDetector.get_health(player)
    local max_health = HealthDetector.get_max_health(player)
    
    if current_health == nil or max_health == nil then return end
    
    -- 초기화
    if not is_initialized then
        previous_health = current_health
        previous_max_health = max_health
        is_initialized = true
        return
    end
    
    -- 체력 감소 감지 (피격)
    if current_health < previous_health then
        local damage = previous_health - current_health
        event_bus.emit("player_hit", {
            damage = damage,
            current_health = current_health,
            max_health = max_health,
            health_percent = current_health / max_health,
            direction = "unknown"  -- 방향은 damage_detector에서 처리
        })
    end
    
    -- 체력 증가 감지 (회복)
    if current_health > previous_health then
        local healed = current_health - previous_health
        event_bus.emit("heal", {
            amount = healed,
            current_health = current_health,
            max_health = max_health
        })
    end
    
    -- 저체력 심장박동
    local health_percent = current_health / max_health
    if health_percent <= low_health_threshold then
        local current_time = os.clock()
        if not heartbeat_active or (current_time - last_heartbeat_time) >= heartbeat_interval then
            heartbeat_active = true
            last_heartbeat_time = current_time
            
            -- 체력이 낮을수록 빠른 심장박동
            local intensity = 1 - (health_percent / low_health_threshold)
            event_bus.emit("heartbeat", {
                health_percent = health_percent,
                intensity = intensity
            })
        end
    else
        heartbeat_active = false
    end
    
    previous_health = current_health
    previous_max_health = max_health
end

function HealthDetector.get_player()
    -- 게임별로 다른 방식으로 플레이어 가져오기
    local player_manager_name = game_config.singletons.player_manager
    local player_manager = sdk.get_managed_singleton(player_manager_name)
    
    if not player_manager then return nil end
    
    local get_player_method = game_config.methods.get_current_player
    return player_manager:call(get_player_method)
end

function HealthDetector.get_health(player)
    local method = game_config.methods.get_health
    local success, result = pcall(player.call, player, method)
    if success then return result end
    return nil
end

function HealthDetector.get_max_health(player)
    local method = game_config.methods.get_max_health
    local success, result = pcall(player.call, player, method)
    if success then return result end
    return nil
end

return HealthDetector
```

#### `scripts/detectors/damage_detector.lua`

```lua
-- Direct damage event detection via method hooking

local DamageDetector = {}
local event_bus = nil
local game_config = nil

function DamageDetector.init(config, bus)
    game_config = config
    event_bus = bus
    
    -- 피격 메서드 후킹
    DamageDetector.hook_damage_methods()
    
    log.info("[DamageDetector] Initialized")
end

function DamageDetector.hook_damage_methods()
    -- 게임 설정에서 후킹할 메서드 정보 가져오기
    local hooks = game_config.hooks.damage
    
    for _, hook_info in ipairs(hooks) do
        local type_def = sdk.find_type_definition(hook_info.type)
        if type_def then
            local method = type_def:get_method(hook_info.method)
            if method then
                sdk.hook(
                    method,
                    function(args) return DamageDetector.on_pre_damage(args, hook_info) end,
                    function(retval) return DamageDetector.on_post_damage(retval, hook_info) end
                )
                log.info("[DamageDetector] Hooked: " .. hook_info.type .. "." .. hook_info.method)
            else
                log.warn("[DamageDetector] Method not found: " .. hook_info.method)
            end
        else
            log.warn("[DamageDetector] Type not found: " .. hook_info.type)
        end
    end
end

function DamageDetector.on_pre_damage(args, hook_info)
    -- 피격 정보 추출
    local damage_info = {}
    
    -- 데미지 값 추출 (게임별로 다름)
    if hook_info.damage_arg then
        local damage_obj = sdk.to_managed_object(args[hook_info.damage_arg])
        if damage_obj then
            damage_info.damage = damage_obj:get_field("Damage") or 0
            
            -- 방향 정보
            local direction_vec = damage_obj:get_field("Direction")
            if direction_vec then
                damage_info.direction = DamageDetector.vector_to_direction(direction_vec)
            end
        end
    end
    
    -- 피격 방향에 따른 이벤트
    local direction = damage_info.direction or "front"
    event_bus.emit("player_hit_direction", {
        damage = damage_info.damage or 0,
        direction = direction,
        raw_direction = damage_info.direction_vector
    })
    
    return nil  -- 원래 동작 유지
end

function DamageDetector.on_post_damage(retval, hook_info)
    return retval  -- 반환값 수정 없음
end

function DamageDetector.vector_to_direction(vec)
    -- 3D 벡터를 4방향으로 변환
    if not vec then return "front" end
    
    local x = vec.x or 0
    local z = vec.z or 0
    
    if math.abs(x) > math.abs(z) then
        return x > 0 and "right" or "left"
    else
        return z > 0 and "front" or "back"
    end
end

return DamageDetector
```

#### `scripts/detectors/weapon_detector.lua`

```lua
-- Weapon firing detection

local WeaponDetector = {}
local event_bus = nil
local game_config = nil

function WeaponDetector.init(config, bus)
    game_config = config
    event_bus = bus
    
    WeaponDetector.hook_weapon_methods()
    
    log.info("[WeaponDetector] Initialized")
end

function WeaponDetector.hook_weapon_methods()
    local hooks = game_config.hooks.weapon
    
    for _, hook_info in ipairs(hooks) do
        local type_def = sdk.find_type_definition(hook_info.type)
        if type_def then
            local method = type_def:get_method(hook_info.method)
            if method then
                sdk.hook(
                    method,
                    function(args) return WeaponDetector.on_pre_action(args, hook_info) end,
                    function(retval) return retval end
                )
                log.info("[WeaponDetector] Hooked: " .. hook_info.type .. "." .. hook_info.method)
            end
        end
    end
end

function WeaponDetector.on_pre_action(args, hook_info)
    local event_type = hook_info.event_type or "gun_fire"
    
    -- 무기 정보 추출
    local weapon_obj = sdk.to_managed_object(args[2])
    local weapon_name = "unknown"
    
    if weapon_obj then
        local name_method = weapon_obj:get_type_definition():get_method("get_Name")
        if name_method then
            local success, result = pcall(weapon_obj.call, weapon_obj, "get_Name")
            if success and result then
                weapon_name = result
            end
        end
    end
    
    event_bus.emit(event_type, {
        weapon_name = weapon_name,
        weapon_type = hook_info.weapon_type or "gun",
        hand = hook_info.hand or "right"
    })
    
    return nil
end

return WeaponDetector
```

---

### 1.4 게임별 설정

#### `scripts/games/re7.lua`

```lua
-- Resident Evil 7 specific configuration

local RE7 = {}

RE7.game_name = "re7"
RE7.game_title = "Resident Evil 7: Biohazard"

-- Singleton 클래스명
RE7.singletons = {
    player_manager = "app.PlayerManager",
    game_manager = "app.GameManager",
    inventory = "app.InventoryManager"
}

-- 메서드명
RE7.methods = {
    get_current_player = "get_CurrentPlayer",
    get_health = "get_CurrentHP",
    get_max_health = "get_MaxHP"
}

-- 후킹할 메서드들
RE7.hooks = {
    damage = {
        {
            type = "app.HitController",
            method = "onDamage",
            damage_arg = 3,
            description = "Player damage handler"
        },
        {
            type = "app.PlayerCore",
            method = "takeDamage",
            damage_arg = 3,
            description = "Alternative damage handler"
        }
    },
    weapon = {
        {
            type = "app.WeaponGun",
            method = "shoot",
            event_type = "gun_fire",
            weapon_type = "gun"
        },
        {
            type = "app.WeaponGun",
            method = "reload",
            event_type = "gun_reload",
            weapon_type = "gun"
        },
        {
            type = "app.WeaponMelee",
            method = "attack",
            event_type = "melee_attack",
            weapon_type = "melee"
        }
    },
    item = {
        {
            type = "app.ItemManager",
            method = "useItem",
            event_type = "item_use"
        }
    }
}

return RE7
```

#### `scripts/games/re8.lua`

```lua
-- Resident Evil Village (RE8) specific configuration

local RE8 = {}

RE8.game_name = "re8"
RE8.game_title = "Resident Evil Village"

RE8.singletons = {
    player_manager = "app.PlayerManager",
    game_manager = "app.GameManager"
}

RE8.methods = {
    get_current_player = "get_CurrentPlayer",
    get_health = "get_CurrentHP",
    get_max_health = "get_MaxHP"
}

RE8.hooks = {
    damage = {
        {
            type = "app.HitController",
            method = "onDamage",
            damage_arg = 3
        }
    },
    weapon = {
        {
            type = "app.WeaponGun",
            method = "shoot",
            event_type = "gun_fire"
        },
        {
            type = "app.WeaponGun",
            method = "reload",
            event_type = "gun_reload"
        }
    },
    item = {}
}

return RE8
```

---

## 개발 워크플로우

### 1. 환경 설정

```bash
# 1. REFramework 설치
# https://github.com/praydog/REFramework/releases 에서 다운로드
# 게임 폴더에 dinput8.dll 복사

# 2. 프로젝트 클론
git clone <this-repo>
cd RE_bHaptics_Mod

# 3. 스크립트 복사
cp -r scripts/* "[GAME_FOLDER]/reframework/autorun/"
```

### 2. 이벤트 탐색 (Object Explorer)

1. 게임 실행
2. `Insert` 키로 REFramework 메뉴 열기
3. `DeveloperTools` → `Object Explorer`
4. 관심 있는 클래스 검색 (예: `Player`, `Damage`, `Weapon`)
5. TDB Methods 우클릭 → `Hook All Methods`
6. 게임에서 해당 동작 수행
7. `Hooked Methods` 창에서 호출된 메서드 확인
8. 메서드 이름 복사하여 게임 설정 파일에 추가

### 3. 테스트

```bash
# 게임 실행 후 로그 확인
# Windows: 게임 폴더/re7_framework_log.txt
# 또는 REFramework 메뉴 → ScriptRunner → 로그 확인
```

### 4. 디버그 팁

- `log.info()` 로 변수 값 출력
- Object Explorer에서 실시간 값 확인
- `re.on_draw_ui()` 로 ImGui 디버그 창 생성

---

## 다음 단계 (Phase 2 준비)

### bHaptics 연동 방법

1. **Python 브릿지 서버**
   - 파일 기반 통신 (Lua → 파일 → Python → bHaptics)
   - 소켓 통신 (더 빠름)

2. **직접 WebSocket 연결**
   - Lua용 WebSocket 라이브러리 필요
   - 복잡하지만 중간 프로세스 불필요

3. **Native DLL 플러그인**
   - C++로 bHaptics SDK 래핑
   - 가장 빠르고 안정적

### 햅틱 패턴 매핑 예시

```lua
-- 이벤트 → 햅틱 패턴 매핑
local HAPTIC_MAP = {
    player_hit = {
        front = "VestFront",
        back = "VestBack",
        left = "VestLeftSide",
        right = "VestRightSide"
    },
    gun_fire = {
        gun = "RecoilPistol",
        shotgun = "RecoilShotgun",
        rifle = "RecoilRifle"
    },
    heartbeat = "HeartbeatLow",
    heal = "HealingPulse"
}
```

---

## 참고 자료

- [REFramework Documentation](https://cursey.github.io/reframework-book/)
- [REFramework GitHub](https://github.com/praydog/REFramework)
- [bHaptics Developer Portal](https://portal.bhaptics.com)
- [bHaptics Designer](https://designer.bhaptics.com)
- [기존 RE7 bHaptics 모드](https://github.com/Astienth/RE7_bHaptics_Provolver)

---

## 라이선스

MIT License

---

*Last Updated: 2025-01-XX*
*Version: 0.1.0-dev*
