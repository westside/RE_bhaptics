-- Resident Evil Village (RE8) - Game Configuration
-- Class names and method signatures for RE8

local RE8 = {}

RE8.game_name = "re8"
RE8.game_title = "Resident Evil Village"

-- ============================================
-- Singleton 클래스명
-- ============================================
RE8.singletons = {
    player_manager = "app.PlayerManager",
    game_manager = "app.GameManager",
    inventory_manager = "app.InventoryManager",
    weapon_manager = "app.WeaponManager"
}

-- ============================================
-- 플레이어 관련 메서드
-- ============================================
RE8.methods = {
    get_current_player = "get_CurrentPlayer",
    get_player_core = "get_PlayerCore",
    get_health = "get_CurrentHP",
    get_max_health = "get_MaxHP",
    is_alive = "get_IsAlive"
}

-- ============================================
-- 후킹할 메서드들
-- ============================================
RE8.hooks = {
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
            description = "Player take damage"
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
            type = "app.WeaponKnife",
            method = "attack",
            event_type = "melee_attack",
            weapon_type = "knife"
        }
    },
    
    item = {
        {
            type = "app.InventoryManager",
            method = "useItem",
            event_type = "item_use"
        }
    },
    
    interaction = {},
    defense = {}
}

RE8.damage_info = {
    damage_field = "Damage",
    direction_field = "Direction"
}

RE8.health_thresholds = {
    critical = 0.15,
    low = 0.30,
    medium = 0.60
}

function RE8.get_player()
    local pm = sdk.get_managed_singleton(RE8.singletons.player_manager)
    if not pm then return nil end
    
    local success, player = pcall(pm.call, pm, RE8.methods.get_current_player)
    if success then return player end
    return nil
end

return RE8
