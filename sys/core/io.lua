--@EXT sys
local aex_int = sys.get_internal_table()

io = {}
stdin  = {}
stdout = {}
stderr = {}

local processes = aex_int.processes
local g_pid = sys.get_running_pid

local function getstdin()
    return processes[g_pid()].stdin
end
local function getstdout()
    return processes[g_pid()].stdout
end
local function getstderr()
    return processes[g_pid()].stderr
end

function io.getGenericStream()
    local buffer = ''
    local bound = nil
    do
        local stream = {}

        function stream.write(self, data)
            if bound then
                if not bound.write then return nil end
                return bound:write(tostring(data))
            end
            buffer = buffer .. tostring(data)
            return true
        end
        function stream.read(self, len)
            if bound then
                if not bound.read then return nil end
                return bound:read(len)
            end
            local data = ''
            while #buffer == 0 do waitOne() end

            if not len then data, buffer = buffer, '' return data
            else
                while #buffer < len do waitOne() end
                data, buffer = string.sub(buffer, 1, len), string.sub(buffer, len + 1)
            end
            return data
        end
        function stream.bind(self, bnd)
            if not bnd then error('stdstr: No binding stream specified', 2) end
            if type(bnd) ~= 'table' then error('stdstr: Invalid stream argument specified (are you sure you are calling with : and not .?)', 2) end
            if not bnd.write and not bnd.read then error('stdstr: Stream is not readable nor writeable, is it a block device file? (Must be stream device, at least)', 2) end

            setmetatable(stream, {
                __index = function(self, key)
                    return bound[key]
                end,
                __newindex = function() end,
            })

            stream.bound = true
            bound = bnd
        end
        function stream.unbind(self)
            bound = nil
            stream.bound = nil

            setmetatable(stream, {})
        end
        return stream
    end
end
function stdin:read(len)
    return getstdin():read(len)
end
function stdout:write(...)
    local stdout = getstdout()
    for _, v in pairs({...}) do
        stdout:write(v)
    end
end
function stdout:writeln(...)
    stdout:write(...)
    stdout:write('\r\n')
end
function stderr:write(...)
    local stderr = getstderr()
    for _, v in pairs({...}) do
        stderr:write(v)
    end
end
function stderr:writeln(...)
    stderr:write(...)
    stderr:write('\r\n')
end
function io.read(len)
    return stdin:read(len)
end
function io.readln(echo)
    local buffer, c, b = ''
    while true do
        c = io.read(1)
        b = string.byte(c)
        if ((b < 32) and (b ~= 13 and b ~= 8)) or b > 127 then goto xcont end
        if c == '\b' then
            if echo and #buffer > 0 then io.write(c) end

            buffer = string.sub(buffer, 1, #buffer - 1)
            goto xcont
        end
        if echo then io.write(c) end
        if c == '\r' or c == '\n' then break end

        buffer = buffer .. c
        ::xcont::
    end
    return buffer
end
function io.write(...)
    stdout:write(...)
end
function io.writeln(...)
    stdout:write(...)
    stdout:write('\r\n')
end
function io.isATTY(file_object)
    return file_object.type == 'tty'
end

setmetatable(io, {
    __index = function(io, key)
        if key == 'stdin' then
            return getstdin()
        elseif key == 'stdout' then
            return getstdout()
        elseif key == 'stderr' then
            return getstderr()
        else
            return io[key]
        end
    end,
})

--function print()
--
--end
--function printTable()
--
--end