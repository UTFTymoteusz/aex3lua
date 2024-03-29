--@EXT drv
info = {
    full_name = 'GMod Wiremod Keyboard Driver',
    name = 'gwirekb',
    type = 'input',
    provider = 'Tymkboi',
    version  = '1.0',
}

local thread

function load()

end
function unload()

end
function enable()
    local kb
    if chipset.Components.KB then kb = wire.getWirelink(chipset.Components.KB) end

    local kb_t = sys.input_add_device('rhkbd')

    local ckeys, bkeys, act = {}, {}
    thread = sys.thread_create(function()
        while true do
            waitOne()

            if not kb then sleep(1000)
                if chipset.Components.KB then kb = wire.getWirelink(chipset.Components.KB) end
                goto xcont
            end

            act = kb.ActiveKeys
            if not act then sleep(1000) goto xcont end

            ckeys = {}

            for _, v in pairs(act) do
                ckeys[v] = true
            end
            for k, _ in pairs(ckeys) do
                if not bkeys[k] then kb_t:keyPress(k) end
            end
            for k, _ in pairs(bkeys) do
                if not ckeys[k] then kb_t:keyRelease(k) end
            end
            bkeys = table.copy(ckeys)
            ::xcont::
        end
    end)
    return true
end
function disable()
    thread:abort()
    return true
end