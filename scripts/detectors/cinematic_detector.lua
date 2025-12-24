-- Cinematic & Game Progress Detection Module
-- Detects cutscenes, chapter changes, loading screens, and game state transitions

local CinematicDetector = {}

-- Dependencies
local event_bus = nil
local game_config = nil
local config = nil
local logger = nil

-- State
local state = {
    -- 컷씬 상태
    is_in_cutscene = false,
    cutscene_name = nil,
    cutscene_start_time = 0,
    
    -- 게임 진행 상태
    current_chapter = nil,
    current_scene = nil,
    current_area = nil,
    
    -- 로딩 상태
    is_loading = false,
    
    -- 플레이어 상태
    is_player_controllable = true,
    
    -- 이전 프레임 상태 (변화 감지용)
    prev_chapter = nil,
    prev_scene = nil,
    prev_is_cutscene = false,
    prev_is_loading = false
}

-- ============================================
-- Initialization
-- ============================================
function CinematicDetector.init(game_cfg, bus, cfg, log)
    game_config = game_cfg
    event_bus = bus
    config = cfg
    logger = log or {
        info = function(m) log.info(m) end,
        debug = function(m) log.info(m) end
    }
    
    -- 프레임마다 상태 체크
    re.on_frame(CinematicDetector.on_frame)
    
    -- 메서드 후킹 설정
    CinematicDetector.setup_hooks()
    
    logger.info("[CinematicDetector] Initialized for " .. game_config.game_name)
end

-- ============================================
-- Per-Frame State Check
-- ============================================
function CinematicDetector.on_frame()
    if not config or not config.get("enabled") then return end
    
    -- 각 상태 체크
    CinematicDetector.check_cutscene_state()
    CinematicDetector.check_game_progress()
    CinematicDetector.check_loading_state()
    CinematicDetector.check_player_control()
    
    -- 상태 변화 감지 및 이벤트 발생
    CinematicDetector.detect_changes()
    
    -- 이전 상태 저장
    state.prev_chapter = state.current_chapter
    state.prev_scene = state.current_scene
    state.prev_is_cutscene = state.is_in_cutscene
    state.prev_is_loading = state.is_loading
end

-- ============================================
-- Cutscene Detection
-- ============================================
function CinematicDetector.check_cutscene_state()
    local is_cutscene = false
    local cutscene_name = nil
    
    -- 방법 1: CutsceneManager / MovieManager 확인
    local cutscene_managers = {
        "app.CutsceneManager",
        "app.MovieManager",
        "app.EventManager",
        "app.DemoManager"
    }
    
    for _, manager_name in ipairs(cutscene_managers) do
        local manager = sdk.get_managed_singleton(manager_name)
        if manager then
            -- 컷씬 재생 중인지 확인
            local playing = CinematicDetector.safe_call(manager, "get_IsPlaying")
                         or CinematicDetector.safe_call(manager, "get_isPlaying")
                         or CinematicDetector.safe_call(manager, "isPlaying")
            
            if playing then
                is_cutscene = true
                
                -- 컷씬 이름 가져오기
                cutscene_name = CinematicDetector.safe_call(manager, "get_CurrentCutsceneName")
                            or CinematicDetector.safe_call(manager, "get_CurrentMovieName")
                            or CinematicDetector.safe_call(manager, "get_Name")
                break
            end
        end
    end
    
    -- 방법 2: 현재 씬의 타임스케일 확인 (컷씬 중 종종 변경됨)
    if not is_cutscene then
        local scene = CinematicDetector.get_current_scene()
        if scene then
            local timescale = CinematicDetector.safe_call(scene, "get_TimeScale")
            -- 타임스케일이 1이 아니면 특수 상황일 수 있음
        end
    end
    
    -- 방법 3: 플레이어 컨트롤 불가 + 카메라 변경 = 컷씬 가능성
    if not is_cutscene then
        local camera_manager = sdk.get_managed_singleton("app.CameraManager")
        if camera_manager then
            local camera_mode = CinematicDetector.safe_call(camera_manager, "get_CurrentCameraMode")
                             or CinematicDetector.safe_call(camera_manager, "get_CameraMode")
            
            -- 카메라 모드가 "Cutscene" 또는 특정 값이면 컷씬
            if camera_mode then
                local mode_name = tostring(camera_mode)
                if mode_name:find("Cutscene") or mode_name:find("Event") or mode_name:find("Demo") then
                    is_cutscene = true
                end
            end
        end
    end
    
    state.is_in_cutscene = is_cutscene
    state.cutscene_name = cutscene_name
    
    if is_cutscene and not state.prev_is_cutscene then
        state.cutscene_start_time = os.clock()
    end
end

-- ============================================
-- Game Progress / Chapter Detection
-- ============================================
function CinematicDetector.check_game_progress()
    -- GameManager에서 진행 상태 가져오기
    local game_manager = sdk.get_managed_singleton("app.GameManager")
    if not game_manager then return end
    
    -- 챕터/스테이지 정보
    state.current_chapter = CinematicDetector.safe_call(game_manager, "get_CurrentChapter")
                         or CinematicDetector.safe_call(game_manager, "get_Chapter")
                         or CinematicDetector.safe_call(game_manager, "get_StageNo")
                         or CinematicDetector.safe_call(game_manager, "get_CurrentStage")
    
    -- 씬/에어리어 정보
    state.current_scene = CinematicDetector.safe_call(game_manager, "get_CurrentSceneName")
                       or CinematicDetector.safe_call(game_manager, "get_SceneName")
    
    state.current_area = CinematicDetector.safe_call(game_manager, "get_CurrentAreaName")
                      or CinematicDetector.safe_call(game_manager, "get_AreaName")
                      or CinematicDetector.safe_call(game_manager, "get_CurrentArea")
    
    -- ProgressManager가 있는 경우
    local progress_manager = sdk.get_managed_singleton("app.ProgressManager")
    if progress_manager then
        local progress = CinematicDetector.safe_call(progress_manager, "get_CurrentProgress")
                      or CinematicDetector.safe_call(progress_manager, "get_Progress")
        
        if progress and not state.current_chapter then
            state.current_chapter = progress
        end
    end
    
    -- SaveDataManager에서 정보 가져오기
    local save_manager = sdk.get_managed_singleton("app.SaveDataManager")
    if save_manager then
        local save_data = CinematicDetector.safe_call(save_manager, "get_CurrentSaveData")
        if save_data then
            local chapter = CinematicDetector.safe_call(save_data, "get_Chapter")
                         or CinematicDetector.safe_call(save_data, "get_ScenarioProgress")
            if chapter and not state.current_chapter then
                state.current_chapter = chapter
            end
        end
    end
end

-- ============================================
-- Loading Screen Detection
-- ============================================
function CinematicDetector.check_loading_state()
    local is_loading = false
    
    -- 방법 1: SceneManager 확인
    local scene_manager = sdk.get_native_singleton("via.SceneManager")
    if scene_manager then
        local scene_manager_type = sdk.find_type_definition("via.SceneManager")
        if scene_manager_type then
            local is_loading_scene = sdk.call_native_func(
                scene_manager, 
                scene_manager_type, 
                "get_IsLoading"
            )
            if is_loading_scene then
                is_loading = true
            end
        end
    end
    
    -- 방법 2: LoadingManager 확인
    local loading_managers = {
        "app.LoadingManager",
        "app.LoadManager",
        "app.StreamingManager"
    }
    
    for _, manager_name in ipairs(loading_managers) do
        local manager = sdk.get_managed_singleton(manager_name)
        if manager then
            local loading = CinematicDetector.safe_call(manager, "get_IsLoading")
                         or CinematicDetector.safe_call(manager, "get_isLoading")
                         or CinematicDetector.safe_call(manager, "isLoading")
            
            if loading then
                is_loading = true
                break
            end
        end
    end
    
    -- 방법 3: Fade 상태 확인 (로딩 중 화면 페이드)
    local fade_manager = sdk.get_managed_singleton("app.FadeManager")
    if fade_manager then
        local is_fading = CinematicDetector.safe_call(fade_manager, "get_IsFading")
                       or CinematicDetector.safe_call(fade_manager, "isFading")
        -- 페이드 중이면 로딩/전환 중일 수 있음
    end
    
    state.is_loading = is_loading
end

-- ============================================
-- Player Control Detection
-- ============================================
function CinematicDetector.check_player_control()
    local is_controllable = true
    
    -- InputManager에서 입력 가능 여부 확인
    local input_manager = sdk.get_managed_singleton("app.InputManager")
    if input_manager then
        local input_enabled = CinematicDetector.safe_call(input_manager, "get_IsInputEnabled")
                           or CinematicDetector.safe_call(input_manager, "get_isEnable")
        
        if input_enabled == false then
            is_controllable = false
        end
    end
    
    -- PlayerManager에서 조작 가능 여부 확인
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    if player_manager then
        local can_control = CinematicDetector.safe_call(player_manager, "get_IsControllable")
                         or CinematicDetector.safe_call(player_manager, "get_CanControl")
        
        if can_control == false then
            is_controllable = false
        end
    end
    
    -- 컷씬이나 로딩 중이면 조작 불가
    if state.is_in_cutscene or state.is_loading then
        is_controllable = false
    end
    
    state.is_player_controllable = is_controllable
end

-- ============================================
-- Change Detection & Events
-- ============================================
function CinematicDetector.detect_changes()
    -- 컷씬 시작
    if state.is_in_cutscene and not state.prev_is_cutscene then
        event_bus.emit("cutscene_start", {
            cutscene_name = state.cutscene_name,
            chapter = state.current_chapter,
            scene = state.current_scene
        })
    end
    
    -- 컷씬 종료
    if not state.is_in_cutscene and state.prev_is_cutscene then
        local duration = os.clock() - state.cutscene_start_time
        event_bus.emit("cutscene_end", {
            cutscene_name = state.cutscene_name,
            duration = duration,
            chapter = state.current_chapter
        })
    end
    
    -- 챕터 변경
    if state.current_chapter ~= state.prev_chapter and state.prev_chapter ~= nil then
        event_bus.emit("chapter_change", {
            previous_chapter = state.prev_chapter,
            current_chapter = state.current_chapter,
            scene = state.current_scene,
            area = state.current_area
        })
    end
    
    -- 씬 변경
    if state.current_scene ~= state.prev_scene and state.prev_scene ~= nil then
        event_bus.emit("scene_change", {
            previous_scene = state.prev_scene,
            current_scene = state.current_scene,
            chapter = state.current_chapter
        })
    end
    
    -- 로딩 시작
    if state.is_loading and not state.prev_is_loading then
        event_bus.emit("loading_start", {
            scene = state.current_scene,
            chapter = state.current_chapter
        })
    end
    
    -- 로딩 종료
    if not state.is_loading and state.prev_is_loading then
        event_bus.emit("loading_end", {
            scene = state.current_scene,
            chapter = state.current_chapter
        })
    end
end

-- ============================================
-- Method Hooks (Alternative Detection)
-- ============================================
function CinematicDetector.setup_hooks()
    -- 컷씬 관련 메서드 후킹
    local cutscene_hooks = {
        { type = "app.CutsceneManager", method = "play", event = "cutscene_trigger" },
        { type = "app.CutsceneManager", method = "startCutscene", event = "cutscene_trigger" },
        { type = "app.MovieManager", method = "play", event = "movie_trigger" },
        { type = "app.DemoManager", method = "startDemo", event = "demo_trigger" },
        { type = "app.EventManager", method = "startEvent", event = "event_trigger" }
    }
    
    for _, hook_info in ipairs(cutscene_hooks) do
        local type_def = sdk.find_type_definition(hook_info.type)
        if type_def then
            local method = type_def:get_method(hook_info.method)
            if method then
                local success = pcall(function()
                    sdk.hook(method,
                        function(args)
                            event_bus.emit(hook_info.event, {
                                type = hook_info.type,
                                method = hook_info.method
                            })
                            return nil
                        end,
                        function(retval) return retval end
                    )
                end)
                
                if success then
                    logger.debug("[CinematicDetector] Hooked: " .. hook_info.type .. "." .. hook_info.method)
                end
            end
        end
    end
    
    -- 씬 전환 후킹
    local scene_hooks = {
        { type = "app.SceneManager", method = "changeScene" },
        { type = "app.SceneManager", method = "loadScene" },
        { type = "app.GameManager", method = "changeArea" },
        { type = "app.GameManager", method = "changeChapter" }
    }
    
    for _, hook_info in ipairs(scene_hooks) do
        local type_def = sdk.find_type_definition(hook_info.type)
        if type_def then
            local method = type_def:get_method(hook_info.method)
            if method then
                local success = pcall(function()
                    sdk.hook(method,
                        function(args)
                            event_bus.emit("scene_transition", {
                                type = hook_info.type,
                                method = hook_info.method
                            })
                            return nil
                        end,
                        function(retval) return retval end
                    )
                end)
            end
        end
    end
end

-- ============================================
-- Helper Functions
-- ============================================
function CinematicDetector.get_current_scene()
    local scene_manager = sdk.get_native_singleton("via.SceneManager")
    if not scene_manager then return nil end
    
    local scene_manager_type = sdk.find_type_definition("via.SceneManager")
    if not scene_manager_type then return nil end
    
    local scene = sdk.call_native_func(scene_manager, scene_manager_type, "get_CurrentScene")
    return scene
end

function CinematicDetector.safe_call(obj, method_name)
    if not obj then return nil end
    
    local success, result = pcall(function()
        return obj:call(method_name)
    end)
    
    if success then return result end
    return nil
end

function CinematicDetector.safe_get_field(obj, field_name)
    if not obj then return nil end
    
    local success, result = pcall(function()
        return obj:get_field(field_name)
    end)
    
    if success then return result end
    return nil
end

-- ============================================
-- Public API
-- ============================================
function CinematicDetector.get_state()
    return state
end

function CinematicDetector.is_in_cutscene()
    return state.is_in_cutscene
end

function CinematicDetector.is_loading()
    return state.is_loading
end

function CinematicDetector.get_current_chapter()
    return state.current_chapter
end

function CinematicDetector.is_player_controllable()
    return state.is_player_controllable
end

return CinematicDetector
