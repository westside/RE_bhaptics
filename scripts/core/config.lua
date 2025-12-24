-- RE_bHaptics Configuration Manager
-- Handles loading/saving mod settings

local Config = {}

Config.defaults = {
    -- 일반 설정
    enabled = true,
    debug_mode = true,
    log_level = 1,  -- DEBUG
    
    -- 이벤트 감지 설정
    detection = {
        health_check_interval = 0,  -- 0 = every frame
        low_health_threshold = 0.3,
        heartbeat_interval = 1.0,
        enable_direction_detection = true
    },
    
    -- 햅틱 설정 (Phase 2)
    haptics = {
        enabled = false,  -- Phase 2에서 활성화
        intensity_multiplier = 1.0,
        vest_enabled = true,
        arms_enabled = true
    },
    
    -- 이벤트별 활성화
    events = {
        player_hit = true,
        player_hit_direction = true,
        gun_fire = true,
        gun_reload = true,
        heartbeat = true,
        heal = true,
        melee_attack = true,
        item_use = true,
        -- 시네마틱/진행상태 이벤트
        cutscene_start = true,
        cutscene_end = true,
        chapter_change = true,
        scene_change = true,
        loading_start = true,
        loading_end = true
    }
}

Config.current = nil
Config.config_path = nil

-- 설정 초기화
function Config.init()
    Config.current = Config.deep_copy(Config.defaults)
    
    -- 설정 파일 경로 결정
    local game_name = reframework:get_game_name()
    Config.config_path = "re_bhaptics_" .. game_name .. ".json"
    
    -- 저장된 설정 로드 시도
    Config.load()
end

-- 설정 로드
function Config.load()
    local file = io.open(Config.config_path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        
        local success, loaded = pcall(json.load_string, content)
        if success and loaded then
            Config.merge(loaded)
            log.info("[Config] Loaded settings from " .. Config.config_path)
        end
    end
end

-- 설정 저장
function Config.save()
    local content = json.dump_string(Config.current, 2)
    local file = io.open(Config.config_path, "w")
    if file then
        file:write(content)
        file:close()
        log.info("[Config] Saved settings to " .. Config.config_path)
    end
end

-- 설정 값 가져오기
function Config.get(path)
    local parts = Config.split(path, ".")
    local current = Config.current
    
    for _, part in ipairs(parts) do
        if type(current) == "table" and current[part] ~= nil then
            current = current[part]
        else
            return nil
        end
    end
    
    return current
end

-- 설정 값 설정
function Config.set(path, value)
    local parts = Config.split(path, ".")
    local current = Config.current
    
    for i = 1, #parts - 1 do
        local part = parts[i]
        if type(current[part]) ~= "table" then
            current[part] = {}
        end
        current = current[part]
    end
    
    current[parts[#parts]] = value
end

-- 설정 병합
function Config.merge(source, target)
    target = target or Config.current
    
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            Config.merge(v, target[k])
        else
            target[k] = v
        end
    end
end

-- 딥 카피
function Config.deep_copy(orig)
    local copy
    if type(orig) == "table" then
        copy = {}
        for k, v in next, orig, nil do
            copy[Config.deep_copy(k)] = Config.deep_copy(v)
        end
        setmetatable(copy, Config.deep_copy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- 문자열 분할
function Config.split(str, sep)
    local result = {}
    for part in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(result, part)
    end
    return result
end

-- 설정 리셋
function Config.reset()
    Config.current = Config.deep_copy(Config.defaults)
    Config.save()
end

return Config
