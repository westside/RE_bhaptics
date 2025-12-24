# 감지 가능한 이벤트 목록

이 문서는 RE_bHaptics 모드에서 감지 가능한 모든 게임 이벤트를 설명합니다.

## 이벤트 구조

모든 이벤트는 EventBus를 통해 발생하며, 다음 공통 필드를 포함합니다:

```lua
{
    _event_name = "event_name",  -- 이벤트 이름
    _timestamp = 12345.67,       -- os.clock() 값
    source = "detector_name"     -- 감지 모듈명
}
```

---

## 플레이어 이벤트

### `player_hit`

플레이어가 피격당했을 때 발생합니다.

```lua
{
    damage = 25,                    -- 받은 데미지
    current_health = 75,            -- 현재 체력
    max_health = 100,               -- 최대 체력
    health_percent = 0.75,          -- 체력 비율 (0~1)
    severity = "medium",            -- 심각도: low/medium/high/critical
    direction = "unknown",          -- 방향 (health_detector에서는 unknown)
    source = "health_monitor"
}
```

**심각도 기준:**
- `critical`: 최대 체력의 30% 이상 데미지
- `high`: 15~30% 데미지
- `medium`: 5~15% 데미지
- `low`: 5% 미만 데미지

---

### `player_hit_direction`

방향 정보가 포함된 피격 이벤트입니다.

```lua
{
    damage = 25,
    direction = "back",             -- front/back/left/right
    direction_vector = {...},       -- 원본 3D 벡터
    hit_position = {...},           -- 피격 위치
    attacker = <object>,            -- 공격자 객체
    source = "damage_hook",
    hook_type = "app.HitController.onDamage"
}
```

---

### `heal`

체력 회복 시 발생합니다.

```lua
{
    amount = 50,                    -- 회복량
    current_health = 100,           -- 현재 체력
    max_health = 100,               -- 최대 체력
    health_percent = 1.0            -- 체력 비율
}
```

---

### `heartbeat`

저체력 상태에서 주기적으로 발생합니다.

```lua
{
    health_percent = 0.25,          -- 현재 체력 비율
    intensity = 0.5,                -- 긴박도 (0~1, 체력 낮을수록 높음)
    interval = 0.75                 -- 다음 심장박동까지 간격 (초)
}
```

**발생 조건:**
- 체력이 30% 이하일 때 활성화
- 체력이 낮을수록 간격이 짧아짐

---

### `health_state`

체력 상태가 변경될 때 발생합니다.

```lua
{
    state = "low",                  -- healthy/medium/low/critical
    percent = 0.28
}
```

---

## 무기 이벤트

### `gun_fire`

총 발사 시 발생합니다.

```lua
{
    weapon_name = "Handgun",        -- 무기 이름
    weapon_type = "gun",            -- 무기 종류
    weapon_class = "app.WeaponGun", -- 클래스명
    ammo_count = 12,                -- 남은 탄약 (가능한 경우)
    hand = "right",                 -- 손 (right/left)
    source = "weapon_hook"
}
```

---

### `gun_reload`

재장전 시 발생합니다.

```lua
{
    weapon_name = "Shotgun",
    weapon_type = "gun",
    hand = "right",
    source = "weapon_hook"
}
```

---

### `melee_attack`

근접 공격 시 발생합니다.

```lua
{
    weapon_name = "Knife",
    weapon_type = "knife",          -- knife/melee
    hand = "right",
    source = "weapon_hook"
}
```

---

## 아이템 이벤트 (예정)

### `item_use`

아이템 사용 시 발생합니다.

```lua
{
    item_name = "First Aid Med",
    item_type = "healing",
    source = "item_hook"
}
```

---

## 시네마틱/진행상태 이벤트

### `cutscene_start`

컷씬이 시작될 때 발생합니다.

```lua
{
    cutscene_name = "opening_cutscene",  -- 컷씬 이름 (가능한 경우)
    chapter = 1,                          -- 현재 챕터
    scene = "main_hall"                   -- 현재 씬
}
```

**활용 예시:**
- 컷씬 시작 시 햅틱 피드백 일시 중지
- 특정 컷씬에 맞춤 햅틱 효과 재생

---

### `cutscene_end`

컷씬이 종료될 때 발생합니다.

```lua
{
    cutscene_name = "opening_cutscene",
    duration = 45.5,                      -- 컷씬 재생 시간 (초)
    chapter = 1
}
```

**활용 예시:**
- 컷씬 종료 후 햅틱 피드백 재개
- 긴 컷씬 후 "환영 돌아옴" 햅틱 효과

---

### `chapter_change`

게임 챕터/스테이지가 변경될 때 발생합니다.

```lua
{
    previous_chapter = 1,
    current_chapter = 2,
    scene = "village_entrance",
    area = "Village"
}
```

**활용 예시:**
- 새 챕터 시작 시 강한 전신 진동
- 챕터별 다른 햅틱 프로필 적용

---

### `scene_change`

게임 씬/맵이 변경될 때 발생합니다.

```lua
{
    previous_scene = "main_hall",
    current_scene = "basement",
    chapter = 1
}
```

**활용 예시:**
- 씬 전환 시 부드러운 전환 효과
- 특정 씬 진입 시 분위기 햅틱

---

### `loading_start`

로딩 화면이 시작될 때 발생합니다.

```lua
{
    scene = "basement",
    chapter = 1
}
```

**활용 예시:**
- 로딩 중 햅틱 일시 중지

---

### `loading_end`

로딩이 완료될 때 발생합니다.

```lua
{
    scene = "basement",
    chapter = 1
}
```

**활용 예시:**
- 로딩 완료 시 부드러운 진동으로 알림
- 햅틱 피드백 재개

---

## 상호작용 이벤트 (예정)

### `interact`

문/상자 등 상호작용 시 발생합니다.

```lua
{
    object_type = "door",
    action = "open",
    source = "interaction_hook"
}
```

---

## 이벤트 구독 예시

```lua
local event_bus = require("core/event_bus")

-- 단일 이벤트 구독
event_bus.on("player_hit", function(data)
    print("피격! 데미지: " .. data.damage)
end)

-- 우선순위 지정 (낮을수록 먼저 실행)
event_bus.on("gun_fire", function(data)
    print("발사!")
end, 1)

-- 일회성 이벤트
event_bus.once("heal", function(data)
    print("첫 회복!")
end)

-- 모든 이벤트 수신
event_bus.on("*", function(data)
    print("이벤트: " .. data._event_name)
end)
```

---

## 이벤트 활성화/비활성화

`config.lua`에서 개별 이벤트를 활성화/비활성화할 수 있습니다:

```lua
events = {
    player_hit = true,
    player_hit_direction = true,
    gun_fire = true,
    gun_reload = true,
    heartbeat = true,
    heal = true,
    melee_attack = true,
    item_use = false  -- 비활성화
}
```

또는 게임 내 REFramework UI에서 토글 가능합니다.
