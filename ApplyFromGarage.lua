-- Apply From Garage

local SCRIPT_VERSION = "0.1"

---
--- Dependencies
---

util.require_natives("3095a")
util.ensure_package_is_installed("lua/Constructor")

local constructor_lib = require("constructor/constructor_lib")
local convertors = require("constructor/convertors")

---
--- Vars
---

local config = {
    apply_mods=true,
    apply_paint=true,
    apply_wheels=true,
}

local GARAGE_PATH = filesystem.stand_dir().."Vehicles/"

local menus = {}
menus.appearance = menu.ref_by_path("Vehicle>Los Santos Customs>Appearance")
menus.garage_items = {}

---
--- Functions
---

local create_construct_from_vehicle = function(vehicle_handle)
    local construct = constructor_lib.copy_construct_plan(constructor_lib.construct_base)
    construct.type = "VEHICLE"
    construct.handle = vehicle_handle
    constructor_lib.default_entity_attributes(construct)
    constructor_lib.serialize_vehicle_attributes(construct)
    return construct
end

local function apply_from_file(filepath)
    local handle = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), true)
    if not handle then
        error("You must be in a vehicle to apply to")
    end
    --util.toast("Applying from file "..filepath)
    local _, filename, ext = string.match(filepath, "(.-)([^\\/]-%.?)[.]([^%.\\/]*)$")
    local construct_plan = convertors.convert_txt_to_construct_plan({
        is_directory=false,
        filepath=filepath,
        filename=filename,
        ext=ext,
    })
    local construct = create_construct_from_vehicle(handle)
    if config.apply_mods then
        construct.vehicle_attributes.mods = construct_plan.vehicle_attributes.mods
    end
    if config.apply_paint then
        construct.vehicle_attributes.paint = construct_plan.vehicle_attributes.paint
    end
    if config.apply_wheels then
        construct.vehicle_attributes.wheels = construct_plan.vehicle_attributes.wheels
    end
    constructor_lib.deserialize_vehicle_attributes(construct)
end


local function delete_menu_list(menu_list)
    if type(menu_list) ~= "table" then return end
    for k, h in pairs(menu_list) do
        if h:isValid() then
            menu.delete(h)
        end
        menu_list[k] = nil
    end
end

local function build_garage_items(directory, path)
    local items = {}
    if path == nil then path = "" end
    for _, filepath in ipairs(filesystem.list_files(directory)) do
        if filesystem.is_dir(filepath) then
            local _2, dirname = string.match(filepath, "(.-)([^\\/]-%.?)$")
            local child_items = build_garage_items(filepath, path.."/"..dirname)
            table.insert(items, {name=dirname, items=child_items})
        else
            local _3, filename, ext = string.match(filepath, "(.-)([^\\/]-%.?)[.]([^%.\\/]*)$")
            if ext == "txt" then
                table.insert(items, {name=filename, filepath=filepath})
            end
        end
    end
    return items
end

local function add_garage_menu_items(root_menu, garage_items)
    for _, garage_item in garage_items do
        if garage_item.items ~= nil then
            garage_item.menu = root_menu:list(garage_item.name, {}, "")
            add_garage_menu_items(garage_item.menu, garage_item.items)
            table.insert(menus.garage_items, garage_item.menu)
        end
    end
    for _, garage_item in garage_items do
        if garage_item.items == nil then
            garage_item.menu = root_menu:action(garage_item.name, {}, "Apply from "..garage_item.name, function()
                apply_from_file(garage_item.filepath)
            end)
            table.insert(menus.garage_items, garage_item.menu)
        end
    end
end

---
--- Menus
---

menus.apply_from_garage = menus.appearance:attachAfter(menu.shadow_root():list("Apply From Garage", {"applyfromgarage"}, "Copy paint, wheels, etc from another vehicle in your garage", function()
    delete_menu_list(menus.garage_items)
    local garage_items = build_garage_items(GARAGE_PATH)
    add_garage_menu_items(menus.apply_from_garage, garage_items)
end))
menu.my_root():link(menus.apply_from_garage)

menus.options = menus.apply_from_garage:list("Apply Options", {}, "Configure which options to copy from selected vehicle to current vehicle")
menus.options:toggle("Apply Paint", {}, "Apply garage vehicle paint to current vehicle", function(value)
    config.apply_paint = value
end, config.apply_paint)
menus.options:toggle("Apply Mods", {}, "Apply garage vehicle paint to current vehicle", function(value)
    config.apply_mods = value
end, config.apply_mods)
menus.options:toggle("Apply Wheels", {}, "Apply garage vehicle paint to current vehicle", function(value)
    config.apply_wheels = value
end, config.apply_wheels)
menus.apply_from_garage:divider("Browse Garage")

menus.about = menu.my_root():list("About", {}, "Information about this script")
menus.about:readonly("Version", SCRIPT_VERSION)
menus.about:hyperlink("Github Source", "https://github.com/hexarobi/stand-lua-applyfromgarage", "View source files on Github")
menus.about:hyperlink("Discord", "https://discord.gg/RF4N7cKz", "Open Discord Server")
