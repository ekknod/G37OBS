-- ekknod@2019 --
local obs                      = obslua
local bit                      = require("bit")
local ffi                      = require("ffi")
local ntdll                    = ffi.load("ntdll.dll")
local u32                      = ffi.load("user32.dll")
local k32                      = ffi.load("kernel32.dll")

local g_encryption_key         = 0x5F21360
local g_handle                 = 0
local g_wow64                  = 0
local g_peb                    = 0
local g_target                 = 0
local g_target_bone            = 0
local g_previous_tick          = 0
local g_old_punch              = {0.00, 0.00, 0.00}
local g_bones                  = {5, 4, 3, 0, 7, 8}
local g_mouse1_down            = false

local vt_client                = 0
local vt_entity                = 0
local vt_engine                = 0
local vt_cvar                  = 0
local vt_input                 = 0

local sensitivity              = 0
local mp_teammates_are_enemies = 0

local m_iHealth                = 0
local m_vecViewOffset          = 0
local m_lifeState              = 0
local m_nTickBase              = 0
local m_vecPunch               = 0
local m_vecVelocity            = 0
local m_fFlags                 = 0
local m_iTeamNum               = 0
local m_bSpotted               = 0
local m_vecOrigin              = 0
local m_iShotsFired            = 0
local m_iCrossHairID           = 0
local m_iGlowIndex             = 0
local m_dwBoneMatrix           = 0
local m_dwGlowObjectManager    = 0
local m_dwForceJump            = 0
local m_dwEntityList           = 0
local m_dwClientState          = 0
local m_dwGetLocalPlayer       = 0
local m_dwViewAngles           = 0
local m_dwMaxClients           = 0
local m_dwState                = 0
local m_dwButton               = 0

local cl_bhop                  = false
local cl_radar                 = true
local cl_glow                  = true
local cl_glow_hold             = false
local cl_rcs                   = false
local cl_triggerbot            = true
local cl_aimbot                = true
local cl_aimbot_head           = false
local cl_aimbot_legit          = false
local cl_aimbot_rcs            = true
local cl_aimbot_smooth         = 4.5
local cl_aimbot_fov            = 1.0 / 180.0
local cl_aimbot_key            = 107
local cl_triggerbot_key        = 111
local cl_glow_key              = 111
local cl_bhop_key              = 65


local g_key_list = {
    {"KEY_0", 1},
    {"KEY_1", 2},
    {"KEY_2", 3},
    {"KEY_3", 4},
    {"KEY_4", 5},
    {"KEY_5", 6},
    {"KEY_6", 7},
    {"KEY_7", 8},
    {"KEY_8", 9},
    {"KEY_9", 10},
    {"KEY_A", 11},
    {"KEY_B", 12},
    {"KEY_C", 13},
    {"KEY_D", 14},
    {"KEY_E", 15},
    {"KEY_F", 16},
    {"KEY_G", 17},
    {"KEY_H", 18},
    {"KEY_I", 19},
    {"KEY_J", 20},
    {"KEY_K", 21},
    {"KEY_L", 22},
    {"KEY_M", 23},
    {"KEY_N", 24},
    {"KEY_O", 25},
    {"KEY_P", 26},
    {"KEY_Q", 27},
    {"KEY_R", 28},
    {"KEY_S", 29},
    {"KEY_T", 30},
    {"KEY_U", 31},
    {"KEY_V", 32},
    {"KEY_W", 33},
    {"KEY_X", 34},
    {"KEY_Y", 35},
    {"KEY_Z", 36},
    {"KEY_PAD_0", 37},
    {"KEY_PAD_1", 38},
    {"KEY_PAD_2", 39},
    {"KEY_PAD_3", 40},
    {"KEY_PAD_4", 41},
    {"KEY_PAD_5", 42},
    {"KEY_PAD_6", 43},
    {"KEY_PAD_7", 44},
    {"KEY_PAD_8", 45},
    {"KEY_PAD_9", 46},
    {"KEY_PAD_DIVIDE", 47},
    {"KEY_PAD_MULTIPLY", 48},
    {"KEY_PAD_MINUS", 49},
    {"KEY_PAD_PLUS", 50},
    {"KEY_PAD_ENTER", 51},
    {"KEY_PAD_DECIMAL", 52},
    {"KEY_LBRACKET", 53},
    {"KEY_RBRACKET", 54},
    {"KEY_SEMICOLON", 55},
    {"KEY_APOSTROPHE", 56},
    {"KEY_BACKQUOTE", 57},
    {"KEY_COMMA", 58},
    {"KEY_PERIOD", 59},
    {"KEY_SLASH", 60},
    {"KEY_BACKSLASH", 61},
    {"KEY_MINUS", 62},
    {"KEY_EQUAL", 63},
    {"KEY_ENTER", 64},
    {"KEY_SPACE", 65},
    {"KEY_BACKSPACE", 66},
    {"KEY_TAB", 67},
    {"KEY_CAPSLOCK", 68},
    {"KEY_NUMLOCK", 69},
    {"KEY_ESCAPE", 70},
    {"KEY_SCROLLLOCK", 71},
    {"KEY_INSERT", 72},
    {"KEY_DELETE", 73},
    {"KEY_HOME", 74},
    {"KEY_END", 75},
    {"KEY_PAGEUP", 76},
    {"KEY_PAGEDOWN", 77},
    {"KEY_BREAK", 78},
    {"KEY_LSHIFT", 79},
    {"KEY_RSHIFT", 80},
    {"KEY_LALT", 81},
    {"KEY_RALT", 82},
    {"KEY_LCONTROL", 83},
    {"KEY_RCONTROL", 84},
    {"KEY_LWIN", 85},
    {"KEY_RWIN", 86},
    {"KEY_APP", 87},
    {"KEY_UP", 88},
    {"KEY_LEFT", 89},
    {"KEY_DOWN", 90},
    {"KEY_RIGHT", 91},
    {"KEY_F1", 92},
    {"KEY_F2", 93},
    {"KEY_F3", 94},
    {"KEY_F4", 95},
    {"KEY_F5", 96},
    {"KEY_F6", 97},
    {"KEY_F7", 98},
    {"KEY_F8", 99},
    {"KEY_F9", 100},
    {"KEY_F10", 101},
    {"KEY_F11", 102},
    {"KEY_F12", 103},
    {"KEY_CAPSLOCKTOGGLE", 104},
    {"KEY_NUMLOCKTOGGLE", 105},
    {"KEY_SCROLLLOCKTOGGLE", 106},
    {"MOUSE_LEFT", 107},
    {"MOUSE_RIGHT", 108},
    {"MOUSE_MIDDLE", 109},
    {"MOUSE_4", 110},
    {"MOUSE_5", 111},
    {"MOUSE_WHEEL_UP", 112},
    {"MOUSE_WHEEL_DOWN", 113}
}


-- C imports --
ffi.cdef[[
int Beep(uint32_t, uint32_t);
void mouse_event(uint32_t, uint32_t, uint32_t, uint32_t, uint64_t);
uint64_t GetModuleHandleA(const char*);
int WriteProcessMemory(uint64_t, uint64_t, void *, uint64_t, uint64_t);
int K32GetModuleBaseNameA(uint64_t, uint64_t, char *, uint32_t);
int GetExitCodeProcess(uint64_t, uint32_t*);
long NtQueryInformationProcess(uint64_t, uint32_t, void *, uint32_t, uint32_t*);
long NtWriteVirtualMemory(uint64_t, uint64_t, void *, uint64_t, uint64_t);
long NtReadVirtualMemory(uint64_t, uint64_t, void *, uint64_t, uint64_t);
uint32_t RtlComputeCrc32(uint32_t, const void *, int);
size_t strlen (const char*);
size_t wcslen (const char*);
int _stricmp (const char *, const char *);
uint64_t FindWindowA(const char *, uint64_t);
]]


function script_description()
    return "<b>https://ekknod.xyz - G37OBS</b><hr>ekknod@2019"
end


function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_bool(props, "cl_bhop", "Bhop")
    obs.obs_properties_add_bool(props, "cl_radar", "Radar")
    obs.obs_properties_add_bool(props, "cl_glow", "Glow ESP")
    obs.obs_properties_add_bool(props, "cl_glow_hold", "Glow ESP [Hold Mode]")
    obs.obs_properties_add_bool(props, "cl_rcs", "Recoil Control System")
    obs.obs_properties_add_bool(props, "cl_triggerbot", "Triggerbot")
    obs.obs_properties_add_bool(props, "cl_aimbot", "Aimbot")
    obs.obs_properties_add_bool(props, "cl_aimbot_head", "Aimbot Head Only")
    obs.obs_properties_add_bool(props, "cl_aimbot_legit", "Aimbot Legit")
    obs.obs_properties_add_bool(props, "cl_aimbot_rcs", "Aimbot No Recoil")
    obs.obs_properties_add_float_slider(props, "cl_aimbot_smooth", "Aimbot Smooth", 0.0, 50.0, 0.25)
    obs.obs_properties_add_float_slider(props, "cl_aimbot_fov", "Aimbot Fov", 0.0, 180.0, 0.25)
    local aimbot_keys = obs.obs_properties_add_list(props,  "cl_aimbot_key",
        "Aimbot", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    local trigger_keys = obs.obs_properties_add_list(props,  "cl_triggerbot_key",
        "Triggerbot", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    local glow_key = obs.obs_properties_add_list(props,  "cl_glow_key",
        "Glow ESP", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    local bhop_keys = obs.obs_properties_add_list(props,  "cl_bhop_key",
        "Bhop", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    for i = 1, #g_key_list do
        obs.obs_property_list_add_string(aimbot_keys, g_key_list[i][1], g_key_list[i][1])
        obs.obs_property_list_add_string(trigger_keys, g_key_list[i][1], g_key_list[i][1])
        obs.obs_property_list_add_string(glow_key, g_key_list[i][1], g_key_list[i][1])
        obs.obs_property_list_add_string(bhop_keys, g_key_list[i][1], g_key_list[i][1])
    end
    return props
end


function script_load()
    -- 0x1fffff = PROCESS_ALL_ACCESS
    -- 0x000410 = PROCESS_QUERY_INFORMATION | PROCESS_VM_READ
    -- 0x000430 = PROCESS_QUERY_INFORMATION | PROCESS_VM_READ | PROCESS_VM_WRITE
    -- if cl_glow then
    --     patch_flags(0x000430)
    -- else
    --     patch_flags(0x000410)
    -- end
    patch_flags(0x000430)
end


function script_defaults(settings)
    obs.obs_data_set_default_bool(settings, "cl_bhop", cl_bhop)
    obs.obs_data_set_default_bool(settings, "cl_radar", cl_radar)
    obs.obs_data_set_default_bool(settings, "cl_glow", cl_glow)
    obs.obs_data_set_default_bool(settings, "cl_glow_hold", cl_glow_hold)
    obs.obs_data_set_default_bool(settings, "cl_rcs", cl_rcs)
    obs.obs_data_set_default_bool(settings, "cl_triggerbot", cl_triggerbot)
    obs.obs_data_set_default_bool(settings, "cl_aimbot", cl_aimbot)
    obs.obs_data_set_default_bool(settings, "cl_aimbot_head", cl_aimbot_head)
    obs.obs_data_set_default_bool(settings, "cl_aimbot_legit", cl_aimbot_legit)
    obs.obs_data_set_default_bool(settings, "cl_aimbot_rcs", cl_aimbot_rcs)
    obs.obs_data_set_default_double(settings, "cl_aimbot_smooth", cl_aimbot_smooth)
    obs.obs_data_set_default_double(settings, "cl_aimbot_fov", 1.0)
    obs.obs_data_set_default_string(settings,
        "cl_aimbot_key", g_key_list[cl_aimbot_key][1])
    obs.obs_data_set_default_string(settings,
        "cl_triggerbot_key", g_key_list[cl_triggerbot_key][1])
    obs.obs_data_set_default_string(settings,
        "cl_glow_key", g_key_list[cl_glow_key][1])
    obs.obs_data_set_default_string(settings,
        "cl_bhop_key", g_key_list[cl_bhop_key][1])
end


local function get_key_from_list(name)
    for i = 1, #g_key_list do
        if g_key_list[i][1] == name then
            return g_key_list[i][2]
        end
    end
    return 0
end


function script_update(settings)
    cl_bhop = obs.obs_data_get_bool(settings, "cl_bhop")
    cl_radar = obs.obs_data_get_bool(settings, "cl_radar")
    cl_glow = obs.obs_data_get_bool(settings, "cl_glow")
    cl_glow_hold = obs.obs_data_get_bool(settings, "cl_glow_hold")
    cl_rcs = obs.obs_data_get_bool(settings, "cl_rcs")
    cl_triggerbot = obs.obs_data_get_bool(settings, "cl_triggerbot")
    cl_aimbot = obs.obs_data_get_bool(settings, "cl_aimbot")
    cl_aimbot_head = obs.obs_data_get_bool(settings, "cl_aimbot_head")
    cl_aimbot_legit = obs.obs_data_get_bool(settings, "cl_aimbot_legit")
    cl_aimbot_rcs = obs.obs_data_get_bool(settings, "cl_aimbot_rcs")
    cl_aimbot_smooth = obs.obs_data_get_double(settings, "cl_aimbot_smooth")
    cl_aimbot_fov = obs.obs_data_get_double(settings, "cl_aimbot_fov") / 180.0
    cl_aimbot_key = get_key_from_list(obs.obs_data_get_string(settings, "cl_aimbot_key"))
    cl_triggerbot_key = get_key_from_list(obs.obs_data_get_string(settings, "cl_triggerbot_key"))
    cl_glow_key = get_key_from_list(obs.obs_data_get_string(settings, "cl_glow_key"))
    cl_bhop_key = get_key_from_list(obs.obs_data_get_string(settings, "cl_bhop_key"))
end


function script_tick(seconds)
    if mem_is_running() then
        if not is_in_game() then
            g_target = 0
            g_previous_tick = 0
            return
        end
        local player = get_client_entity(get_local_player())
        local view_angle = get_view_angles()
        local fl_sensitivity = get_float(sensitivity)
        if cl_triggerbot then
            if is_button_down(cl_triggerbot_key) == 1 then
                if get_valid_cross_id(player) ~= 0 then
                    u32.mouse_event(0x0002, 0, 0, 0, 0)
                    g_mouse1_down = true
                else
                    u32.mouse_event(0x0004, 0, 0, 0, 0)
                    g_mouse1_down = false
                end
            else
                if g_mouse1_down then
                    u32.mouse_event(0x0004, 0, 0, 0, 0)
                    g_mouse1_down = false
                end
            end
        end

        if cl_bhop then
            if is_button_down(cl_bhop_key) == 1 then
                if (bit.band(get_flags(player), 1) == 1) then
                    mem_write_i32(m_dwForceJump, 5)
                else
                    mem_write_i32(m_dwForceJump, 4)
                end
            end
        end

        if cl_aimbot then
            if is_button_down(cl_aimbot_key) == 1 then
                aimbot(player, view_angle, fl_sensitivity)
            else
                g_target = 0
            end
        end

        if cl_rcs then
            rcs(player, view_angle, fl_sensitivity)
        end

        if cl_glow or cl_radar then
            glow_radar(player)
        end
    else
        g_target = 0
        g_previous_tick = 0
        if u32.FindWindowA("Valve001", 0) ~= 0 then
            if not initialize() then
                g_handle = 0
            end
        end
    end
end


function glow_radar(player)
    local glow_pointer = mem_read_i32(m_dwGlowObjectManager)
    for i = 0, get_max_clients() do
        local entity = get_client_entity(i)
        if is_valid(entity) then
            if get_int(mp_teammates_are_enemies) == 0 and get_team_num(player) == get_team_num(entity) then
                goto continue
            end

            if cl_radar then
                mem_write_i8(entity + m_bSpotted, 1)
            end

            if cl_glow then
                if cl_glow_hold and is_button_down(cl_glow_key) == 0 then
                    goto continue
                end
                local entity_health = get_health(entity) / 100.0
                local index = mem_read_i32(entity + m_iGlowIndex) * 0x38
                mem_write_float(glow_pointer + index + 0x08, 1.0 - entity_health)  -- r
                mem_write_float(glow_pointer + index + 0x0C, entity_health)        -- g
                mem_write_float(glow_pointer + index + 0x10, 0.0)                  -- b
                mem_write_float(glow_pointer + index + 0x14, 0.8)                  -- a
                mem_write_i8(glow_pointer + index + 0x28, 1)
                mem_write_i8(glow_pointer + index + 0x29, 0)
            end
        end
        ::continue::
    end
end


function rcs(player, view_angle, sensitivity)
    local a0 = get_vec_punch(player)
    if get_shots_fired(player) > 1 then
        local a1 = { a0[1] - g_old_punch[1], a0[2] - g_old_punch[2], 0}
        local a2 = {view_angle[1] - a1[1] * 2.0, view_angle[2] - a1[2] * 2.0, 0}
        u32.mouse_event(0x0001, ((a2[2] - view_angle[2]) / sensitivity) / -0.022,
                        ((a2[1] - view_angle[1]) / sensitivity) / 0.022, 0, 0)
    end
    g_old_punch = a0
end


function aimbot(player, view_angle, sensitivity)
    if not is_valid(g_target) and not aimbot_get_best_target(view_angle, player) then
        return
    end
    if cl_aimbot_legit and (bit.band(get_flags(g_target), 1) == 0 or get_velocity(g_target) > 150) then
        g_target = 0
        return
    end
    aimbot_aim_at(player, g_target, sensitivity, view_angle,
        aimbot_get_target_angle(player, g_target, g_target_bone))
end


function get_valid_cross_id(player)
    local index = get_cross_index(player)
    if index == 0 then
        return 0
    end
    local entity = get_client_entity(index - 1)
    if get_team_num(player) ~= get_team_num(entity) and get_health(entity) > 0 then
        return index
    end
    return 0
end


function aimbot_get_target_angle(player, target, id)
    local m = get_bone_pos(target, id)
    local c = get_eye_pos(player)
    c[1] = m[1] - c[1]
    c[2] = m[2] - c[2]
    c[3] = m[3] - c[3]
    c = vec_angles(angle_normalize(c))
    if cl_aimbot_rcs and get_shots_fired(player) > 1 then
        local p = get_vec_punch(player)
        c[1] = c[1] - p[1] * 2.0
        c[2] = c[2] - p[2] * 2.0
        c[3] = c[3] - p[3] * 2.0
    end
    return vec_clamp(c)
end


function aimbot_get_best_target(angles, player)
    local best_fov = 9999.00
    for i = 0, get_max_clients() do
        local entity = get_client_entity(i)
        if is_valid(entity) == true then
            if get_int(mp_teammates_are_enemies) == 0 and get_team_num(player) == get_team_num(entity) then
                goto continue
            end
            if cl_aimbot_head then
                local fov = get_fov(angles, aimbot_get_target_angle(player, entity, 8))
                if fov < best_fov then
                    best_fov = fov
                    g_target = entity
                    g_target_bone = 8
                end
            else
                for j = 1, 6 do
                    local fov = get_fov(angles, aimbot_get_target_angle(player, entity, g_bones[j]))
                    if fov < best_fov then
                        best_fov = fov
                        g_target = entity
                        g_target_bone = g_bones[j]
                    end
                end
            end
        end
        ::continue::
    end
    return best_fov ~= 9999.00
end


function aimbot_aim_at(player, entity, sensitivity, angles, angle)
    if cl_aimbot_legit and not is_visible(player, entity) then
        g_target = 0
        return
    end
    local current_tick = get_tick_count(player)
    local sx = 0.00
    local sy = 0.00
    local x = angles[2] - angle[2]
    local y = angles[1] - angle[1]
    if y > 89.0 then
        y = 89.0
    elseif y < -89.0 then
        y = -89.0
    end
    if x > 180.0 then
        x = x - 360.0
    elseif x < -180.0 then
        x = x + 360.0
    end
    if (math.abs(x) / 180.0) >= cl_aimbot_fov then
        g_target = 0
        return
    end
    if (math.abs(y) / 89.0) >= cl_aimbot_fov then
        g_target = 0
        return
    end
    x = (x / sensitivity) / 0.022
    y = (y / sensitivity) / -0.022
    if cl_aimbot_smooth >= 1.00 then
        if sx < x then
            sx = sx + 1.0 + (x / cl_aimbot_smooth);
        elseif sx > x then
            sx = sx - 1.0 + (x / cl_aimbot_smooth);
        end
        if sy < y then
            sy = sy + 1.0 + (y / cl_aimbot_smooth);
        elseif sy > y then
            sy = sy - 1.0 + (y / cl_aimbot_smooth);
        end
    else
        sx = x
        sy = y
    end
    if current_tick - g_previous_tick > 0 then
        g_previous_tick = current_tick
        u32.mouse_event(0x0001, sx, sy, 0, 0)
    end
end


function initialize()
    if mem_is_running() then
        return true
    end
    if not mem_initialize("csgo.exe") then
        return false
    end
    if not vt_initialize() then
        return false
    end
    if not nv_initialize() then
        return false
    end
    sensitivity = get_convar(0x2b2b0d04)
    mp_teammates_are_enemies = get_convar(0x565d237b)
    if sensitivity == 0 or mp_teammates_are_enemies == 0 then
        return false
    end
    k32.Beep(450, 500)
    return true
end


function vt_initialize()
    local table = get_interface_factory(0x2e96d8ca)
    if table == 0 then return false end
    vt_client = get_interface(table, 0x5dc0ec1e)
    if vt_client == 0 then return false end
    vt_entity = get_interface(table, 0xc8e1780e)
    if vt_entity == 0 then return false end
    table = get_interface_factory(0x17aa8ca1)
    if table == 0 then return false end
    vt_engine = get_interface(table, 0xd6397de2)
    if vt_engine == 0 then return false end
    table = get_interface_factory(0x920441ba)
    if table == 0 then return false end
    vt_cvar = get_interface(table, 0xd61ec67e)
    if vt_cvar == 0 then return false end
    table = get_interface_factory(0x3567ab03)
    if table == 0 then return false end
    vt_input = get_interface(table, 0xae6180a3)
    if vt_input == 0 then return false end
    return true
end


function nv_initialize()
    local table = get_netvar_table(0xe341b2e)
    if table == 0 then return false end
    m_iHealth = get_netvar_offset(table, 0xaa30647)
    if m_iHealth == 0 then return false end
    m_vecViewOffset = get_netvar_offset(table, 0x314343b0)
    if m_vecViewOffset == 0 then return false end
    m_lifeState = get_netvar_offset(table, 0xddb7bf63)
    if m_lifeState == 0 then return false end
    m_nTickBase = get_netvar_offset(table, 0x7fcbb12e)
    if m_nTickBase == 0 then return false end
    m_vecPunch = get_netvar_offset(table, 0x2700150d) + 0x70
    if m_vecPunch == 0 then return false end
    m_vecVelocity = get_netvar_offset(table, 0x9f99cc)
    if m_vecVelocity == 0 then return false end
    m_fFlags = get_netvar_offset(table, 0x6dedf30c)
    if m_fFlags == 0 then return false end
    table = get_netvar_table(0x701356ad)
    if table == 0 then return false end
    m_iTeamNum = get_netvar_offset(table, 0x77ffa860)
    if m_iTeamNum == 0 then return false end
    m_bSpotted = get_netvar_offset(table, 0xcf0118b2)
    if m_bSpotted == 0 then return false end
    m_vecOrigin = get_netvar_offset(table, 0xaec30674)
    if m_vecOrigin == 0 then return false end
    table = get_netvar_table(0x885a08f)
    if table == 0 then return false end
    m_iShotsFired = get_netvar_offset(table, 0xbbd87ca6)
    if m_iShotsFired == 0 then return false end
    m_iCrossHairID = get_netvar_offset(table, 0x76275606) + 0x5C
    if m_iCrossHairID == 0 then return false end
    m_iGlowIndex = get_netvar_offset(table, 0x1064ab21) + 0x18
    if m_iGlowIndex == 0 then return false end
    table = get_netvar_table(0xd9f4f894)
    if table == 0 then return false end
    m_dwBoneMatrix = get_netvar_offset(table, 0x4fcc8600) + 0x1C
    if m_dwBoneMatrix == 0 then return false end
    m_dwGlowObjectManager = mem_scan_pattern(0x2e96d8ca, "\xA1\x00\x00\x00\x00\xA8\x01\x75\x4B", "x????xxxx", 10)
    if m_dwGlowObjectManager == 0 then return false end
    m_dwGlowObjectManager = mem_read_i32(m_dwGlowObjectManager + 1) + 4
    if m_dwGlowObjectManager == 0 then return false end
    m_dwForceJump = mem_scan_pattern(0x2e96d8ca, "\x8B\x0D\x00\x00\x00\x00\x8B\xD6\x8B\xC1\x83\xCA\x02", "xx????xxxxxxx", 14)
    if m_dwForceJump == 0 then return false end
    m_dwForceJump = mem_read_i32(m_dwForceJump + 2)
    if m_dwForceJump == 0 then return false end
    m_dwEntityList = vt_entity - (mem_read_i32(get_interface_function(vt_entity, 6) + 0x22) - 0x38)
    m_dwClientState = mem_read_i32(mem_read_i32(get_interface_function(vt_engine, 18) + 0x21))
    m_dwGetLocalPlayer = mem_read_i32(get_interface_function(vt_engine, 12) + 0x16)
    m_dwViewAngles = mem_read_i32(get_interface_function(vt_engine, 19) + 0x191)
    m_dwMaxClients = mem_read_i32(get_interface_function(vt_engine, 20) + 0x07)
    m_dwState = mem_read_i32(get_interface_function(vt_engine, 26) + 0x07)
    m_dwButton = mem_read_i32(get_interface_function(vt_input, 15) + 0x21D)
    return true
end


function mem_initialize(process_name)
    g_handle = get_process_handle(process_name)
    if g_handle == 0 then
        return false
    end
    g_peb = get_process_peb(g_handle, 1)
    if g_peb == 0 then
        g_peb = get_process_peb(g_handle, 0)
        g_wow64 = 0
    else
        g_wow64 = 1
    end
    return true
end


function mem_is_running()
    local buffer = ffi.new("uint32_t[1]", 0)
    k32.GetExitCodeProcess(g_handle, buffer)
    return buffer[0] == 0x103
end


function mem_read(address, length)
    local buffer = ffi.new("char[?]", length)
    ntdll.NtReadVirtualMemory(g_handle, address, buffer, length, 0)
    return buffer
end


function mem_read_i8(address)
    local buffer = ffi.new("uint8_t[1]", 0)
    ntdll.NtReadVirtualMemory(g_handle, address, buffer, 1, 0)
    return buffer[0]
end


function mem_read_i16(address)
    local buffer = ffi.new("uint16_t[1]", 0)
    ntdll.NtReadVirtualMemory(g_handle, address, buffer, 2, 0)
    return buffer[0]
end


function mem_read_i32(address)
    local buffer = ffi.new("uint32_t[1]", 0)
    ntdll.NtReadVirtualMemory(g_handle, address, buffer, 4, 0)
    return buffer[0]
end


function mem_read_i64(address, length)
    local buffer = ffi.new("uint64_t[1]", 0)
    ntdll.NtReadVirtualMemory(g_handle, address, buffer, length or 8, 0)
    return buffer[0]
end


function mem_read_float(address)
    local buffer = ffi.new("float[1]", 0)
    ntdll.NtReadVirtualMemory(g_handle, address, buffer, 4, 0)
    return buffer[0]
end


function mem_read_float3(address)
    local buffer = ffi.new("float[3]", 0)
    ntdll.NtReadVirtualMemory(g_handle, address, buffer, 4, 0)
    return buffer
end


function mem_write_float(address, value)
    return ntdll.NtWriteVirtualMemory(g_handle, address, ffi.new("float[1]", value), 4, 0) == 0
end

function mem_write_i8(address, value)
    return ntdll.NtWriteVirtualMemory(g_handle, address, ffi.new("char[1]", value), 1, 0) == 0
end

function mem_write_i32(address, value)
    return ntdll.NtWriteVirtualMemory(g_handle, address, ffi.new("int[1]", value), 4, 0) == 0
end


function mem_get_module(module_crc)
    local a0 = {}
    if g_wow64 then
        a0 = {0x04, 0x0C, 0x14, 0x28, 0x10}
    else
        a0 = {0x08, 0x18, 0x20, 0x50, 0x20}
    end
    local a1 = mem_read_i64(mem_read_i64(g_peb + a0[2], a0[1]) + a0[3], a0[1])
    local a2 = mem_read_i64(a1 + a0[1], a0[1])
    while a1 ~= a2 do
        local a3 = mem_read(mem_read_i64(a1 + a0[4], a0[1]), 240)
        if ntdll.RtlComputeCrc32(g_encryption_key, a3, ffi.C.wcslen(a3) + 1) == module_crc then
            return mem_read_i64(a1 + a0[5], a0[1])
        end
        a1 = mem_read_i64(a1, a0[1])
    end
    return 0
end


function mem_get_export(module, export_crc)
    if module == 0 then
        return 0
    end
    local a0 = mem_read_i32(module + mem_read_i16(module + 0x3C) + (0x88 - g_wow64 * 0x10)) + module
    local a1 = {mem_read_i32(a0 + 0x18), mem_read_i32(a0 + 0x1C), mem_read_i32(a0 + 0x20), mem_read_i32(a0 + 0x24)}
    while a1[1] > 0 do
        a1[1] = a1[1] - 1
        local a2 = mem_read(module + mem_read_i32(module + a1[3] + (a1[1] * 4)), 120)
        if ntdll.RtlComputeCrc32(g_encryption_key, a2, ffi.C.strlen(a2) + 1) == export_crc then
            local a3 = mem_read_i16(module + a1[4] + (a1[1] * 2))
            local a4 = mem_read_i32(module + a1[2] + (a3 * 4))
            return module + a4
        end
    end
    return 0
end


function mem_scan_pattern(module_crc, pattern, mask, length)
    local a0 = mem_get_module(module_crc)
    local a1 = mem_read_i32(a0 + 0x03C) + a0
    local a2 = mem_read_i32(a1 + 0x01C)
    local a3 = mem_read_i32(a1 + 0x02C)
    local a4 = mem_read(a0 + a3, a2)
    local a5 = ffi.cast("char *", pattern)
    local a6 = ffi.cast("char *", mask)
    for a7 = 0, a2 do
        local a8 = 0
        for a9 = 0, length do
            if a6[a9] == 0x78 and a4[a7 + a9] ~= a5[a9] then
                break
            end
            a8 = a8 + 1
        end
        if a8 - 1 == length then
            return a0 + a3 + a7
        end
    end
    return 0
end


function get_interface_factory(crc_module)
    local a0 = mem_get_export(mem_get_module(crc_module), 0xe7838d08)
    return mem_read_i32(mem_read_i32(a0 - 0x6A))
end


function get_interface(interface_factory, crc_interface)
    while interface_factory ~= 0 do
        local a0 = mem_read(mem_read_i32(interface_factory + 0x4), 120)
        if ntdll.RtlComputeCrc32(g_encryption_key, a0, ffi.C.strlen(a0) - 2) == crc_interface then
            return mem_read_i32(mem_read_i32(interface_factory) + 1)
        end
        interface_factory = mem_read_i32(interface_factory + 0x8)
    end
    return 0
end


function get_interface_function(interface, index)
    return mem_read_i32(mem_read_i32(interface) + index * 4)
end


function get_netvar_table(crc_netvar_table)
    local a0 = mem_read_i32(mem_read_i32(get_interface_function(vt_client, 8) + 1))
    while a0 ~= 0 do
        local a1 = mem_read_i32(a0 + 0x0C)
        local a2 = mem_read(mem_read_i32(a1 + 0x0C), 120)
        if ntdll.RtlComputeCrc32(g_encryption_key, a2, ffi.C.strlen(a2) + 1) == crc_netvar_table then
            return a1
        end
        a0 = mem_read_i32(a0 + 0x10)
    end
    return 0
end


function __get_netvar_offset_ex(netvar_table, crc_netvar)
    local a0 = 0
    for a1 = 0, mem_read_i32(netvar_table + 0x4) do
        local a2 = a1 * 60 + mem_read_i32(netvar_table)
        local a3 = mem_read_i32(a2 + 0x2C)
        local a4 = mem_read(mem_read_i32(a2), 120)
        if ntdll.RtlComputeCrc32(g_encryption_key, a4, ffi.C.strlen(a4) + 1) == crc_netvar then
            return a3 + a0
        end
    end
    return a0
end


function get_netvar_offset(netvar_table, crc_netvar)
    local a0 = 0
    for a1 = 0, mem_read_i32(netvar_table + 0x4) do
        local a2 = a1 * 60 + mem_read_i32(netvar_table)
        local a3 = mem_read_i32(a2 + 0x2C)
        local a4 = mem_read_i32(a2 + 0x28)
        if a4 ~= 0 and mem_read_i32(a4 + 0x4) ~= 0 then
            local a5 = __get_netvar_offset_ex(a4, crc_netvar)
            if a5 ~= 0 then
                a0 = a0 + a3 + a5
            end
        end
        local a6 = mem_read(mem_read_i32(a2), 120)
        if ntdll.RtlComputeCrc32(g_encryption_key, a6, ffi.C.strlen(a6) + 1) == crc_netvar then
            return a3 + a0
        end
    end
    return a0
end


function get_convar(crc_convar)
    local a0 = mem_read_i32(mem_read_i32(mem_read_i32(vt_cvar + 0x34)) + 0x4)
    while a0 ~= 0 do
        local a1 = mem_read(mem_read_i32(a0 + 0x0C), 120)
        if ntdll.RtlComputeCrc32(g_encryption_key, a1, ffi.C.strlen(a1) + 1) == crc_convar then
            return a0
        end
        a0 = mem_read_i32(a0 + 0x4)
    end
    return 0
end


function get_int(convar)
    return ffi.new("uint32_t[1]", bit.bxor(mem_read_i32(convar + 0x30), convar))[0]
end


function get_float(convar)
    return ffi.cast("float*", ffi.new("uint32_t[1]", bit.bxor(mem_read_i32(convar + 0x2C), convar)))[0]
end


function is_button_down(button)
    local a0 = mem_read_i32(vt_input + (bit.rshift(button, 5) * 4) + m_dwButton)
    return bit.band((bit.rshift(a0, (bit.band(button, 31)))), 1)
end


function is_in_game()
    return mem_read_i8(m_dwClientState + m_dwState) == 6
end


function get_local_player()
    return mem_read_i32(m_dwClientState + m_dwGetLocalPlayer)
end


function get_max_clients()
    return mem_read_i32(m_dwClientState + m_dwMaxClients)
end


function get_view_angles()
    return {
        mem_read_float(m_dwClientState + m_dwViewAngles),
        mem_read_float(m_dwClientState + m_dwViewAngles + 4),
        mem_read_float(m_dwClientState + m_dwViewAngles + 8)
    }
end


function get_client_entity(index)
    return mem_read_i32(m_dwEntityList + index * 0x10)
end


function is_visible(player, entity)
    local mask = mem_read_i32(entity + 0x980)
    local base = mem_read_i32(player + 0x64) - 1
    return (bit.band(mask, (bit.lshift(1, base)))) > 0
end


function get_team_num(entity)
    return mem_read_i32(entity + m_iTeamNum)
end


function get_health(entity)
    return mem_read_i32(entity + m_iHealth)
end


function get_flags(entity)
    return mem_read_i32(entity + m_fFlags)
end


function get_life_state(entity)
    return mem_read_i32(entity + m_lifeState)
end


function get_tick_count(entity)
    return mem_read_i32(entity + m_nTickBase)
end


function get_shots_fired(entity)
    return mem_read_i32(entity + m_iShotsFired)
end


function get_cross_index(entity)
    return mem_read_i32(entity + m_iCrossHairID)
end


function get_origin(entity)
    return {
        mem_read_float(entity + m_vecOrigin),
        mem_read_float(entity + m_vecOrigin + 4),
        mem_read_float(entity + m_vecOrigin + 8)
    }
end


function get_vec_view(entity)
    return {
        mem_read_float(entity + m_vecViewOffset),
        mem_read_float(entity + m_vecViewOffset + 4),
        mem_read_float(entity + m_vecViewOffset + 8)
    }
end


function get_eye_pos(entity)
    local v = get_vec_view(entity)
    local o = get_origin(entity)
    return {v[1] + o[1], v[2] + o[2], v[3] + o[3]}
end


function get_velocity(entity)
    local x = mem_read_float(entity + m_vecVelocity)
    local y = mem_read_float(entity + m_vecVelocity + 4)
    return math.sqrt(x * x + y * y)
end


function get_vec_punch(entity)
    return {
        mem_read_float(entity + m_vecPunch),
        mem_read_float(entity + m_vecPunch + 4),
        mem_read_float(entity + m_vecPunch + 8)
    }
end


function get_bone_pos(entity, index)
    local a0 = 0x30 * index
    local a1 = mem_read_i32(entity + m_dwBoneMatrix)
    return {
        mem_read_float(a1 + a0 + 0x0C),
        mem_read_float(a1 + a0 + 0x1C),
        mem_read_float(a1 + a0 + 0x2C)
    }
end


function is_valid(entity)
    if entity == 0 then
        return false
    end
    local health = get_health(entity)
    return get_life_state(entity) == 0 and health > 0 and health < 1337
end


-- fuck you obs --
-- https://github.com/obsproject/obs-studio/commit/0acf86ba046efd4bc37ed9931cc2c0f4bc74f9dd#diff-154ed4865eac33aca4ca5db04f5fd70c
function patch_flags(access_mask)
    local address = k32.GetModuleHandleA("win-capture.dll") + 0x48BD + 1
    return k32.WriteProcessMemory(-1, address, ffi.new("int[1]", access_mask), 4, 0)
end


-- find process handle --
function get_process_handle(process_name)
    local index  = 0x2710
    local buffer = ffi.new("char[20]", 0)
    while index > 0 do
        if k32.K32GetModuleBaseNameA(index, 0, buffer, 20) then
            if ffi.C._stricmp(buffer, process_name) == 0 then
                return index
            end
        end
        index = index - 4
    end
    return 0
end


-- find process peb --
function get_process_peb(process_handle, wow64)
    local buffer = ffi.new("uint64_t[6]", 0)
    local len = ffi.new("uint32_t[1]", 0)
    if wow64 == 1 then
        if ntdll.NtQueryInformationProcess(process_handle, 26, buffer, 8, len) == 0 then
            return buffer[0]
        end
    else
        if ntdll.NtQueryInformationProcess(process_handle, 0, buffer, 48, len) == 0 then
            return buffer[1]
        end
    end
    return 0
end


function sincos(radians)
    return {math.sin(radians), math.cos(radians)}
end


function rad_to_deg(rad)
    return rad * 3.141592654
end


function deg_to_rad(deg)
    return deg * 0.017453293
end


function angle_vec(angles)
    local s = sincos(deg_to_rad(angles[1]))
    local y = sincos(deg_to_rad(angles[2]))
    return {s[2] * y[2], s[2] * y[1], -s[1]}
end


function angle_normalize(angles)
    local radius = 1.0 / (math.sqrt(angles[1] * angles[1] + angles[2] * angles[2] + angles[3] * angles[3]) + 1.192092896e-07)
    angles[1] = angles[1] * radius
    angles[2] = angles[2] * radius
    angles[3] = angles[3] * radius
    return angles
end


function vec_angles(forward)
    local tmp, yaw, pitch
    if forward[2] == 0.00 and forward[1] == 0.00 then
        yaw = 0
        if forward[3] > 0.00 then
            pitch = 270.0
        else
            pitch = 90.0
        end
    else
        yaw = math.atan2(forward[2], forward[1]) * 57.295779513
        if yaw < 0.00 then
            yaw = yaw + 360.0
        end
        tmp = math.sqrt(forward[1] * forward[1] + forward[2] * forward[2])
        pitch = math.atan2(-forward[3], tmp) * 57.295779513
        if pitch < 0.00 then
            pitch = pitch + 360.0
        end
    end
    return {pitch, yaw, 0.00}
end


function vec_clamp(angles)
    if angles[1] > 89.0 and angles[1] <= 180.0 then
        angles[1] = 89.0
    end
    if angles[1] > 180.0 then
        angles[1] = angles[1] - 360.0
    end
    if angles[1] < -89.0 then
        angles[1] = -89.0
    end
    angles[2] = math.fmod(angles[2] + 180, 360) - 180
    return angles
end


function vec_dot(v0, v1)
    return v0[1] * v1[1] + v0[2] * v1[2] + v0[3] * v1[3]
end


function vec_length(v)
    return v[1] * v[1] + v[2] * v[2] + v[3] * v[3]
end


function get_fov(p0, p1)
    local a0 = angle_vec(p0)
    local a1 = angle_vec(p1)
    return rad_to_deg(math.acos(vec_dot(a0, a1) / vec_length(a0)))
end

