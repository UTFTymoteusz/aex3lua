--@EXT drv
local aex_int = sys.get_internal_table()
local hal  = aex_int.hal
local boot = aex_int.boot

local file_read   = hal.hdd.file_read
local file_exists = hal.hdd.file_exists
local file_write  = hal.hdd.file_write
local file_list   = hal.hdd.file_list
local file_delete = hal.hdd.file_delete
local dir_create  = hal.hdd.dir_create

local devid = 0

local driver = {}

local function enable()

    for _, id in pairs(hal.hdd.get_all_ids()) do

        if id == boot.drive_id then
            boot.drive_name = '/dev/hdd' .. devid
        end
        sys.add_device('hdd' .. devid, function()
            return {
                fileRead   = function(self, path)       return file_read(id,   path) end,
                fileExists = function(self, path)       return file_exists(id, path) end,
                fileWrite  = function(self, path, data) return file_write(id,  path, data) end,
                fileList   = function(self, path)       return file_list(id,   path) end,
                fileDelete = function(self, path)       return file_delete(id, path) end,
                dirCreate  = function(self, path)       return dir_create(id,  path) end,
            }
        end)
        sys.mark_device('hdd' .. devid, 'hdd')
        sys.drvmgr_claim('hdd' .. devid, driver)
    
        devid = devid + 1
        ::xcontinue::
    end
end

driver.full_name = 'HDD Hub Driver'
driver.name = 'hddh'
driver.type = 'hub'
driver.provider = 'Tymkboi'
driver.version  = '1.0'
driver.disallow_disable = true

function driver.load()

end
function driver.unload()

end
function driver.enable()
    enable()
    return true
end
function driver.disable()
    return false
end

return driver