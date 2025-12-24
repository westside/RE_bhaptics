-- ============================================
-- RE_bHaptics Mod - Main Entry Point
-- ============================================
-- Place this file in: [game_folder]/reframework/autorun/
-- 
-- This mod detects game events (damage, weapon fire, etc.)
-- and will integrate with bHaptics haptic suits in Phase 2.
-- ============================================

local MOD_NAME = "RE_bHaptics"
local MOD_VERSION = "0.1.0"
local MOD_AUTHOR = "Your Name"

-- ============================================
-- Module Loading
-- ============================================

-- Core 모듈 로드 (autorun 폴더 기준)
local logger = require("logger")
local event_bus = require("event_bus")
local config = require("config")

-- 설정 초기화
config.init()
logger.set_level(config.get("log_level") or logger.LEVEL.DEBUG)

logger.info("========================================")
logger.info(MOD_NAME .. " v" .. MOD_VERSION)
logger.info("========================================")

-- ============================================
-- Game Detection
-- ============================================
local game_name = reframework:get_game_name()
local game_config = nil

logger.info("Detected game: " .. game_name)

-- 게임별 설정 로드 (autorun 폴더 기준)
if game_name == "re7" then
    local success, cfg = pcall(require, "re7")
    if success then game_config = cfg end
elseif game_name == "re8" then
    local success, cfg = pcall(require, "re8")
    if success then game_config = cfg end
elseif game_name == "re2" then
    local success, cfg = pcall(require, "re2")
    if success then game_config = cfg end
elseif game_name == "re4" then
    local success, cfg = pcall(require, "re4")
    if success then game_config = cfg end
end

if not game_config then
    logger.error("Unsupported game or failed to load config: " .. game_name)
    logger.error("Supported games: re7, re8, re2, re4")
    return
end

logger.info("Loaded config for: " .. game_config.game_title)

-- ============================================
-- Detector Modules
-- ============================================
local health_detector = nil
local damage_detector = nil
local weapon_detector = nil
local cinematic_detector = nil

-- 체력 감지기
local success, hd = pcall(require, "health_detector")
if success then
    health_detector = hd
    health_detector.init(game_config, event_bus, config, logger)
else
    logger.warn("Failed to load health_detector: " .. tostring(hd))
end

-- 피격 감지기
local success, dd = pcall(require, "damage_detector")
if success then
    damage_detector = dd
    damage_detector.init(game_config, event_bus, config, logger)
else
    logger.warn("Failed to load damage_detector: " .. tostring(dd))
end

-- 무기 감지기
local success, wd = pcall(require, "weapon_detector")
if success then
    weapon_detector = wd
    weapon_detector.init(game_config, event_bus, config, logger)
else
    logger.warn("Failed to load weapon_detector: " .. tostring(wd))
end

-- 시네마틱/진행상태 감지기
local success, cd = pcall(require, "cinematic_detector")
if success then
    cinematic_detector = cd
    cinematic_detector.init(game_config, event_bus, config, logger)
else
    logger.warn("Failed to load cinematic_detector: " .. tostring(cd))
end

-- ============================================
-- Event Listeners (Debug)
-- ============================================

-- 모든 이벤트 로깅 (디버그 모드)
if config.get("debug_mode") then
    event_bus.on("*", function(data)
        local event_name = data._event_name or "unknown"
        logger.debug("EVENT: " .. event_name)
    end, 999)  -- 낮은 우선순위
end

-- 개별 이벤트 리스너
event_bus.on("player_hit", function(data)
    logger.info(string.format(
        "PLAYER_HIT | damage=%d | health=%.0f%% | severity=%s",
        data.damage or 0,
        (data.health_percent or 0) * 100,
        data.severity or "unknown"
    ))
end)

event_bus.on("player_hit_direction", function(data)
    logger.info(string.format(
        "PLAYER_HIT_DIRECTION | damage=%d | direction=%s",
        data.damage or 0,
        data.direction or "unknown"
    ))
end)

event_bus.on("gun_fire", function(data)
    logger.info(string.format(
        "GUN_FIRE | weapon=%s | type=%s",
        data.weapon_name or "unknown",
        data.weapon_type or "unknown"
    ))
end)

event_bus.on("gun_reload", function(data)
    logger.info(string.format(
        "GUN_RELOAD | weapon=%s",
        data.weapon_name or "unknown"
    ))
end)

event_bus.on("melee_attack", function(data)
    logger.info(string.format(
        "MELEE_ATTACK | weapon=%s",
        data.weapon_name or "unknown"
    ))
end)

event_bus.on("heartbeat", function(data)
    logger.debug(string.format(
        "HEARTBEAT | health=%.0f%% | intensity=%.2f",
        (data.health_percent or 0) * 100,
        data.intensity or 0
    ))
end)

event_bus.on("heal", function(data)
    logger.info(string.format(
        "HEAL | amount=%d | health=%.0f%%",
        data.amount or 0,
        (data.health_percent or 0) * 100
    ))
end)

-- 시네마틱/진행상태 이벤트
event_bus.on("cutscene_start", function(data)
    logger.info(string.format(
        "CUTSCENE_START | name=%s | chapter=%s",
        tostring(data.cutscene_name or "unknown"),
        tostring(data.chapter or "?")
    ))
end)

event_bus.on("cutscene_end", function(data)
    logger.info(string.format(
        "CUTSCENE_END | name=%s | duration=%.1fs",
        tostring(data.cutscene_name or "unknown"),
        data.duration or 0
    ))
end)

event_bus.on("chapter_change", function(data)
    logger.info(string.format(
        "CHAPTER_CHANGE | %s -> %s | area=%s",
        tostring(data.previous_chapter or "?"),
        tostring(data.current_chapter or "?"),
        tostring(data.area or "unknown")
    ))
end)

event_bus.on("scene_change", function(data)
    logger.info(string.format(
        "SCENE_CHANGE | %s -> %s",
        tostring(data.previous_scene or "?"),
        tostring(data.current_scene or "?")
    ))
end)

event_bus.on("loading_start", function(data)
    logger.info("LOADING_START | scene=" .. tostring(data.scene or "unknown"))
end)

event_bus.on("loading_end", function(data)
    logger.info("LOADING_END | scene=" .. tostring(data.scene or "unknown"))
end)

-- ============================================
-- Debug UI (ImGui)
-- ============================================
local show_debug_window = false

re.on_draw_ui(function()
    if imgui.tree_node(MOD_NAME .. " v" .. MOD_VERSION) then
        
        -- 토글 버튼들
        local changed, enabled = imgui.checkbox("Mod Enabled", config.get("enabled"))
        if changed then
            config.set("enabled", enabled)
            config.save()
        end
        
        changed, show_debug_window = imgui.checkbox("Show Debug Window", show_debug_window)
        
        imgui.separator()
        
        -- 이벤트 활성화
        if imgui.tree_node("Event Toggles") then
            local events = {
                "player_hit", "player_hit_direction", "gun_fire", "gun_reload", 
                "melee_attack", "heartbeat", "heal",
                "cutscene_start", "cutscene_end", "chapter_change", "scene_change",
                "loading_start", "loading_end"
            }
            for _, event_name in ipairs(events) do
                local event_enabled = config.get("events." .. event_name)
                local changed, new_value = imgui.checkbox(event_name, event_enabled)
                if changed then
                    config.set("events." .. event_name, new_value)
                end
            end
            
            if imgui.button("Save Settings") then
                config.save()
                logger.info("Settings saved")
            end
            
            imgui.tree_pop()
        end
        
        -- 최근 이벤트
        if imgui.tree_node("Recent Events") then
            local history = event_bus.get_history(nil, 10)
            for _, entry in ipairs(history) do
                imgui.text(string.format("%.2f: %s", entry.time, entry.name))
            end
            imgui.tree_pop()
        end
        
        -- 체력 정보
        if health_detector and imgui.tree_node("Health State") then
            local state = health_detector.get_state()
            imgui.text("Previous HP: " .. tostring(state.previous_health))
            imgui.text("Initialized: " .. tostring(state.is_initialized))
            imgui.text("Heartbeat Active: " .. tostring(state.heartbeat_active))
            imgui.tree_pop()
        end
        
        -- 시네마틱/진행상태 정보
        if cinematic_detector and imgui.tree_node("Cinematic State") then
            local state = cinematic_detector.get_state()
            imgui.text("In Cutscene: " .. tostring(state.is_in_cutscene))
            imgui.text("Cutscene Name: " .. tostring(state.cutscene_name or "N/A"))
            imgui.text("Current Chapter: " .. tostring(state.current_chapter or "N/A"))
            imgui.text("Current Scene: " .. tostring(state.current_scene or "N/A"))
            imgui.text("Current Area: " .. tostring(state.current_area or "N/A"))
            imgui.text("Is Loading: " .. tostring(state.is_loading))
            imgui.text("Player Controllable: " .. tostring(state.is_player_controllable))
            imgui.tree_pop()
        end
        
        imgui.tree_pop()
    end
end)

-- 별도 디버그 창
re.on_frame(function()
    if show_debug_window then
        if imgui.begin_window(MOD_NAME .. " Debug", true) then
            imgui.text("Game: " .. game_config.game_title)
            imgui.text("Events Registered: " .. #event_bus.get_registered_events())
            
            imgui.separator()
            imgui.text("Event History:")
            
            local history = event_bus.get_history(nil, 20)
            for _, entry in ipairs(history) do
                local time_str = string.format("%.2f", entry.time)
                imgui.text("[" .. time_str .. "] " .. entry.name)
            end
            
            imgui.end_window()
        end
    end
end)

-- ============================================
-- Initialization Complete
-- ============================================
logger.info("Event detection system initialized")
logger.info("Registered events: " .. table.concat(event_bus.get_registered_events(), ", "))
logger.info("========================================")
