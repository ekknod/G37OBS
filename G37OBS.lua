-- ekknod@2019 --
local obs                      = obslua
local bit                      = require("bit")
local ffi                      = require("ffi")
local ntdll                    = ffi.load("ntdll.dll")
local u32                      = ffi.load("user32.dll")
local k32                      = ffi.load("kernel32.dll")
local g_encryption_key         = 0x5F2135
local g_handle                 = 0
local g_wow64                  = 0
local g_peb                    = 0
local g_target                 = 0
local g_target_bone            = 0
local g_previous_tick          = 0
local g_old_punch              = {0.00, 0.00, 0.00}
local g_bones                  = {5, 4, 3, 0, 7, 8}

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
local m_vecOrigin              = 0
local m_iShotsFired            = 0
local m_iCrossHairID           = 0
local m_iGlowIndex             = 0
local m_dwBoneMatrix           = 0
local m_dwGlowObjectManager    = 0
local m_dwEntityList           = 0
local m_dwClientState          = 0
local m_dwGetLocalPlayer       = 0
local m_dwViewAngles           = 0
local m_dwMaxClients           = 0
local m_dwState                = 0
local m_dwButton               = 0

local cl_glow                = true
local cl_glow_always         = true
local cl_rcs                 = false
local cl_aimbot              = true
local cl_aimbot_head         = false
local cl_aimbot_legit        = true
local cl_aimbot_rcs          = true
local cl_aimbot_smooth       = 4.5
local cl_aimbot_fov          = 1.0 / 180.0
local cl_aimbot_key          = 107
local cl_triggerbot_key      = 111


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
uint32_t RtlCrc32(const void *, uint64_t, uint32_t);
void *memcpy(void *, const void *, size_t);
size_t strlen (const char*);
size_t wcslen (const wchar_t*);
int wcscmp (const wchar_t*, const wchar_t*);
int strcmp (const char *, const char *);
void *CreateThread(uint64_t, uint64_t, void(*)(), uint64_t, uint32_t, uint64_t);

double sin(double);
double cos(double);
double sqrt(double);
double atan2(double, double);
double fabs(double);
]]

function script_description()
    return "<b>G37OBS</b><hr>ekknod@2019"
end

function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_bool(props, "cl_glow", "Glow ESP")
    obs.obs_properties_add_bool(props, "cl_glow_always", "Glow ESP [Triggerbot Key]")
    obs.obs_properties_add_bool(props, "cl_rcs", "Recoil Control System")
    obs.obs_properties_add_bool(props, "cl_aimbot", "Aimbot")
    obs.obs_properties_add_bool(props, "cl_aimbot_head", "Aimbot Head Only")
    obs.obs_properties_add_bool(props, "cl_aimbot_legit", "Aimbot Legit")
    obs.obs_properties_add_bool(props, "cl_aimbot_rcs", "Aimbot No Recoil")
    obs.obs_properties_add_float_slider(props, "cl_aimbot_smooth", "Aimbot Smooth", 0.0, 1000.0, 0.25)
    obs.obs_properties_add_float_slider(props, "cl_aimbot_fov", "Aimbot Fov", 0.0, 180.0, 0.25)
    obs.obs_properties_add_int(props, "cl_aimbot_key", "Aimbot Key", 0, 123, 1)
    obs.obs_properties_add_int(props, "cl_triggerbot_key", "Triggerbot Key", 0, 123, 1)
    obs.obs_properties_add_button(props, "start_button", "Start", callback_start)
    obs.obs_properties_add_button(props, "stop_button", "Stop", callback_stop)
    return props
end

function script_load()
    -- 0x1fffff = PROCESS_ALL_ACCESS
    -- 0x000410 = PROCESS_QUERY_INFORMATION | PROCESS_VM_READ
    -- 0x000430 = PROCESS_QUERY_INFORMATION | PROCESS_VM_READ | PROCESS_VM_WRITE
    if cl_glow then
        patch_flags(0x000430)
    else
        patch_flags(0x000410)
    end
end

function script_defaults(settings)
    obs.obs_data_set_default_bool(settings, "cl_glow", cl_glow)
    obs.obs_data_set_default_bool(settings, "cl_glow_always", cl_glow_always)
    obs.obs_data_set_default_bool(settings, "cl_rcs", cl_rcs)
    obs.obs_data_set_default_bool(settings, "cl_aimbot", cl_aimbot)
    obs.obs_data_set_default_bool(settings, "cl_aimbot_head", cl_aimbot_head)
    obs.obs_data_set_default_bool(settings, "cl_aimbot_legit", cl_aimbot_legit)
    obs.obs_data_set_default_bool(settings, "cl_aimbot_rcs", cl_aimbot_rcs)
    obs.obs_data_set_default_double(settings, "cl_aimbot_smooth", cl_aimbot_smooth)
    obs.obs_data_set_default_double(settings, "cl_aimbot_fov", 1.0)
    obs.obs_data_set_default_int(settings, "cl_aimbot_key", cl_aimbot_key)
    obs.obs_data_set_default_int(settings, "cl_triggerbot_key", cl_triggerbot_key)
end

function script_update(settings)
    cl_glow = obs.obs_data_get_bool(settings, "cl_glow")
    cl_glow_always = obs.obs_data_get_bool(settings, "cl_glow_always")
    cl_rcs = obs.obs_data_get_bool(settings, "cl_rcs")
    cl_aimbot = obs.obs_data_get_bool(settings, "cl_aimbot")
    cl_aimbot_head = obs.obs_data_get_bool(settings, "cl_aimbot_head")
    cl_aimbot_legit = obs.obs_data_get_bool(settings, "cl_aimbot_legit")
    cl_aimbot_rcs = obs.obs_data_get_bool(settings, "cl_aimbot_rcs")
    cl_aimbot_smooth = obs.obs_data_get_double(settings, "cl_aimbot_smooth")
    cl_aimbot_fov = obs.obs_data_get_double(settings, "cl_aimbot_fov") / 180.0
    cl_aimbot_key = obs.obs_data_get_int(settings, "cl_aimbot_key")
    cl_triggerbot_key = obs.obs_data_get_int(settings, "cl_triggerbot_key")
end

function script_tick(seconds)
    if mem_is_running() then
        if not is_in_game() then
            return
        end
        local player = get_client_entity(get_local_player())
        local view_angle = get_view_angles()
        local fl_sensitivity = get_float(sensitivity)
        if is_button_down(cl_triggerbot_key) == 1 then
            triggerbot(player)
        end
        if cl_aimbot and is_button_down(cl_aimbot_key) == 1 then
            aimbot(player, view_angle, fl_sensitivity)
        else
            g_target = 0
        end
        if cl_rcs then
            rcs(player, view_angle, fl_sensitivity)
        end
        if cl_glow then
            if cl_glow_always and is_button_down(cl_triggerbot_key) == 0 then
                return
            end
            glow(player)
        end
    end
end

function callback_start(props, p)
    if mem_is_running() then
        return
    end
    if not mem_initialize("csgo.exe") then
        return
    end
    if not vt_initialize() then
        return
    end
    if not nv_initialize() then
        return
    end
    sensitivity = get_convar(0x395d48d4)
    mp_teammates_are_enemies = get_convar(0x603d532b)
    k32.Beep(450, 500)
end

function callback_stop(props, p)
    g_handle = 0
end

function glow(player)
    local glow_pointer = mem_read_i32(m_dwGlowObjectManager)
    for i = 0, get_max_clients(), 1 do
        local entity = get_client_entity(i)
        if is_valid(entity) then
            if get_int(mp_teammates_are_enemies) == 0 and get_team_num(player) == get_team_num(entity) then
                goto continue
            end
            -- another way
            -- ( entity + 0x3960 ) = flDetectedByEnemySensorTime
            local entity_health = get_health(entity) / 100.0
            local index = mem_read_i32(entity + m_iGlowIndex) * 0x38
            mem_write_float(glow_pointer + index + 0x04, 1.0 - entity_health)  -- r
            mem_write_float(glow_pointer + index + 0x08, entity_health)        -- g
            mem_write_float(glow_pointer + index + 0x0C, 0.0)                  -- b
            mem_write_float(glow_pointer + index + 0x10, 0.8)                  -- a
            mem_write_i8(glow_pointer + index + 0x24, 1)
            mem_write_i8(glow_pointer + index + 0x25, 0)
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

function triggerbot(player)
    local index = get_cross_index(player)
    if index == 0 then
        return
    end
    local entity = get_client_entity(index - 1)
    if get_team_num(player) ~= get_team_num(entity) and get_health(entity) > 0 then
        u32.mouse_event(0x0002, 0, 0, 0, 0)
        u32.mouse_event(0x0004, 0, 0, 0, 0)
    end
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
    for i = 0, get_max_clients(), 1 do
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
                for j = 1, 6, 1 do
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
    if (ntdll.fabs(x) / 180.0) >= cl_aimbot_fov then
        g_target = 0
        return
    end
    if (ntdll.fabs(y) / 89.0) >= cl_aimbot_fov then
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

function vt_initialize()
    local table = get_interface_factory(0xe32c87ca)
    if table == 0 then
        return false
    end
    vt_client = get_interface(table, 0xa3588f60)
    vt_entity = get_interface(table, 0x3aba23bf)
    table = get_interface_factory(0x2a6cf06a)
    if table == 0 then
        return false
    end
    vt_engine = get_interface(table, 0x6d557021)
    table = get_interface_factory(0x3f9458c1)
    if table == 0 then
        return false
    end
    vt_cvar = get_interface(table, 0xa70d20c6)
    table = get_interface_factory(0xbe7a9f4c)
    if table == 0 then
        return false
    end
    vt_input = get_interface(table, 0x15813dcd)
    return true
end

function nv_initialize()
    local a0 = ffi.new("unsigned char[?]", 10)
    a0[0] = 0xA1
    a0[1] = 0x00
    a0[2] = 0x00
    a0[3] = 0x00
    a0[4] = 0x00
    a0[5] = 0xA8
    a0[6] = 0x01
    a0[7] = 0x75
    a0[8] = 0x4B
    a0[9] = 0x00
    local a1 = ffi.new("unsigned char[?]", 10)
    a1[0] = 0x78
    a1[1] = 0x3f
    a1[2] = 0x3f
    a1[3] = 0x3f
    a1[4] = 0x3f
    a1[5] = 0x78
    a1[6] = 0x78
    a1[7] = 0x78
    a1[8] = 0x78
    a1[9] = 0x00
    local table = get_netvar_table(0x6bc91a61)
    m_iHealth = get_netvar_offset(table, 0x382a0d22)
    m_vecViewOffset = get_netvar_offset(table, 0xd559c683)
    m_lifeState = get_netvar_offset(table, 0x36e1804)
    m_nTickBase = get_netvar_offset(table, 0x5d7b904)
    m_vecPunch = get_netvar_offset(table, 0xcb82e6e9) + 0x70
    m_vecVelocity = get_netvar_offset(table, 0x38157a6)
    m_fFlags = get_netvar_offset(table, 0x545667e9)
    table = get_netvar_table(0x23ff2c3a)
    m_iTeamNum = get_netvar_offset(table, 0x82ce835)
    m_vecOrigin = get_netvar_offset(table, 0x10a3868f)
    table = get_netvar_table(0x1ca12dde)
    m_iShotsFired = get_netvar_offset(table, 0x4b93831e)
    m_iCrossHairID = get_netvar_offset(table, 0x81f86f46) + 0x5C
    m_iGlowIndex = get_netvar_offset(table, 0xd8343d48) + 0x18
    table = get_netvar_table(0x4d7d72f9)
    m_dwBoneMatrix = get_netvar_offset(table, 0xc1fb72) + 0x1C
    -- table = get_netvar_table(0x956d820a)
    -- m_iItemDefinitionIndex = get_netvar_offset(table, 0x2a0c9a76)
    m_dwGlowObjectManager = mem_scan_pattern(0xe32c87ca, a0, a1, 10)
    m_dwGlowObjectManager = mem_read_i32(m_dwGlowObjectManager + 1) + 4
    m_dwEntityList = vt_entity - (mem_read_i32(get_interface_function(vt_entity, 5) + 0x22) - 0x38)
    m_dwClientState = mem_read_i32(mem_read_i32(get_interface_function(vt_engine, 18) + 0x16))
    m_dwGetLocalPlayer = mem_read_i32(get_interface_function(vt_engine, 12) + 0x16)
    m_dwViewAngles = mem_read_i32(get_interface_function(vt_engine, 19) + 0xB2)
    m_dwMaxClients = mem_read_i32(get_interface_function(vt_engine, 20) + 0x07)
    m_dwState = mem_read_i32(get_interface_function(vt_engine, 26) + 0x07)
    m_dwButton = mem_read_i32(get_interface_function(vt_input, 15) + 0x21D)
    return 1
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

function mem_read_bytes(address, length)
    local buffer = ffi.new("unsigned char[?]", length)
    ntdll.NtReadVirtualMemory(g_handle, address, buffer, length, 0)
    return buffer
end

function mem_read_i8_buffer(address)
    local buffer = ffi.new("char[120]", 0)
    ntdll.NtReadVirtualMemory(g_handle, address, buffer, 120, 0)
    return buffer
end

function mem_read_i16_buffer(address)
    local buffer = ffi.new("short[120]", 0)
    ntdll.NtReadVirtualMemory(g_handle, address, buffer, 240, 0)
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
    return k32.WriteProcessMemory(g_handle, address, ffi.new("float[1]", value), 4, 0)
end

function mem_write_i8(address, value)
    return k32.WriteProcessMemory(g_handle, address, ffi.new("char[1]", value), 1, 0)
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
        local a3 = mem_read_i16_buffer(mem_read_i64(a1 + a0[4], a0[1]))
        if ntdll.RtlCrc32(a3, ffi.C.wcslen(a3) + 1, g_encryption_key) == module_crc then
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
        local a2 = mem_read_i8_buffer(module + mem_read_i32(module + a1[3] + (a1[1] * 4)))
        if ntdll.RtlCrc32(a2, ffi.C.strlen(a2) + 1, g_encryption_key) == export_crc then
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
    local a4 = mem_read_bytes(a0 + a3, a2)
    for a5 = 0, a2, 1 do
        local a6 = 0
        for a7 = 0, length, 1 do
            if mask[a7] == 0x78 and a4[a5 + a7] ~= pattern[a7] then
                break
            end
            a6 = a6 + 1
        end
        if mask[a6] == 0 then
            return a0 + a3 + a5
        end
    end
    return 0
end

function get_interface_factory(crc_module)
    local a0 = mem_get_export(mem_get_module(crc_module), 0xb4d20654)
    return mem_read_i32(mem_read_i32(a0 - 0x6A))
end

function get_interface(interface_factory, crc_interface)
    while interface_factory ~= 0 do
        local a0 = mem_read_i8_buffer(mem_read_i32(interface_factory + 0x4))
        if ntdll.RtlCrc32(a0, ffi.C.strlen(a0) - 2, g_encryption_key) == crc_interface then
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
        local a2 = mem_read_i8_buffer(mem_read_i32(a1 + 0x0C))
        if ntdll.RtlCrc32(a2, ffi.C.strlen(a2) + 1, g_encryption_key) == crc_netvar_table then
            return a1
        end
        a0 = mem_read_i32(a0 + 0x10)
    end
    return 0
end

function __get_netvar_offset_ex(netvar_table, crc_netvar)
    local a0 = 0
    for a1 = 0, mem_read_i32(netvar_table + 0x4), 1 do
        local a2 = a1 * 60 + mem_read_i32(netvar_table)
        local a3 = mem_read_i32(a2 + 0x2C)
        local a4 = mem_read_i8_buffer(mem_read_i32(a2))
        if ntdll.RtlCrc32(a4, ffi.C.strlen(a4) + 1, g_encryption_key) == crc_netvar then
            return a3 + a0
        end
    end
    return a0
end

function get_netvar_offset(netvar_table, crc_netvar)
    local a0 = 0
    for a1 = 0, mem_read_i32(netvar_table + 0x4), 1 do
        local a2 = a1 * 60 + mem_read_i32(netvar_table)
        local a3 = mem_read_i32(a2 + 0x2C)
        local a4 = mem_read_i32(a2 + 0x28)
        if a4 ~= 0 and mem_read_i32(a4 + 0x4) ~= 0 then
            local a5 = __get_netvar_offset_ex(a4, crc_netvar)
            if a5 ~= 0 then
                a0 = a0 + a3 + a5
            end
        end
        local a6 = mem_read_i8_buffer(mem_read_i32(a2))
        if ntdll.RtlCrc32(a6, ffi.C.strlen(a6) + 1, g_encryption_key) == crc_netvar then
            return a3 + a0
        end
    end
    return a0
end

function get_convar(crc_convar)
    local a0 = mem_read_i32(mem_read_i32(mem_read_i32(vt_cvar + 0x34)) + 0x4)
    while a0 ~= 0 do
        local a1 = mem_read_i8_buffer(mem_read_i32(a0 + 0x0C))
        if ntdll.RtlCrc32(a1, ffi.C.strlen(a1) + 1, g_encryption_key) == crc_convar then
            return a0
        end
        a0 = mem_read_i32(a0 + 0x4)
    end
    return 0
end

function get_int(convar)
    local a0 = ffi.new("uint32_t[1]", 0)
    local a1 = bit.bxor(mem_read_i32(convar + 0x30), convar)
    ntdll.memcpy(a0, ffi.new("uint32_t[1]", a1), 4)
    return a0[0]
end

function get_float(convar)
    local a0 = ffi.new("float[1]", 0)
    local a1 = bit.bxor(mem_read_i32(convar + 0x2C), convar)
    ntdll.memcpy(a0, ffi.new("uint32_t[1]", a1), 4)
    return a0[0]
end

function is_button_down(button)
    a0 = mem_read_i32(vt_input + (bit.rshift(button, 5) * 4) + m_dwButton)
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
    return ntdll.sqrt(x * x + y * y)
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
    local address = k32.GetModuleHandleA("win-capture.dll") + 0x58AE
    return k32.WriteProcessMemory(-1, address, ffi.new("int[1]", access_mask), 4, 0)
end

-- find process handle --
function get_process_handle(process_name)
    local index  = 0x2710
    local buffer = ffi.new("char[20]", 0)
    while index > 0 do
        if k32.K32GetModuleBaseNameA(index, 0, buffer, 20) then
            if ffi.C.strcmp(buffer, process_name) == 0 then
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
    return {ntdll.sin(radians), ntdll.cos(radians)}
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
    local radius = 1.0 / (ntdll.sqrt(angles[1] * angles[1] + angles[2] * angles[2] + angles[3] * angles[3]) + 1.192092896e-07)
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
        yaw = ntdll.atan2(forward[2], forward[1]) * 57.295779513
        if yaw < 0.00 then
            yaw = yaw + 360.0
        end
        tmp = ntdll.sqrt(forward[1] * forward[1] + forward[2] * forward[2])
        pitch = ntdll.atan2(-forward[3], tmp) * 57.295779513
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
