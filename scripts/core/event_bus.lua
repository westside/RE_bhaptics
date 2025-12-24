-- RE_bHaptics Event Bus
-- Simple pub/sub system for inter-module communication

local EventBus = {}
EventBus._listeners = {}
EventBus._event_history = {}
EventBus._history_size = 50

-- 이벤트 리스너 등록
function EventBus.on(event_name, callback, priority)
    priority = priority or 10
    
    if not EventBus._listeners[event_name] then
        EventBus._listeners[event_name] = {}
    end
    
    table.insert(EventBus._listeners[event_name], {
        callback = callback,
        priority = priority
    })
    
    -- 우선순위로 정렬
    table.sort(EventBus._listeners[event_name], function(a, b)
        return a.priority < b.priority
    end)
end

-- 일회성 이벤트 리스너
function EventBus.once(event_name, callback)
    local wrapper
    wrapper = function(data)
        EventBus.off(event_name, wrapper)
        callback(data)
    end
    EventBus.on(event_name, wrapper)
end

-- 이벤트 발생
function EventBus.emit(event_name, data)
    data = data or {}
    data._event_name = event_name
    data._timestamp = os.clock()
    
    -- 히스토리 저장
    table.insert(EventBus._event_history, {
        name = event_name,
        data = data,
        time = data._timestamp
    })
    
    -- 히스토리 크기 제한
    while #EventBus._event_history > EventBus._history_size do
        table.remove(EventBus._event_history, 1)
    end
    
    -- 리스너 호출
    local listeners = EventBus._listeners[event_name]
    if listeners then
        for _, listener in ipairs(listeners) do
            local success, err = pcall(listener.callback, data)
            if not success then
                log.error("[EventBus] Error in listener for '" .. event_name .. "': " .. tostring(err))
            end
        end
    end
    
    -- 와일드카드 리스너 호출 (모든 이벤트 수신)
    local all_listeners = EventBus._listeners["*"]
    if all_listeners then
        for _, listener in ipairs(all_listeners) do
            local success, err = pcall(listener.callback, data)
            if not success then
                log.error("[EventBus] Error in wildcard listener: " .. tostring(err))
            end
        end
    end
end

-- 이벤트 리스너 제거
function EventBus.off(event_name, callback)
    local listeners = EventBus._listeners[event_name]
    if listeners then
        for i = #listeners, 1, -1 do
            if listeners[i].callback == callback then
                table.remove(listeners, i)
            end
        end
    end
end

-- 모든 리스너 제거
function EventBus.clear(event_name)
    if event_name then
        EventBus._listeners[event_name] = nil
    else
        EventBus._listeners = {}
    end
end

-- 이벤트 히스토리 조회
function EventBus.get_history(event_name, count)
    count = count or 10
    local result = {}
    
    for i = #EventBus._event_history, 1, -1 do
        local entry = EventBus._event_history[i]
        if not event_name or entry.name == event_name then
            table.insert(result, entry)
            if #result >= count then
                break
            end
        end
    end
    
    return result
end

-- 등록된 이벤트 목록
function EventBus.get_registered_events()
    local events = {}
    for name, _ in pairs(EventBus._listeners) do
        table.insert(events, name)
    end
    return events
end

return EventBus
