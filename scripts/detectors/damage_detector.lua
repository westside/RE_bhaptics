-- Direct Damage Detection Module
-- Hooks damage methods to detect hits with direction info

local DamageDetector = {}

-- Dependencies
local event_bus = nil
local game_config = nil
local config = nil
local logger = nil

-- State
local hooked_methods = {}

-- ============================================
-- Initialization
-- ============================================
function DamageDetector.init(game_cfg, bus, cfg, log)
    game_config = game_cfg
    event_bus = bus
    config = cfg
    logger = log or { 
        info = function(m) log.info(m) end,
        warn = function(m) log.warn(m) end,
        error = function(m) log.error(m) end
    }
    
    -- 피격 메서드 후킹
    DamageDetector.setup_hooks()
    
    logger.info("[DamageDetector] Initialized for " .. game_config.game_name)
end

-- ============================================
-- Hook Setup
-- ============================================
function DamageDetector.setup_hooks()
    local hooks = game_config.hooks.damage or {}
    
    for _, hook_info in ipairs(hooks) do
        local success = DamageDetector.hook_method(hook_info)
        if success then
            table.insert(hooked_methods, hook_info)
        end
    end
    
    logger.info("[DamageDetector] Hooked " .. #hooked_methods .. " damage methods")
end

function DamageDetector.hook_method(hook_info)
    local type_def = sdk.find_type_definition(hook_info.type)
    if not type_def then
        logger.warn("[DamageDetector] Type not found: " .. hook_info.type)
        return false
    end
    
    local method = type_def:get_method(hook_info.method)
    if not method then
        logger.warn("[DamageDetector] Method not found: " .. hook_info.type .. "." .. hook_info.method)
        return false
    end
    
    local success, err = pcall(function()
        sdk.hook(
            method,
            function(args) return DamageDetector.on_pre_damage(args, hook_info) end,
            function(retval) return retval end
        )
    end)
    
    if success then
        logger.info("[DamageDetector] Hooked: " .. hook_info.type .. "." .. hook_info.method)
        return true
    else
        logger.error("[DamageDetector] Failed to hook: " .. hook_info.type .. "." .. hook_info.method .. " - " .. tostring(err))
        return false
    end
end

-- ============================================
-- Damage Handler
-- ============================================
function DamageDetector.on_pre_damage(args, hook_info)
    if not config or not config.get("events.player_hit_direction") then 
        return nil 
    end
    
    local damage_info = DamageDetector.extract_damage_info(args, hook_info)
    
    if damage_info then
        event_bus.emit("player_hit_direction", {
            damage = damage_info.damage,
            direction = damage_info.direction,
            direction_vector = damage_info.direction_vector,
            hit_position = damage_info.hit_position,
            attacker = damage_info.attacker,
            source = "damage_hook",
            hook_type = hook_info.type .. "." .. hook_info.method
        })
    end
    
    return nil  -- 원래 동작 유지
end

-- ============================================
-- Damage Info Extraction
-- ============================================
function DamageDetector.extract_damage_info(args, hook_info)
    local result = {
        damage = 0,
        direction = "front",
        direction_vector = nil,
        hit_position = nil,
        attacker = nil
    }
    
    -- 데미지 정보 객체 추출
    local damage_arg_index = hook_info.damage_arg or 3
    
    if args[damage_arg_index] then
        local damage_obj = sdk.to_managed_object(args[damage_arg_index])
        
        if damage_obj then
            -- 데미지 값
            result.damage = DamageDetector.safe_get_field(damage_obj, 
                game_config.damage_info.damage_field or "Damage") or 0
            
            -- 방향 벡터
            local dir_vec = DamageDetector.safe_get_field(damage_obj, 
                game_config.damage_info.direction_field or "Direction")
            
            if dir_vec then
                result.direction_vector = dir_vec
                result.direction = DamageDetector.vector_to_direction(dir_vec)
            end
            
            -- 피격 위치
            result.hit_position = DamageDetector.safe_get_field(damage_obj,
                game_config.damage_info.hit_position_field or "HitPosition")
            
            -- 공격자
            result.attacker = DamageDetector.safe_get_field(damage_obj,
                game_config.damage_info.attacker_field or "Attacker")
        end
    end
    
    return result
end

function DamageDetector.safe_get_field(obj, field_name)
    if not obj or not field_name then return nil end
    
    local success, result = pcall(function()
        return obj:get_field(field_name)
    end)
    
    if success then return result end
    return nil
end

-- ============================================
-- Direction Calculation
-- ============================================
function DamageDetector.vector_to_direction(vec)
    if not vec then return "front" end
    
    -- 벡터 컴포넌트 추출
    local x, z
    
    if type(vec) == "table" then
        x = vec.x or vec[1] or 0
        z = vec.z or vec[3] or 0
    else
        -- REManagedObject인 경우
        local success_x, res_x = pcall(function() return vec:get_field("x") or vec.x end)
        local success_z, res_z = pcall(function() return vec:get_field("z") or vec.z end)
        x = success_x and res_x or 0
        z = success_z and res_z or 0
    end
    
    -- 4방향으로 변환
    if math.abs(x) > math.abs(z) then
        return x > 0 and "right" or "left"
    else
        return z > 0 and "front" or "back"
    end
end

function DamageDetector.vector_to_direction_8(vec)
    if not vec then return "front" end
    
    local x = vec.x or 0
    local z = vec.z or 0
    local angle = math.atan2(x, z) * (180 / math.pi)
    
    -- 8방향
    if angle >= -22.5 and angle < 22.5 then return "front"
    elseif angle >= 22.5 and angle < 67.5 then return "front_right"
    elseif angle >= 67.5 and angle < 112.5 then return "right"
    elseif angle >= 112.5 and angle < 157.5 then return "back_right"
    elseif angle >= 157.5 or angle < -157.5 then return "back"
    elseif angle >= -157.5 and angle < -112.5 then return "back_left"
    elseif angle >= -112.5 and angle < -67.5 then return "left"
    else return "front_left" end
end

-- ============================================
-- Debug
-- ============================================
function DamageDetector.get_hooked_methods()
    return hooked_methods
end

return DamageDetector
