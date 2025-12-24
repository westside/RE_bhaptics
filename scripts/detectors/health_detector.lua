-- Health Change Detection Module
-- Monitors player health and emits events on changes

local HealthDetector = {}

-- Dependencies (will be injected via init)
local event_bus = nil
local game_config = nil
local config = nil
local logger = nil

-- State
local state = {
    previous_health = nil,
    previous_max_health = nil,
    is_initialized = false,
    heartbeat_active = false,
    last_heartbeat_time = 0
}

-- ============================================
-- Initialization
-- ============================================
function HealthDetector.init(game_cfg, bus, cfg, log)
    game_config = game_cfg
    event_bus = bus
    config = cfg
    logger = log or { 
        info = function(m) log.info(m) end,
        debug = function(m) log.info(m) end,
        error = function(m) log.error(m) end
    }
    
    -- 매 프레임 감시 등록
    re.on_frame(HealthDetector.on_frame)
    
    logger.info("[HealthDetector] Initialized for " .. game_config.game_name)
end

-- ============================================
-- Per-Frame Health Check
-- ============================================
function HealthDetector.on_frame()
    if not config or not config.get("enabled") then return end
    
    local player = HealthDetector.get_player()
    if not player then 
        state.is_initialized = false
        return 
    end
    
    local current_health = HealthDetector.get_health(player)
    local max_health = HealthDetector.get_max_health(player)
    
    if current_health == nil or max_health == nil then return end
    if max_health <= 0 then return end
    
    -- 첫 프레임 초기화
    if not state.is_initialized then
        state.previous_health = current_health
        state.previous_max_health = max_health
        state.is_initialized = true
        logger.debug("[HealthDetector] State initialized: HP=" .. current_health .. "/" .. max_health)
        return
    end
    
    local health_percent = current_health / max_health
    
    -- 체력 감소 감지 (피격)
    if current_health < state.previous_health then
        local damage = state.previous_health - current_health
        HealthDetector.on_damage(damage, current_health, max_health, health_percent)
    end
    
    -- 체력 증가 감지 (회복)
    if current_health > state.previous_health then
        local healed = current_health - state.previous_health
        HealthDetector.on_heal(healed, current_health, max_health, health_percent)
    end
    
    -- 저체력 심장박동
    HealthDetector.check_heartbeat(health_percent)
    
    -- 상태 업데이트
    state.previous_health = current_health
    state.previous_max_health = max_health
end

-- ============================================
-- Event Handlers
-- ============================================
function HealthDetector.on_damage(damage, current, max, percent)
    if not config.get("events.player_hit") then return end
    
    local severity = HealthDetector.get_damage_severity(damage, max)
    
    event_bus.emit("player_hit", {
        damage = damage,
        current_health = current,
        max_health = max,
        health_percent = percent,
        severity = severity,
        direction = "unknown",  -- 방향은 DamageDetector에서 처리
        source = "health_monitor"
    })
    
    -- 체력 상태 변화 이벤트
    local threshold = HealthDetector.get_health_state(percent)
    event_bus.emit("health_state", {
        state = threshold,
        percent = percent
    })
end

function HealthDetector.on_heal(amount, current, max, percent)
    if not config.get("events.heal") then return end
    
    event_bus.emit("heal", {
        amount = amount,
        current_health = current,
        max_health = max,
        health_percent = percent
    })
end

function HealthDetector.check_heartbeat(health_percent)
    if not config.get("events.heartbeat") then return end
    
    local threshold = config.get("detection.low_health_threshold") or 0.3
    local interval = config.get("detection.heartbeat_interval") or 1.0
    
    if health_percent <= threshold then
        local current_time = os.clock()
        
        -- 체력이 낮을수록 빠른 심장박동
        local speed_multiplier = 1 - (health_percent / threshold)
        local adjusted_interval = interval * (1 - speed_multiplier * 0.5)
        
        if not state.heartbeat_active or (current_time - state.last_heartbeat_time) >= adjusted_interval then
            state.heartbeat_active = true
            state.last_heartbeat_time = current_time
            
            event_bus.emit("heartbeat", {
                health_percent = health_percent,
                intensity = speed_multiplier,
                interval = adjusted_interval
            })
        end
    else
        state.heartbeat_active = false
    end
end

-- ============================================
-- Helper Functions
-- ============================================
function HealthDetector.get_player()
    local player_manager_name = game_config.singletons.player_manager
    local player_manager = sdk.get_managed_singleton(player_manager_name)
    
    if not player_manager then return nil end
    
    local method_name = game_config.methods.get_current_player
    local success, player = pcall(player_manager.call, player_manager, method_name)
    
    if success then return player end
    return nil
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

function HealthDetector.get_damage_severity(damage, max_health)
    local percent = damage / max_health
    if percent >= 0.3 then return "critical"
    elseif percent >= 0.15 then return "high"
    elseif percent >= 0.05 then return "medium"
    else return "low" end
end

function HealthDetector.get_health_state(percent)
    local thresholds = game_config.health_thresholds or {}
    if percent <= (thresholds.critical or 0.15) then return "critical"
    elseif percent <= (thresholds.low or 0.30) then return "low"
    elseif percent <= (thresholds.medium or 0.60) then return "medium"
    else return "healthy" end
end

-- ============================================
-- Debug
-- ============================================
function HealthDetector.get_state()
    return state
end

function HealthDetector.reset()
    state.is_initialized = false
    state.previous_health = nil
    state.heartbeat_active = false
end

return HealthDetector
