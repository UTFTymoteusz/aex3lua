--@EXT sys
-- func.sys: Provides extra syscalls
local aex_int = sys.get_internal_table()

function sys.set_hostname(name)
    aex_int.assertType(name, 'string')

    local f = sys.fs_open('/cfg/hostname', 'w')
    f:write(name)
    f:flush()
    f:close()

    aex_int.hostname = name

    return true
end
function sys.get_hostname()
    return aex_int.hostname
end