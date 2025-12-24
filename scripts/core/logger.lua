-- RE_bHaptics Logger Utility
-- Provides logging with different levels

local Logger = {}

Logger.LEVEL = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4
}

Logger.level_names = {
    [1] = "DEBUG",
    [2] = "INFO",
    [3] = "WARN",
    [4] = "ERROR"
}

Logger.current_level = Logger.LEVEL.DEBUG
Logger.prefix = "[RE_bHaptics]"
Logger.show_timestamp = true

local function get_timestamp()
    if Logger.show_timestamp then
        return os.date("[%H:%M:%S] ")
    end
    return ""
end

function Logger.set_level(level)
    Logger.current_level = level
end

function Logger.debug(msg)
    if Logger.current_level <= Logger.LEVEL.DEBUG then
        log.info(get_timestamp() .. Logger.prefix .. " [DEBUG] " .. tostring(msg))
    end
end

function Logger.info(msg)
    if Logger.current_level <= Logger.LEVEL.INFO then
        log.info(get_timestamp() .. Logger.prefix .. " [INFO] " .. tostring(msg))
    end
end

function Logger.warn(msg)
    if Logger.current_level <= Logger.LEVEL.WARN then
        log.warn(get_timestamp() .. Logger.prefix .. " [WARN] " .. tostring(msg))
    end
end

function Logger.error(msg)
    if Logger.current_level <= Logger.LEVEL.ERROR then
        log.error(get_timestamp() .. Logger.prefix .. " [ERROR] " .. tostring(msg))
    end
end

-- 테이블 출력 헬퍼
function Logger.dump(tbl, indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)
    
    if type(tbl) ~= "table" then
        Logger.debug(prefix .. tostring(tbl))
        return
    end
    
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            Logger.debug(prefix .. tostring(k) .. " = {")
            Logger.dump(v, indent + 1)
            Logger.debug(prefix .. "}")
        else
            Logger.debug(prefix .. tostring(k) .. " = " .. tostring(v))
        end
    end
end

return Logger
