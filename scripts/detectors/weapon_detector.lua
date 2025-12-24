-- Weapon Action Detection Module
-- Hooks weapon methods to detect firing, reloading, melee attacks

local WeaponDetector = {}

-- Dependencies
local event_bus = nil
local game_config = nil
local config = nil
local logger = nil

-- State
local hooked_methods = {}
local last_fire_time = 0
local fire_cooldown = 0.05  -- 50ms 중복 방지

-- ============================================
-- Initialization
-- ============================================
function WeaponDetector.init(game_cfg, bus, cfg, log)
    game_config = game_cfg
    event_bus = bus
    config = cfg
    logger = log or { 
        info = function(m) log.info(m) end,
        warn = function(m) log.warn(m) end
    }
    
    WeaponDetector.setup_hooks()
    
    logger.info("[WeaponDetector] Initialized for " .. game_config.game_name)
end

-- ============================================
-- Hook Setup
-- ============================================
function WeaponDetector.setup_hooks()
    local hooks = game_config.hooks.weapon or {}
    
    for _, hook_info in ipairs(hooks) do
        local success = WeaponDetector.hook_method(hook_info)
        if success then
            table.insert(hooked_methods, hook_info)
        end
    end
    
    logger.info("[WeaponDetector] Hooked " .. #hooked_methods .. " weapon methods")
end

function WeaponDetector.hook_method(hook_info)
    local type_def = sdk.find_type_definition(hook_info.type)
    if not type_def then
        logger.warn("[WeaponDetector] Type not found: " .. hook_info.type)
        return false
    end
    
    local method = type_def:get_method(hook_info.method)
    if not method then
        logger.warn("[WeaponDetector] Method not found: " .. hook_info.type .. "." .. hook_info.method)
        return false
    end
    
    local success, err = pcall(function()
        sdk.hook(
            method,
            function(args) return WeaponDetector.on_pre_action(args, hook_info) end,
            function(retval) return retval end
        )
    end)
    
    if success then
        logger.info("[WeaponDetector] Hooked: " .. hook_info.type .. "." .. hook_info.method)
        return true
    else
        logger.warn("[WeaponDetector] Failed to hook: " .. tostring(err))
        return false
    end
end

-- ============================================
-- Action Handler
-- ============================================
function WeaponDetector.on_pre_action(args, hook_info)
    local event_type = hook_info.event_type or "weapon_action"
    
    -- 이벤트 활성화 확인
    if not config.get("events." .. event_type) then
        return nil
    end
    
    -- 중복 발사 방지 (gun_fire만)
    if event_type == "gun_fire" then
        local current_time = os.clock()
        if current_time - last_fire_time < fire_cooldown then
            return nil
        end
        last_fire_time = current_time
    end
    
    -- 무기 정보 추출
    local weapon_info = WeaponDetector.extract_weapon_info(args, hook_info)
    
    event_bus.emit(event_type, {
        weapon_name = weapon_info.name,
        weapon_type = hook_info.weapon_type or "unknown",
        weapon_class = weapon_info.class,
        ammo_count = weapon_info.ammo,
        hand = hook_info.hand or "right",
        source = "weapon_hook"
    })
    
    return nil
end

-- ============================================
-- Weapon Info Extraction
-- ============================================
function WeaponDetector.extract_weapon_info(args, hook_info)
    local info = {
        name = "Unknown",
        class = hook_info.type,
        ammo = nil
    }
    
    -- args[2]가 보통 this (무기 객체)
    if args[2] then
        local weapon_obj = sdk.to_managed_object(args[2])
        
        if weapon_obj then
            -- 무기 이름
            info.name = WeaponDetector.get_weapon_name(weapon_obj)
            
            -- 탄약 수 (총기인 경우)
            if hook_info.weapon_type == "gun" then
                info.ammo = WeaponDetector.get_ammo_count(weapon_obj)
            end
        end
    end
    
    return info
end

function WeaponDetector.get_weapon_name(weapon_obj)
    -- 여러 방법으로 이름 가져오기 시도
    local methods = {"get_Name", "getName", "get_WeaponName", "get_DisplayName"}
    
    for _, method_name in ipairs(methods) do
        local success, result = pcall(weapon_obj.call, weapon_obj, method_name)
        if success and result then
            return tostring(result)
        end
    end
    
    -- 타입 이름 반환
    local type_def = weapon_obj:get_type_definition()
    if type_def then
        return type_def:get_name()
    end
    
    return "Unknown"
end

function WeaponDetector.get_ammo_count(weapon_obj)
    local methods = {"get_CurrentAmmo", "get_AmmoCount", "getCurrentBulletNum"}
    
    for _, method_name in ipairs(methods) do
        local success, result = pcall(weapon_obj.call, weapon_obj, method_name)
        if success and type(result) == "number" then
            return result
        end
    end
    
    return nil
end

-- ============================================
-- Debug
-- ============================================
function WeaponDetector.get_hooked_methods()
    return hooked_methods
end

return WeaponDetector
