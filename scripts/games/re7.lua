-- Resident Evil 7: Biohazard - Game Configuration
-- Class names and method signatures for RE7

local RE7 = {}

RE7.game_name = "re7"
RE7.game_title = "Resident Evil 7: Biohazard"

-- ============================================
-- Singleton 클래스명
-- Object Explorer에서 확인 가능
-- ============================================
RE7.singletons = {
    player_manager = "app.PlayerManager",
    game_manager = "app.GameManager",
    inventory_manager = "app.InventoryManager",
    input_manager = "app.InputManager",
    sound_manager = "app.SoundManager"
}

-- ============================================
-- 플레이어 관련 메서드
-- ============================================
RE7.methods = {
    -- 플레이어 가져오기
    get_current_player = "get_CurrentPlayer",
    get_player_core = "get_PlayerCore",
    
    -- 체력
    get_health = "get_CurrentHP",
    get_max_health = "get_MaxHP",
    set_health = "set_CurrentHP",
    
    -- 상태
    is_alive = "get_IsAlive",
    is_blocking = "get_IsBlocking"
}

-- ============================================
-- 후킹할 메서드들
-- Object Explorer에서 "Hook All Methods"로 찾기
-- ============================================
RE7.hooks = {
    -- 피격 관련
    damage = {
        {
            type = "app.HitController",
            method = "onDamage",
            damage_arg = 3,
            description = "Main player damage handler"
        },
        {
            type = "app.PlayerCore",
            method = "takeDamage",
            damage_arg = 3,
            description = "Player core damage method"
        },
        {
            type = "app.PlayerCore",
            method = "onHit",
            damage_arg = 2,
            description = "Hit event callback"
        }
    },
    
    -- 무기 관련
    weapon = {
        {
            type = "app.WeaponGun",
            method = "shoot",
            event_type = "gun_fire",
            weapon_type = "gun",
            description = "Gun shooting"
        },
        {
            type = "app.WeaponGun",
            method = "fire",
            event_type = "gun_fire",
            weapon_type = "gun",
            description = "Alternative fire method"
        },
        {
            type = "app.WeaponGun",
            method = "reload",
            event_type = "gun_reload",
            weapon_type = "gun",
            description = "Weapon reload"
        },
        {
            type = "app.WeaponGun",
            method = "startReload",
            event_type = "gun_reload",
            weapon_type = "gun",
            description = "Reload start"
        },
        {
            type = "app.WeaponMelee",
            method = "attack",
            event_type = "melee_attack",
            weapon_type = "melee",
            description = "Melee attack"
        },
        {
            type = "app.WeaponKnife",
            method = "slash",
            event_type = "melee_attack",
            weapon_type = "knife",
            description = "Knife slash"
        }
    },
    
    -- 아이템 관련
    item = {
        {
            type = "app.InventoryManager",
            method = "useItem",
            event_type = "item_use",
            description = "Item usage"
        },
        {
            type = "app.ItemManager",
            method = "use",
            event_type = "item_use",
            description = "Alternative item use"
        }
    },
    
    -- 상호작용
    interaction = {
        {
            type = "app.GimmickController",
            method = "activate",
            event_type = "interact",
            description = "Gimmick activation (doors, etc.)"
        }
    },
    
    -- 방어
    defense = {
        {
            type = "app.PlayerCore",
            method = "startBlock",
            event_type = "block_start",
            description = "Block start"
        },
        {
            type = "app.PlayerCore",
            method = "endBlock",
            event_type = "block_end",
            description = "Block end"
        }
    }
}

-- ============================================
-- 피격 방향 정보 필드
-- ============================================
RE7.damage_info = {
    damage_field = "Damage",
    direction_field = "Direction",
    attacker_field = "Attacker",
    hit_position_field = "HitPosition"
}

-- ============================================
-- 체력 임계값
-- ============================================
RE7.health_thresholds = {
    critical = 0.15,    -- 15% 이하 = 위험
    low = 0.30,         -- 30% 이하 = 낮음
    medium = 0.60       -- 60% 이하 = 중간
}

-- ============================================
-- 디버그용 헬퍼 함수
-- ============================================
function RE7.get_player()
    local pm = sdk.get_managed_singleton(RE7.singletons.player_manager)
    if not pm then return nil end
    
    local success, player = pcall(pm.call, pm, RE7.methods.get_current_player)
    if success then return player end
    return nil
end

function RE7.get_health_info()
    local player = RE7.get_player()
    if not player then return nil end
    
    local current = player:call(RE7.methods.get_health) or 0
    local max = player:call(RE7.methods.get_max_health) or 1
    
    return {
        current = current,
        max = max,
        percent = current / max
    }
end

return RE7
