--@EXT lib
local aex_int = sys.get_internal_table()
local hal = {}
aex_int.hal = hal

local boot_kind = aex_int.boot.kind

if boot_kind == 'net_rh_emu' then
    hal.hdd = {
        file_read = function(id, path)
            return rh:FileRead(id, path)
        end,
        file_exists = function(id, path)
            return rh:FileExists(id, path)
        end,
        file_write = function(id, path, data)
            return rh:FileWrite(id, path, data)
        end,
        file_list = function(id, path)
            local list = rh:FileList(id, path)
            local ret = {}

            for k, v in pairs(string.split(list, '\n')) do
                v = string.split(v, '\r')
                if not v[1] or not v[2] then goto xcont end

                ret[#ret + 1] = {
                    name = v[1],
                    type = v[2],
                }
                ::xcont::
            end
            return ret
        end,
        file_delete = function(id, path)
            return rh:FileDelete(id, path)
        end,
        dir_create = function(id, path)
            return rh:DirectoryCreate(id, path)
        end,
        get_all_ids = function()
            return {0}
        end,
    }
    hal.core = {
        reset = function()
            rh:Reset()
        end,
        beep = function(freq, len)
            rh:Beep(freq, len)
        end,
        time = function()
            return os.clock()
        end,
    }
elseif boot_kind == 'gmod_rh_sf' then
    local drives = {}

    for k, v in pairs(chipset.Components.SATA) do
        if v then
            drives[k] = v
        end
    end
    local drive
    hal.hdd = {
        fd_open = function(id, path, mode)
            drive = drives[id]
            local fd, rr, rr2 = unpack((hook.runRemote(drive[1], 'hddaccess', drive[2], 11, path, mode)[1] or {})[1])

            if not fd then
                if rr == 2312 then return fd, -0xFD01 end
                if rr == 6623 then return fd, -0xFD02 end
                return fd, rr, rr2
            end
            return fd, rr, rr2
        end,
        fd_read = function(id, fd, len)
            drive = drives[id]
            return (hook.runRemote(drive[1], 'hddaccess', drive[2], 12, fd, len)[1] or {})[1]
        end,
        fd_write = function(id, fd, str)
            drive = drives[id]
            return (hook.runRemote(drive[1], 'hddaccess', drive[2], 13, fd, str)[1] or {})[1]
        end,
        fd_seek = function(id, fd, op, offset)
            drive = drives[id]
            return (hook.runRemote(drive[1], 'hddaccess', drive[2], 14, fd, op, offset)[1] or {})[1]
        end,
        fd_flush = function(id, fd)
            drive = drives[id]
            return (hook.runRemote(drive[1], 'hddaccess', drive[2], 15, fd)[1] or {})[1]
        end,
        fd_close = function(id, fd)
            drive = drives[id]
            return (hook.runRemote(drive[1], 'hddaccess', drive[2], 16, fd)[1] or {})[1]
        end,

        --file_read = function(id, path)
        --    drive = drives[id]
        --    return (hook.runRemote(drive[1], 'hddaccess', drive[2], 0, path)[1] or {})[1]
        --end,
        file_exists = function(id, path)
            drive = drives[id]
            return (hook.runRemote(drive[1], 'hddaccess', drive[2], 2, path)[1] or {})[1]
        end,
        --file_write = function(id, path, data)
        --    drive = drives[id]
        --    return (hook.runRemote(drive[1], 'hddaccess', drive[2], 1, path, data)[1] or {})[1]
        --end,
        file_list = function(id, path)
            drive = drives[id]
            local a = (hook.runRemote(drive[1], 'hddaccess', drive[2], 3, path)[1] or {})[1]
            if type(a) ~= 'table' then return nil end

            local ent = {}
            for k, v in pairs(a) do
                ent[#ent + 1] = {
                    name = k,
                    type = v[1],
                }
            end
            return ent
        end,
        file_delete = function(id, path)
            drive = drives[id]
            return (hook.runRemote(drive[1], 'hddaccess', drive[2], 4, path)[1] or {})[1]
        end,
        dir_create = function(id, path)
            drive = drives[id]
            return (hook.runRemote(drive[1], 'hddaccess', drive[2], 5, path)[1] or {})[1]
        end,
        file_size = function(id, path)
            drive = drives[id]
            return (hook.runRemote(drive[1], 'hddaccess', drive[2], 6, path)[1] or {})[1]
        end,
        file_type = function(id, path)
            drive = drives[id]
            return (hook.runRemote(drive[1], 'hddaccess', drive[2], 7, path)[1] or {})[1]
        end,
        get_all_ids = function()
            local keybois = table.getKeys(drives)
            local ret = {}

            for k, v in pairs(keybois) do

                if #drives[v] > 0 then
                    ret[#ret + 1] = v
                end
            end
            return ret
        end,
    }
    local start = timer.systime()
    hal.core = {
        reset = function()
            cpu.reset()
        end,
        beep = function(freq, len)
            rh:Beep(freq, len)
        end,
        time = function()
            return timer.systime() - start
        end,
    }
    if chipset.Components.IO and #chipset.Components.IO > 0 then
        local io = chipset.Components.IO
        local buffers = {}

        hal.serial = {
            clear = function(id)
                return (hook.runRemote(io[1], io[2], 114, id)[1] or {})[1]
            end,
            write = function(id, str)
                return (hook.runRemote(io[1], io[2], 111, id, str)[1] or {})[1]
            end,
            read = function(id, len)
                local a
                if not len then
                    a = buffers[id]
                    buffers[id] = ''
                    
                    return a
                else
                    b = buffers[id]
                    a = string.sub(b, 1, len)
                    buffers[id] = string.sub(b, len + 1)
                    return a
                end
            end,
            get_all_ids = function() 
                local fan = {} 
                for i = 0, (hook.runRemote(io[1], io[2], 113)[1] or {})[1] - 1 do
                    fan[#fan + 1] = i
                end
                return fan
            end,
        }
        for _, v in pairs(hal.serial.get_all_ids()) do
            buffers[v] = ''
        end
        cpu.handleInterrupt('serial', function(port, data) 
            buffers[port] = buffers[port] .. data
        end)
    else
        hal.serial = {
            close = function() end,
            write = function() end,
            read  = function() end,
            get_all_ids = function() return {} end,
        }
    end
end