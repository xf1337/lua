--dedicated lua for etnasy.gg
local info = {}; do
    info.username = 'etnasy.gg user'
    info.hwid = 0
    info.till = 123123123
    info.build = 'alpha'
    info.current_version = '4'
    info.cur_last_upd = '21.02.2024'
    info.last_update = 0
end

local max_tickbase = 0
rage.is_defensive_active = function()
    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then return end

    local tickbase = lp.m_nTickBase
    if math.abs(tickbase - max_tickbase) > 64 then
        max_tickbase = 0
    end

    local defensive_ticks_left = 0

    if tickbase > max_tickbase then
        max_tickbase = tickbase
    elseif max_tickbase > tickbase then
        defensive_ticks_left = math.min(14, math.max(0, max_tickbase-tickbase-1))
    end

    return defensive_ticks_left > 0
end
local function vtable_thunk(index, ...) local ctype = ffi.typeof(...); return function(instance, ...) assert(instance ~= nil, "invalid instance"); local vtable = ffi.cast("void***", instance); local vfunc = ffi.cast(ctype, vtable[0][index]); return vfunc(instance, ...); end end
local function vtable_bind(module_name, interface_name, index, ...) local addr = utils.create_interface(module_name, interface_name); assert(addr, "invalid interface"); local ctype = ffi.typeof(...); local vtable = ffi.cast("void***", addr); local vfunc = ffi.cast(ctype, vtable[0][index]); return function(...) return vfunc(vtable, ...); end end
local function __thiscall(func, this) return function(...) return func(this, ...) end end

local kernel32 = ffi.load("kernel32")
local jmp_hook = utils.pattern_scan("engine.dll", "FF E1")
local native = {
    fnGetModuleHandle = ffi.cast("uint32_t(__fastcall*)(unsigned int, unsigned int, const char*)", jmp_hook),
    fnGetProcAddress = ffi.cast("uint32_t(__fastcall*)(unsigned int, unsigned int, uint32_t, const char*)", jmp_hook),
    pGetProcAddress = ffi.cast("uint32_t**", ffi.cast("uint32_t", utils.pattern_scan("engine.dll", "FF 15 ? ? ? ? A3 ? ? ? ? EB 05")) + 2)[0][0],
    pGetModuleHandle = ffi.cast("uint32_t**", ffi.cast("uint32_t", utils.pattern_scan("engine.dll", "FF 15 ? ? ? ? 85 C0 74 0B")) + 2)[0][0]
}
local defensive_link = tostring(network.get('https://i.ibb.co/phGPKrC/65da1730f046c-1708791633-65da1730f0444.png'))
local slowed_link = tostring(network.get('https://i.ibb.co/1K80W2Z/s.png'))
local vector_extension; do
    local vector_mt = getmetatable(vector());
    function vector_mt.by_i(s, i, v)
        if v ~= nil then if i == 1 then s.x = v else s.y = v end return s end
        if i == 1 then return s.x else return s.y end
    end
    function vector_mt:unpack() return self.x, self.y, self.z; end
    function vector_mt:is_zero() return self.x == 0 and self.y == 0 and self.z == 0 end
    function vector_mt:__add(vec)
        if type(vec) == "number" then vec = vector(vec, vec, vec); end
        return vector(self.x + vec.x, self.y + vec.y, self.z + vec.z);
    end
    function vector_mt:__sub(vec)
        if type(vec) == "number" then vec = vector(vec, vec, vec); end
        return vector(self.x - vec.x, self.y - vec.y, self.z - vec.z);
    end
    function vector_mt:__mul(vec)
        if type(vec) == "number" then vec = vector(vec, vec, vec); end
        return vector(self.x * vec.x, self.y * vec.y, self.z * vec.z);
    end
    function vector_mt:__div(vec)
        if type(vec) == "number" then vec = vector(vec, vec, vec); end
        return vector(self.x / vec.x, self.y / vec.y, self.z / vec.z);
    end
    function vector_mt:__unm() return self * -1; end
end
local color_extension; do
    local color_mt = getmetatable(color());
    color_mt.alpha = function(s, a) return color(s.r, s.g, s.b, a) end
    color_mt.alp = function(s, a) return s:alpha(a * 255) end
    color_mt.alp_self = function(s, a) return s:alpha((a * s.a / 255) * 255) end
    function color_mt:unpack() return self.r, self.g, self.b, self.a end 
    function color_mt:to_hex() return string.format("%02x%02x%02x%02x", self:unpack()) end 
end
-- dsc.gg/southwestcfg
ffi.cdef([[
    typedef uint16_t time_enum;
    typedef struct {
        time_enum year;
        time_enum month;
        time_enum dayw;
        time_enum day;
        time_enum hour;
        time_enum minute;
        time_enum second;
        time_enum millisecond;
    } SYSTEMTIME;
    void GetLocalTime(SYSTEMTIME *lpSystemTime);

    typedef unsigned long POINTER;
    POINTER GetForegroundWindow();
    
    bool SetWindowTextA(POINTER hWnd, const char* lpString);

    typedef int BOOL;
    typedef unsigned long HANDLE;
    typedef HANDLE HWND;
    typedef int bInvert;
 
    HWND GetActiveWindow(void);

    BOOL FlashWindow(HWND hWnd, BOOL bInvert);
]])
local clipboard do
    clipboard = { }

    local GetClipboardTextCount = vtable_bind('vgui2.dll', 'VGUI_System010', 7, 'int(__thiscall*)(void*)')
    local SetClipboardText = vtable_bind('vgui2.dll', 'VGUI_System010', 9, 'void(__thiscall*)(void*, const char*, int)')
    local GetClipboardText = vtable_bind('vgui2.dll', 'VGUI_System010', 11, 'int(__thiscall*)(void*, int, const char*, int)')

    local function set(...)
        local text = tostring(table.concat({ ... }))

        SetClipboardText(text, string.len(text))
    end

    local function get()
        local len = GetClipboardTextCount()

        if len > 0 then
            local char_arr = ffi.typeof('char[?]')(len)
            GetClipboardText(0, char_arr, len)
            local text = ffi.string(char_arr, len - 1)

            return text:gsub('~etnasy.gg~', '')
        end
    end

    clipboard.set = set
    clipboard.get = get
end

local main = {
    screen_size = render.screen_size(),
    hz = 60,
    conditions = {'» global', '» standing', '» moving', '» slow-walking', '» in air', '» crouching', '» air-crouching'},
    short_conditions = {'g ~ ', 's ~ ', 'm ~ ', 'sw ~ ', 'a ~ ', 'c ~ ', 'ac ~ '},
    welcomer = {
        "you welcome",
    },
    clantag_speed = 5,
    clantag_stage = 1,
    steamname = cvar.name:string()
}

main.welcome_phrase = main.welcomer[math.random(1, #main.welcomer)]
local refs = {
    antiaim = {
        manual_left = ui.find('Anti aim', 'Angles', 'Manual left'),
        manual_right = ui.find('Anti aim', 'Angles', 'Manual right'),
        body_yaw = ui.find('Anti aim', 'Angles', 'Body yaw'),
        body_yaw_options = ui.find('Anti aim', 'Angles', 'Body yaw options'),
        limit = ui.find('Anti aim', 'Angles', 'Limit'),
        yaw_jitter = ui.find('Anti aim', 'Angles', 'Yaw jitter')
    },
    ragebot = {
        hideshots = ui.find('Aimbot', 'Aimbot', 'Hide Shots'),
        doubletap = ui.find('Aimbot', 'Aimbot', 'Double Tap')
    }
}
local base64 = {
    b = 'ANGELwaveBCFHJKMOQRShuyTUVWXYbcdfgijklmnopPIZDqrstxz0123456789+/',
    encode = function(self, data)
        return ((data:gsub('.', function(x)
            local r,b='',x:byte()
            for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
            return r;
        end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
            if (#x < 6) then return '' end
            local c=0
            for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
            return self.b:sub(c+1,c+1)
        end)..({ '', '==', '=' })[#data%3+1])
    end,
    decode = function(self, data)
        data = string.gsub(data, '[^'..self.b..'=]', '')
        return (data:gsub('.', function(x)
            if (x == '=') then return '' end
            local r,f='',(self.b:find(x)-1)
            for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
            return r;
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if (#x ~= 8) then return '' end
            local c=0
            for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
                return string.char(c)
        end))
    end
}

ui.tab("etnasy.gg lua");
local menu = {
    tab = {
        home = ui.groupbox('etnasy.gg lua', '« home »'),
        main = ui.groupbox('etnasy.gg lua', '« main »')
    },
    visual = {}, home = {}, aa = {}, misc = {}, builder = {},
    elements = function(self)
        self.navigation = self.tab.home:combo(' etnasy.gg lua ~ '.. main.welcome_phrase, '» home', '» anti-aim', '» visual', '» misc')
        self.home.welcome_text = self.tab.main:label('» welcome back etnasy.gg user!\n» dedicated lua for etnasy.gg')

        self.aa.override = self.tab.home:checkbox(' enable anti-aim')
        self.aa.setting_type = self.tab.home:combo(' anti-aim mode', '» disabled', '» presets', '» custom')
        self.aa.setting_main = self.tab.home:combo(' setting type ', '» additions', '» tweaks', '» configs')
        self.aa.manual = self.tab.home:checkbox(' manual direction')
        self.aa.duck_exploit = self.tab.home:checkbox('» duck exploit')
        self.aa.manual_auto_reset = self.tab.home:checkbox('» auto reset')
        self.aa.manual_left = self.tab.home:keybind('» left direction')
        self.aa.manual_back = self.tab.home:keybind('» back direction')
        self.aa.manual_right = self.tab.home:keybind('» right direction')
        self.aa.manual_forward = self.tab.home:keybind('» forward direction')
        self.aa.import = self.tab.home:button('           import settings from clipboard             ')
        self.aa.export = self.tab.home:button('             export settings to clipboard                ')
        self.aa.fast_ladder = self.tab.home:checkbox(' fast ladder move')
        self.aa.avoid_backstab = self.tab.home:checkbox(' avoid backstab')
        self.aa.no_fall_damage = self.tab.home:checkbox(' no fall damage')
        self.aa.safe_head = self.tab.home:checkbox(' safe head')
        self.aa.safe_head_conds = self.tab.home:multicombo('» conditions', '» air melee', '» height difference')
 
        self.aa.preset = self.tab.main:combo(' active preset', '» aggressive', '» meta')
        self.aa.preset_text = self.tab.main:label('you are using an anti-aim preset\neverything is set up. enjoy!')
        self.aa.condition = self.tab.main:combo(' current condition', unpack(main.conditions))
        self.builder = {
            [0] = function(self)
                for i = 1, #main.conditions do
                    local cond = main.short_conditions[i]
                    if not self.builder[i] then self.builder[i] = {} end
                    local ctx = self.builder[i]

                    ctx.override = self.tab.main:checkbox(string.format('override %s condition', main.conditions[i]))
                    ctx.yaw_add_degree = self.tab.main:slider_int(cond..'yaw add', -180, 180, 0, "%dº%")
                    ctx.yaw_modifier = self.tab.main:combo(cond..'yaw modifier', '» disabled', '» jitter', '» delayed', '» random', '» x-way')
                    ctx.way_count = self.tab.main:slider_int(cond..'way count', 3, 7, 3, "%d-way%")
                    ctx.way_deg = {
                        [1] = self.tab.main:slider_int(cond..'1st-way degree', -180, 180, 0, "%dº%"),
                        [2] = self.tab.main:slider_int(cond..'2nd-way degree', -180, 180, 0, "%dº%"),
                        [3] = self.tab.main:slider_int(cond..'3rd-way degree', -180, 180, 0, "%dº%"),
                        [4] = self.tab.main:slider_int(cond..'4th-way degree', -180, 180, 0, "%dº%"),
                        [5] = self.tab.main:slider_int(cond..'5th-way degree', -180, 180, 0, "%dº%"),
                        [6] = self.tab.main:slider_int(cond..'6th-way degree', -180, 180, 0, "%dº%"),
                        [7] = self.tab.main:slider_int(cond..'7th-way degree', -180, 180, 0, "%dº%")
                    }
                    ctx.delay_tick = self.tab.main:slider_int(cond..'delay tick', 3, 16, 3, "%dt%")
                    ctx.modifier_left = self.tab.main:slider_int(cond..'modifier left', -180, 180, 0, "%dº%")
                    ctx.modifier_right = self.tab.main:slider_int(cond..'modifier right', -180, 180, 0, "%dº%")
                    ctx.body_options = self.tab.main:combo(cond..'body options', '» disabled', '» opposite', '» jitter')
                    ctx.fake_yaw_limit = self.tab.main:slider_int(cond..'body yaw', -58, 58, 0, "%dº%")
                    ctx.left_fake_yaw_limit = self.tab.main:slider_int(cond..'left body yaw', 0, 58, 0, "%dº%")
                    ctx.right_fake_yaw_limit = self.tab.main:slider_int(cond..'right body yaw', 0, 58, 0, "%dº%")
                    ctx.defensive_shift = self.tab.main:combo(cond..'lag options', '» default', '» delayed', '» always on')
                    ctx.defensive_ticks = self.tab.main:slider_int(cond..'lag delay', 3, 16, 3, "%dt%")
                    ctx.defensive_yaw = self.tab.main:combo(cond..'defensive yaw', '» disabled', '» opposite', '» sideways', '» spin', '» custom jitter')
                    ctx.custom_defensive_yaw = self.tab.main:slider_int(cond..'defensive yaw deg', -180, 180, 90)
                    ctx.defensive_spin_limit = self.tab.main:slider_int(cond..'defensive spin limit', 0, 360, 360)
                    ctx.defensive_pitch = self.tab.main:combo(cond..'defensive pitch', '» disabled', '» up', '» down', '» zero', '» custom', '» custom jitter')
                    ctx.custom_defensive_pitch = self.tab.main:slider_int(cond..'defensive pitch deg', -89, 89, 89)
                    
                end
            end
        }; self.builder[0](self)
        self.visual.optimization = self.tab.home:multicombo(' optimization', '» no glow')

        self.visual.enable_indicators = self.tab.main:checkbox(' crosshair indicators')
        self.visual.indicators_color = self.tab.main:color_picker(' crosshair indicators', color(255, 255, 255, 85))
        self.visual.indicators_mode = self.tab.main:combo('» indicators style', '» classic', '» renewed')
        self.visual.damage_shower = self.tab.main:checkbox(' damage shower')
        self.visual.manual_arrows = self.tab.main:checkbox(' manual arrows')
        self.visual.manual_arrows_color = self.tab.main:color_picker(' manual arrows', color(255, 255, 255, 255))
        self.visual.manual_arrows_mode = self.tab.main:combo('» arrows style', '» default', '» renewed')
        self.visual.manual_arrows_yadd = self.tab.main:slider_int("» distance", 0, 85, 0, "%dº%")
        self.visual.kibitmarker = self.tab.main:checkbox(' kibit hitmarker')
        self.visual.kibitmarker_color = self.tab.main:color_picker(' kibit hitmarker', color(255, 255, 255, 255))
        self.visual.kibitmarker_mode = self.tab.main:combo('» hitmarket style', '» circle', '» plus')
        self.visual.logs = self.tab.main:checkbox(' event logging')
        self.visual.logs_color = self.tab.main:color_picker(' event logging', color(255, 255, 255, 85))
        self.visual.custom_scope = self.tab.main:checkbox(' custom scope')
        self.visual.custom_scope_t_style = self.tab.main:checkbox(' » t style')
        self.visual.custom_scope_color = self.tab.main:color_picker(' custom scope', color(255, 255, 255, 255))
        self.visual.overlay_position = self.tab.main:slider_int(' » scope lines initial', 0, 500, 190)
        self.visual.overlay_offset = self.tab.main:slider_int(' » scope lines offset', 0, 500, 15)
        self.visual.fade_time = self.tab.main:slider_int(' » fade animation speed', 3, 20, 12)
        self.visual.slowed_down = self.tab.main:checkbox(' slowed down')
        self.visual.slowed_down_style = self.tab.main:combo('» slowed down style', '» renewed', '» default')
        self.visual.notifyx_x = self.tab.main:checkbox(' notification')
        self.visual.notify_condition = self.tab.main:multicombo('» notify options', '» on hit', '» on miss', '» renewed style')
        self.visual.enable_interface = self.tab.main:checkbox(' interface')
        self.visual.interface_color = self.tab.main:color_picker(' interface', color(142, 165, 229, 85))
        self.visual.interface_additional = self.tab.main:multicombo('» panels', '» watermark', '» keybinds', '» info-panel', '» io/hz', '» defensive choke')
        self.visual.interface_mode = self.tab.main:combo('» interface mode', '» default', '» fade')
        self.visual.interface_panelposition = self.tab.main:combo('» info-panel position', '» left', '» right', '» bottom')

        self.misc.enable_animbreaker = self.tab.main:checkbox(' animation breaker')
        self.misc.animations_mode = self.tab.main:combo('» animation in move', '» default', '» moonwalk', '» jitter model', '» static')
        self.misc.animations_mode_air = self.tab.main:combo('» animation in air', '» default', '» moonwalk in air', '» jitter model in air', '» static')
        self.misc.enable_clantag = self.tab.main:checkbox(' clantag spammer')
        self.misc.enable_trashtalk = self.tab.main:checkbox(' killsay')
    end,
    visibility = function(self)
        self.home.welcome_text:visible(self.navigation:get() == 0)

        self.aa.override:visible(self.navigation:get() == 1)
        self.aa.setting_main:visible(self.navigation:get() == 1 and self.aa.override:get())
        self.aa.setting_type:visible(self.navigation:get() == 1 and self.aa.override:get())
        self.aa.manual:visible(self.navigation:get() == 1 and self.aa.override:get() and self.aa.setting_main:get() == 0)
        self.aa.manual_auto_reset:visible(self.navigation:get() == 1 and self.aa.override:get() and self.aa.setting_main:get() == 0 and self.aa.manual:get())
        self.aa.duck_exploit:visible(self.navigation:get() == 1 and self.aa.override:get() and self.aa.setting_main:get() == 0 and self.aa.manual:get())
        self.aa.manual_left:visible(self.navigation:get() == 1 and self.aa.override:get() and self.aa.setting_main:get() == 0 and self.aa.manual:get())
        self.aa.manual_back:visible(self.navigation:get() == 1 and self.aa.override:get() and self.aa.setting_main:get() == 0 and self.aa.manual:get())
        self.aa.manual_right:visible(self.navigation:get() == 1 and self.aa.override:get() and self.aa.setting_main:get() == 0 and self.aa.manual:get())
        self.aa.manual_forward:visible(self.navigation:get() == 1 and self.aa.override:get() and self.aa.setting_main:get() == 0 and self.aa.manual:get())
        self.aa.import:visible(self.navigation:get() == 1 and self.aa.override:get() and self.aa.setting_main:get() == 2)
        self.aa.export:visible(self.navigation:get() == 1 and self.aa.override:get() and self.aa.setting_main:get() == 2)
        self.aa.fast_ladder:visible(self.navigation:get() == 1 and self.aa.override:get() and self.aa.setting_main:get() == 1)
        self.aa.avoid_backstab:visible(self.navigation:get() == 1 and self.aa.override:get() and self.aa.setting_main:get() == 1)
        self.aa.no_fall_damage:visible(self.navigation:get() == 1 and self.aa.override:get() and self.aa.setting_main:get() == 1)
        self.aa.safe_head:visible(self.navigation:get() == 1 and self.aa.override:get() and self.aa.setting_main:get() == 1)
        self.aa.safe_head_conds:visible(self.navigation:get() == 1 and self.aa.override:get() and self.aa.setting_main:get() == 1 and self.aa.safe_head:get())
        self.aa.preset:visible(self.navigation:get() == 1 and self.aa.override:get() and self.aa.setting_type:get() == 1)
        self.aa.preset_text:visible(self.navigation:get() == 1 and self.aa.override:get() and self.aa.setting_type:get() == 1)
        self.aa.condition:visible(self.navigation:get() == 1 and self.aa.override:get() and self.aa.setting_type:get() == 2)
        for i = 1, #main.conditions do
            local main_cond = self.navigation:get() == 1 and self.aa.override:get() and self.aa.setting_type:get() == 2 and self.aa.condition:get()+1 == i and (self.builder[i].override:get() or self.aa.condition:get() == 0)
            self.builder[i].override:visible(self.navigation:get() == 1 and self.aa.override:get() and self.aa.setting_type:get() == 2 and self.aa.condition:get()+1 == i and self.aa.condition:get() ~= 0)
            self.builder[i].yaw_add_degree:visible(main_cond)
            self.builder[i].yaw_modifier:visible(main_cond)
            self.builder[i].way_count:visible(main_cond and self.builder[i].yaw_modifier:get() == 4)
            for idx, obj in pairs(self.builder[i].way_deg) do
                obj:visible(main_cond and self.builder[i].yaw_modifier:get() == 4 and self.builder[i].way_count:get() >= tonumber(idx))
            end
            self.builder[i].delay_tick:visible(main_cond and self.builder[i].yaw_modifier:get() == 2)
            self.builder[i].modifier_left:visible(main_cond and (self.builder[i].yaw_modifier:get() == 2 or self.builder[i].yaw_modifier:get() == 1 or self.builder[i].yaw_modifier:get() == 3))
            self.builder[i].modifier_right:visible(main_cond and (self.builder[i].yaw_modifier:get() == 2 or self.builder[i].yaw_modifier:get() == 1 or self.builder[i].yaw_modifier:get() == 3))
            self.builder[i].body_options:visible(main_cond)
            self.builder[i].fake_yaw_limit:visible(main_cond and self.builder[i].body_options:get() == 1)
            self.builder[i].left_fake_yaw_limit:visible(main_cond and self.builder[i].body_options:get() == 2)
            self.builder[i].right_fake_yaw_limit:visible(main_cond and self.builder[i].body_options:get() == 2)
            self.builder[i].defensive_shift:visible(main_cond)
            self.builder[i].defensive_ticks:visible(main_cond and self.builder[i].defensive_shift:get() == 1)
            self.builder[i].defensive_yaw:visible(main_cond)
            self.builder[i].custom_defensive_yaw:visible(main_cond and self.builder[i].defensive_yaw:get() == 4)
            self.builder[i].defensive_spin_limit:visible(main_cond and self.builder[i].defensive_yaw:get() == 3)
            self.builder[i].defensive_pitch:visible(main_cond)
            self.builder[i].custom_defensive_pitch:visible(main_cond and (self.builder[i].defensive_pitch:get() == 4 or self.builder[i].defensive_pitch:get() == 5))
        end

        self.visual.optimization:visible(self.navigation:get() == 2)
        self.visual.enable_interface:visible(self.navigation:get() == 2)
        self.visual.manual_arrows:visible(self.navigation:get() == 2)
        self.visual.manual_arrows_yadd:visible(self.navigation:get() == 2 and self.visual.manual_arrows:get())
        self.visual.manual_arrows_mode:visible(self.navigation:get() == 2 and self.visual.manual_arrows:get())
        self.visual.slowed_down_style:visible(self.navigation:get() == 2 and self.visual.slowed_down:get())
        self.visual.slowed_down:visible(self.navigation:get() == 2)
        self.visual.interface_color:visible(self.navigation:get() == 2 and self.visual.enable_interface:get())
        self.visual.interface_additional:visible(self.navigation:get() == 2 and self.visual.enable_interface:get())
        self.visual.interface_mode:visible(self.navigation:get() == 2 and self.visual.enable_interface:get())
        self.visual.interface_panelposition:visible(self.navigation:get() == 2 and self.visual.enable_interface:get() and self.visual.interface_additional:get(2))
        self.visual.enable_indicators:visible(self.navigation:get() == 2)
        self.visual.indicators_mode:visible(self.navigation:get() == 2 and self.visual.enable_indicators:get())
        self.visual.damage_shower:visible(self.navigation:get() == 2)
        self.visual.logs:visible(self.navigation:get() == 2)
        self.visual.custom_scope:visible(self.navigation:get() == 2)
        self.visual.custom_scope_t_style:visible(self.navigation:get() == 2 and self.visual.custom_scope:get())
        self.visual.overlay_position:visible(self.navigation:get() == 2 and self.visual.custom_scope:get())
        self.visual.overlay_offset:visible(self.navigation:get() == 2 and self.visual.custom_scope:get())
        self.visual.fade_time:visible(self.navigation:get() == 2 and self.visual.custom_scope:get())
        self.visual.notifyx_x:visible(self.navigation:get() == 2)
        self.visual.notify_condition:visible(self.navigation:get() == 2 and self.visual.notifyx_x:get())
        self.visual.kibitmarker:visible(self.navigation:get() == 2)
        self.visual.kibitmarker_mode:visible(self.navigation:get() == 2 and self.visual.kibitmarker:get())

        self.misc.enable_animbreaker:visible(self.navigation:get() == 3)
        self.misc.animations_mode:visible(self.navigation:get() == 3 and self.misc.enable_animbreaker:get())
        self.misc.animations_mode_air:visible(self.navigation:get() == 3 and self.misc.enable_animbreaker:get())

        self.misc.enable_clantag:visible(self.navigation:get() == 3)
        self.misc.enable_trashtalk:visible(self.navigation:get() == 3)
         end,
}; menu:elements();
local renderer = {}; do
    renderer.rounded_shadow = function(from, to, color, r, size)
        if menu.visual.optimization:get(0) then return end
        if color.a ~= 0 then
            for i = 1, size do
                render.rect(from - vector(i*2, i*2 - 1), to + vector(i*2, i*2), color:alp_self((size - i) / size), r + i*2)
            end
        end
    end
end
local _json={_version="0.1.2"}local b;local c={["\\"]="\\",["\""]="\"",["\b"]="b",["\f"]="f",["\n"]="n",["\r"]="r",["\t"]="t"}local d={["/"]="/"}for e,f in pairs(c)do d[f]=e end;local function g(h)return"\\"..(c[h]or string.format("u%04x",h:byte()))end;local function i(j)return"null"end;local function k(j,l)local m={}l=l or{}if l[j]then error("circular reference")end;l[j]=true;if rawget(j,1)~=nil or next(j)==nil then local n=0;for e in pairs(j)do if type(e)~="number"then error("invalid table: mixed or invalid key types")end;n=n+1 end;if n~=#j then error("invalid table: sparse array")end;for o,f in ipairs(j)do table.insert(m,b(f,l))end;l[j]=nil;return"["..table.concat(m,",").."]"else for e,f in pairs(j)do if type(e)~="string"then error("invalid table: mixed or invalid key types")end;table.insert(m,b(e,l)..":"..b(f,l))end;l[j]=nil;return"{"..table.concat(m,",").."}"end end;local function p(j)return'"'..j:gsub('[%z\1-\31\\"]',g)..'"'end;local function q(j)if j~=j or j<=-math.huge or j>=math.huge then error("unexpected number value '"..tostring(j).."'")end;return string.format("%.14g",j)end;local r={["nil"]=i,["table"]=k,["string"]=p,["number"]=q,["boolean"]=tostring}b=function(j,l)local s=type(j)local t=r[s]if t then return t(j,l)end;error("unexpected type '"..s.."'")end;function _json.encode(j)return b(j)end;local u;local function v(...)local m={}for o=1,select("#",...)do m[select(o,...)]=true end;return m end;local w=v(" ","\t","\r","\n")local x=v(" ","\t","\r","\n","]","}",",")local y=v("\\","/",'"',"b","f","n","r","t","u")local z=v("true","false","null")local A={["true"]=true,["false"]=false,["null"]=nil}local function B(C,D,E,F)for o=D,#C do if E[C:sub(o,o)]~=F then return o end end;return#C+1 end;local function G(C,D,H)local I=1;local J=1;for o=1,D-1 do J=J+1;if C:sub(o,o)=="\n"then I=I+1;J=1 end end;error(string.format("%s at line %d col %d",H,I,J))end;local function K(n)local t=math.floor;if n<=0x7f then return string.char(n)elseif n<=0x7ff then return string.char(t(n/64)+192,n%64+128)elseif n<=0xffff then return string.char(t(n/4096)+224,t(n%4096/64)+128,n%64+128)elseif n<=0x10ffff then return string.char(t(n/262144)+240,t(n%262144/4096)+128,t(n%4096/64)+128,n%64+128)end;error(string.format("invalid unicode codepoint '%x'",n))end;local function L(M)local N=tonumber(M:sub(1,4),16)local O=tonumber(M:sub(7,10),16)if O then return K((N-0xd800)*0x400+O-0xdc00+0x10000)else return K(N)end end;local function P(C,o)local m=""local Q=o+1;local e=Q;while Q<=#C do local R=C:byte(Q)if R<32 then G(C,Q,"control character in string")elseif R==92 then m=m..C:sub(e,Q-1)Q=Q+1;local h=C:sub(Q,Q)if h=="u"then local S=C:match("^[dD][89aAbB]%x%x\\u%x%x%x%x",Q+1)or C:match("^%x%x%x%x",Q+1)or G(C,Q-1,"invalid unicode escape in string")m=m..L(S)Q=Q+#S else if not y[h]then G(C,Q-1,"invalid escape char '"..h.."' in string")end;m=m..d[h]end;e=Q+1 elseif R==34 then m=m..C:sub(e,Q-1)return m,Q+1 end;Q=Q+1 end;G(C,o,"expected closing quote for string")end;local function T(C,o)local R=B(C,o,x)local M=C:sub(o,R-1)local n=tonumber(M)if not n then G(C,o,"invalid number '"..M.."'")end;return n,R end;local function U(C,o)local R=B(C,o,x)local V=C:sub(o,R-1)if not z[V]then G(C,o,"invalid literal '"..V.."'")end;return A[V],R end;local function W(C,o)local m={}local n=1;o=o+1;while 1 do local R;o=B(C,o,w,true)if C:sub(o,o)=="]"then o=o+1;break end;R,o=u(C,o)m[n]=R;n=n+1;o=B(C,o,w,true)local X=C:sub(o,o)o=o+1;if X=="]"then break end;if X~=","then G(C,o,"expected ']' or ','")end end;return m,o end;local function Y(C,o)local m={}o=o+1;while 1 do local Z,j;o=B(C,o,w,true)if C:sub(o,o)=="}"then o=o+1;break end;if C:sub(o,o)~='"'then G(C,o,"expected string for key")end;Z,o=u(C,o)o=B(C,o,w,true)if C:sub(o,o)~=":"then G(C,o,"expected ':' after key")end;o=B(C,o+1,w,true)j,o=u(C,o)m[Z]=j;o=B(C,o,w,true)local X=C:sub(o,o)o=o+1;if X=="}"then break end;if X~=","then G(C,o,"expected '}' or ','")end end;return m,o end;local _={['"']=P,["0"]=T,["1"]=T,["2"]=T,["3"]=T,["4"]=T,["5"]=T,["6"]=T,["7"]=T,["8"]=T,["9"]=T,["-"]=T,["t"]=U,["f"]=U,["n"]=U,["["]=W,["{"]=Y}u=function(C,D)local X=C:sub(D,D)local t=_[X]if t then return t(C,D)end;G(C,D,"unexpected character '"..X.."'")end;function _json.decode(C)if type(C)~="string"then error("expected argument of type string, got "..type(C))end;local m,D=u(C,B(C,1,w,true))D=B(C,D,w,true)if D<=#C then G(C,D,"trailing garbage")end;return m end
local native_GetGameDirectory = vtable_bind("engine.dll", "VEngineClient014", 36, "const char*(__thiscall*)(void*)")
local getGameDirectory = function() return tostring(ffi.string(native_GetGameDirectory())):gsub('\\csgo', '') end
ffi.cdef[[
    bool CreateDirectoryA(const char* lpPathName, void* lpSecurityAttributes);
    bool DeleteUrlCacheEntryA(const char* lpszUrlName);
    void* __stdcall URLDownloadToFileA(void* LPUNKNOWN, const char* LPCSTR, const char* LPCSTR2, int a, int LPBINDSTATUSCALLBACK);
    int CreateDirectoryA(const char*, void*);
    void* CreateFileA(const char*, uintptr_t, uintptr_t, void*, uintptr_t, uintptr_t, void*);
    uintptr_t GetFileSize(void*, uintptr_t*);
    int ReadFile(void*, void*, uintptr_t, uintptr_t*, void*);
    int CloseHandle(void*);
]]
local cfg_settings = {}
local is_ZALUPA_executing = false
local is_custom_zalupa = false
local is_PARASHA_executing = false
local config_frequency = 0
local exec_import = function(cfg)
    is_ZALUPA_executing = true
    is_custom_zalupa = cfg
end
utils.re_cast = function(sModuleName, sFunctionName, sTypeOf)
    local typedefed = ffi.typeof(sTypeOf)
    return function(...)
        return ffi.cast(typedefed, jmp_hook)(native.fnGetProcAddress(native.pGetProcAddress, 0, native.fnGetModuleHandle(native.pGetModuleHandle, 0, sModuleName), sFunctionName), 0, ...)
    end
end

local pLpDevMode = ffi.new("struct { char pad_0[120]; unsigned long dmDisplayFrequency; char pad_2[32]; }[1]"); utils.re_cast("user32.dll", "EnumDisplaySettingsA", "int(__fastcall*)(unsigned int, unsigned int, unsigned int, unsigned long, void*)")(0, 4294967295, pLpDevMode[0])
main.hz = pLpDevMode[0].dmDisplayFrequency or 0 

math.lerp = function(a, b, percentage)
    return a + (b - a) * percentage
end
math.anim = function(a, b, speed)
    return math.lerp(a, b, globals.frametime * (speed or 8))
end
math.calcangle = function(localplayerxpos, localplayerypos, enemyxpos, enemyypos)
    local relativeyaw = math.atan( (localplayerypos - enemyypos) / (localplayerxpos - enemyxpos) )
    return relativeyaw * 180 / math.pi
end
math.angle_vector = function(angle_x, angle_y)
    local sy = math.sin(math.rad(angle_y));
    local cy = math.cos(math.rad(angle_y));
    local sp = math.sin(math.rad(angle_x));
    local cp = math.cos(math.rad(angle_x));
    return cp * cy, cp * sy, -sp;
end
math.extrapolate = function(player, ticks, origin)
    local vel_x, vel_y, vel_z = player['m_vecVelocity[0]'], player['m_vecVelocity[1]'], player['m_vecVelocity[2]']
    local new_x = origin.x + globals.tickinterval * vel_x * ticks
    local new_y = origin.y + globals.tickinterval * vel_y * ticks
    local new_z = origin.z + globals.tickinterval * vel_z * ticks
    return vector(new_x, new_y, new_z)
end
utils.get_date = function()
    local time_t = ffi.new("SYSTEMTIME");
    kernel32.GetLocalTime(time_t);
    return time_t
end
utils.in_bounds = function(pos_a, pos_b, point)
    return point.x > pos_a.x and point.y > pos_a.y and point.x < pos_b.x and point.y < pos_b.y
end
utils.set_window_name = function(name)
    if globals.is_in_game then return end
    utils.hwnd = ffi.C.GetForegroundWindow()
    ffi.C.SetWindowTextA(utils.hwnd, tostring(name))
end
local keybinds_callback_table = {}
utils.set_keybind_callback = function(obj, func)
    if obj:type() ~= 3 then print(string.format('object is not a keybind [%s]', obj:get_name())) return end
    table.insert(keybinds_callback_table, {
        name = obj:get_name(),
        obj = obj,
        callback = func,
        pressed = false,
        unpressed = false,
        update = function(self)
            local current = self
            local key = obj:get_key()
            local mode = obj:get_mode()

            if mode == 1 then
                if not utils.is_key_pressed(key) and current.pressed then
                    current.unpressed = true
                end
                if utils.is_key_pressed(key) and not current.pressed and not current.unpressed and current.obj:get() then
                    current.pressed = true
                    current.callback(obj:get())
                end
                if utils.is_key_pressed(key) and current.pressed and current.unpressed then
                    current.pressed = false
                    current.callback(obj:get())
                end
                if not utils.is_key_pressed(key) and not current.pressed then
                    current.unpressed = false
                end
            elseif mode == 0 then
                if utils.is_key_pressed(key) then
                    current.callback(true)
                    current.pressed = true
                else
                    current.pressed = false
                end
            else
                current.callback(true)
                current.pressed = true
            end
        end
    })
end
table.contains = function(tbl, element)
    for k, v in pairs(tbl) do
        if v == element then return true end
    end
    return false
end
entity.get_players = function(f)
    for i = 1, globals.max_players do
        if entity.get(i) then
            f(entity.get(i))
        end
    end
end
local enchantedTextEffect = function(font, x, y, clr, glow_color, flags, txt, speed)
    local chars_x = 0
    local len = txt:len() - 1
    for i = 1, len + 1 do
        local text_sub = string.sub(txt, i, i)
        local text_size = render.measure_text(font, text_sub)
        local color_glowing = clr:lerp(glow_color, math.abs(math.sin((globals.realtime - (i * 0.02)) * speed)))
        render.text(font, vector(x + chars_x, y), color_glowing, flags, text_sub)

        chars_x = chars_x + text_size.x
    end
end
local netchannel = {}
netchannel.pflFrameTimeStdDeviation = ffi.new("float[1]")
netchannel.pflFrameStartTimeStdDeviation = ffi.new("float[1]")
netchannel.netc_bool = ffi.typeof("bool(__thiscall*)(void*)")
netchannel.netc_bool2 = ffi.typeof("bool(__thiscall*)(void*, int, int)")
netchannel.netc_float = ffi.typeof("float(__thiscall*)(void*, int)")
netchannel.netc_int = ffi.typeof("int(__thiscall*)(void*, int)")
netchannel.net_fr_to = ffi.typeof("void(__thiscall*)(void*, float*, float*, float*)")
netchannel.rawivengineclient = utils.create_interface("engine.dll", "VEngineClient014") or error("VEngineClient014 wasnt found", 2)
netchannel.ivengineclient = ffi.cast(ffi.typeof('void***'), netchannel.rawivengineclient) or error("rawivengineclient is nil", 2)
netchannel.get_net_channel_info = ffi.cast("void*(__thiscall*)(void*)", netchannel.ivengineclient[0][78]) or error("ivengineclient is nil")
netchannel.slv_is_ingame_t = ffi.cast("bool(__thiscall*)(void*)", netchannel.ivengineclient[0][26]) or error("is_in_game is nil")
netchannel.pflFrameTime = ffi.new("float[1]")
netchannel.get = function()
    local INetChannelInfo = ffi.cast("void***", netchannel.get_net_channel_info(netchannel.ivengineclient)) or error("netchaninfo is nil")
    if INetChannelInfo == nil then return end
    local seqNr_out = ffi.cast(netchannel.netc_int, INetChannelInfo[0][17])(INetChannelInfo, 1)
    return {
        seqNr_out = seqNr_out,
        is_loopback = ffi.cast(netchannel.netc_bool, INetChannelInfo[0][6])(INetChannelInfo),
        is_timing_out = ffi.cast(netchannel.netc_bool, INetChannelInfo[0][7])(INetChannelInfo),
        latency = {
            crn = function(flow) return ffi.cast(netchannel.netc_float, INetChannelInfo[0][9])(INetChannelInfo, flow) end,
            average = function(flow) return ffi.cast(netchannel.netc_float, INetChannelInfo[0][10])(INetChannelInfo, flow) end,
        },
        loss = ffi.cast(netchannel.netc_float, INetChannelInfo[0][11])(INetChannelInfo, 1),
        choke = ffi.cast(netchannel.netc_float, INetChannelInfo[0][12])(INetChannelInfo, 1),
        got_bytes = ffi.cast(netchannel.netc_float, INetChannelInfo[0][13])(INetChannelInfo, 1),
        sent_bytes = ffi.cast(netchannel.netc_float, INetChannelInfo[0][13])(INetChannelInfo, 0),
        is_valid_packet = ffi.cast(netchannel.netc_bool2, INetChannelInfo[0][18])(INetChannelInfo, 1, seqNr_out-1),
    }
end
netchannel.get_framerate = function()
    local INetChannelInfo = ffi.cast("void***", netchannel.get_net_channel_info(netchannel.ivengineclient)) or error("netchaninfo is nil")
    if INetChannelInfo == nil then return 0, 0 end
    local server_var = 0
    local server_framerate = 0
    ffi.cast(netchannel.net_fr_to, INetChannelInfo[0][25])(INetChannelInfo, netchannel.pflFrameTime, netchannel.pflFrameTimeStdDeviation, netchannel.pflFrameStartTimeStdDeviation)
    if netchannel.pflFrameTime ~= nil and netchannel.pflFrameTimeStdDeviation ~= nil and netchannel.pflFrameStartTimeStdDeviation ~= nil then
        if netchannel.pflFrameTime[0] > 0 then
            server_var = netchannel.pflFrameStartTimeStdDeviation[0] * 1000
            server_framerate = netchannel.pflFrameTime[0] * 1000
        end
    end
    return server_framerate, server_var
end
local function get_cond(ret)
    if not ret then ret = false end
    if not globals.is_in_game and not entity.get_local_player():is_alive() then return end
    local slowWalkBind = ui.find("Anti aim", "Other", "Slow walk")
    local m_hGroundEntity = entity.get_local_player()['m_hGroundEntity']
    local duck = entity.get_local_player()['m_bDucked']
    local first_velocity = entity.get_local_player()['m_vecVelocity[0]']
    local second_velocity = entity.get_local_player()['m_vecVelocity[1]']
    local velocity = math.floor(math.sqrt(first_velocity*first_velocity+second_velocity*second_velocity))
    if m_hGroundEntity == -1 and duck == true then
        return (ret and 7 or "*aero-crouch*")
    elseif m_hGroundEntity == -1 then
        return (ret and 5 or "*aero*")
    elseif m_hGroundEntity ~= -1 and duck == true then
        return (ret and 6 or "*crouch*")
    elseif m_hGroundEntity ~= -1 and velocity > 5 then
        if not slowWalkBind:get(3) then
            return (ret and 3 or "*move*")
        else
            return (ret and 4 or "*slow*")
        end
    elseif m_hGroundEntity ~= -1 and velocity < 5 then
        return (ret and 2 or "*stand*")
    else
        return ret and 1 or " "
    end
end
math.clamp = function(min, max, val)
    return math.max(min, math.min(max, val))
end
local clamp = function(v, min, max) local num = v; num = num < min and min or num; num = num > max and max or num; return num end

local function linear(t, b, c, d)
    return c * t / d + b
end

local last_side = -1
local function get_side()
    if globals.choked_commands ~= 0 then
        local lp = entity.get_local_player()
        if not lp or not lp:is_alive() then return end

        last_side = (lp['m_flPoseParameter'][11]*120-60+0.5) > 0 and -1 or 1
    end
    return last_side
end
local animation = { alpha = 0, alpha1 = 0, anim = 0 }

local draggable = {}
function draggable:new(name, start_pos, region_size)
    start_pos = start_pos or vector(100, 100)
    local new_drag = {
        name = name,
        start_pos = start_pos,
        region_size = region_size or vector(100, 100),
        x = ui.find("Config", "Config"):slider_int(name .. "_x", 0, main.screen_size.x, start_pos.x),
        y = ui.find("Config", "Config"):slider_int(name .. "_y", 0, main.screen_size.y, start_pos.y),
        captured = false,
        clicked = false,
        mouse_offset = vector(0, 0)
    }
    new_drag.x:visible(false)
    new_drag.y:visible(false)
    setmetatable(new_drag, self)
    self.__index = self
    return new_drag
end
function draggable:get()
    return vector(self.x:get(), self.y:get())
end
function draggable:set(x, y)
    if x ~= nil then
        self.x:set(x)
    end
    if y ~= nil then
        self.y:set(y)
    end
end
local bg_color_anim = 0
local bg_alpha_anim = 0
local is_rendering_rect = false
function draggable:update(region_size, lock_x)
    if not ui.is_open() then self.captured = false self.clicked = false end
    if region_size ~= nil then self.region_size = region_size end
    if lock_x == nil then lock_x = false end
    if self.captured then
        bg_alpha_anim = math.lerp(bg_alpha_anim, 100, 2 * globals.frametime)
        bg_color_anim = math.clamp(0, 255, math.lerp(bg_color_anim, -62, 2.5 * globals.frametime))
    else
        bg_alpha_anim = math.lerp(bg_alpha_anim, 0, 1 * globals.frametime)
        bg_color_anim = math.lerp(bg_color_anim, 45, 1 * globals.frametime)
    end
    is_rendering_rect = true

    if math.floor(bg_alpha_anim) <= 5 then
        is_rendering_rect = false
    end
    if utils.is_key_pressed(0x1) then
        local cur_pos = self:get()
        local mouse_pos = utils.get_mouse_position()
        if not self.clicked then
            self.clicked = true
            if utils.in_bounds(cur_pos, cur_pos + self.region_size, mouse_pos) then
                self.captured = true 
                self.mouse_offset = mouse_pos - cur_pos 
            end
        end

        if self.captured then
            self.x:set(type(lock_x) == 'boolean' and mouse_pos.x - self.mouse_offset.x or lock_x)
            self.y:set(mouse_pos.y - self.mouse_offset.y)
        end
    else
        self.captured = false
        self.clicked = false
    end
end
client.add_callback("render", function()
    if is_rendering_rect then render.rect(main.screen_size, vector(0, 0), color(bg_color_anim, bg_color_anim, bg_color_anim, bg_alpha_anim)) end
end)
local fonts = {
    verdana = render.load_font("Verdana", 12, "a"),
    pixel = render.load_font("Smallest Pixel-7", 11, "a"),
    verdana_bold = render.load_font("Verdana", 11, "ab"),
    verdana_bold2 = render.load_font("Verdana Bold", 12, 'ab'),
    acta_symols = render.load_font("ActaSymbolsW95-Arrows", 18, "a"),
    acta_symols_low = render.load_font("ActaSymbolsW95-Arrows", 12, "a"),
    verdana_arrows = render.load_font("Verdana", 22, "")
}

local drag_logs = draggable:new("logs", vector(main.screen_size.x/2 - 100, main.screen_size.y/2+300), vector(400, 100))
_G.angelwave_push=(function()
	_G.angelwave_notify_cache={}
	local a={callback_registered=false,maximum_count=4}
	local b=color(255,255,255,255)

	function a:set_callback()
		if self.callback_registered then return end;
		client.add_callback("render", function()
			local c={render.screen_size()}
			local d={0,0,0}
			local e=1;
			local f=_G.angelwave_notify_cache;
			for g=#f,1,-1 do
				_G.angelwave_notify_cache[g].time=_G.angelwave_notify_cache[g].time-globals.frametime
				local h,i=255,0;
				local i2 = 0;
				local lerpy = 150;
				local lerp_circ = 0.5;
				local j=f[g]
				if j.time<0 then
					table.remove(_G.angelwave_notify_cache,g)
				else
					local k=j.def_time-j.time;
					local k=k>1 and 1 or k;
				if j.time<1 or k<1 then
					i=(k<1 and k or j.time)/1;
					i2=(k<1 and k or j.time)/1;
					h=i*255;
					lerpy=i*150;
					lerp_circ=i*0.5
				if i<0.2 then
					e=e+16*(1.0-i/0.2)
				end
			end;

			local l={b}
			local m={math.floor(render.measure_text(1,"[etnasy.gg]  "..j.draw).x *1.03)}
			local n={render.measure_text(1,"[etnasy.gg]  ").x}
            local m1={math.floor(render.measure_text(1,"⚠"..j.draw).x *1.03)}
			local n1={render.measure_text(1,"⚠").x}
			local o={render.measure_text(1, j.draw).x}
			local p={render.screen_size().x /2 - m[1]/2 +3, 13.4 -e}
            local p1={render.screen_size().x /2 - m1[1]/2 +3, 13.4 -e}
			local x = render.screen_size().x
            local y = render.screen_size().y
            local posw = vector(drag_logs:get().x, drag_logs:get().y+30)
            drag_logs:update(nil, main.screen_size.x/2 - 200)
        
           if menu.visual.notify_condition:get(2) then
            --[[
            for i = 1, 5 do
                render.rect(vector(p1[1]-1,p1[2]-16 + posw.y - i), vector(p1[1]+ 1+m1[1], p1[2] + 6 + posw.y +i), color(255,60,17,30 - (2 * i)))
                render.push_clip_rect(vector(p1[1]-1,p1[2]+20+ posw.y), vector(p1[1]-15,p1[2] - 20+ posw.y))
                render.circle(vector(p1[1]-1,p1[2]-5 + posw.y), color(255,60,17,30 - (2 * i)), 11)
                render.pop_clip_rect()

                render.push_clip_rect(vector(p1[1]+ 1 +m1[1], p1[2]+20 + posw.y), vector(p1[1]+ 20+m1[1], p1[2]- 20 + posw.y))
                render.circle(vector(p1[1]+ 1+m1[1], p1[2]- 5 + posw.y), color(255,60,17,30 - (2 * i)), 11)
                render.pop_clip_rect()

                --render.rect_filled_rounded(leaset[1] - 3-i, leaset[2] - 5-i, leaset[1]  +beb + 3+ i, l[2] + 15+ i, render.color(ui_color:get_color().r,ui_color:get_color().g,ui_color:get_color().b, 25 - (2 * i)), 5)
            end
            --]]

            --render.push_clip_rect(vector(p1[1]-1,p1[2]-16 + posw.y), vector(p1[1]+ 1+m1[1], p1[2]+6 + posw.y))
            renderer.rounded_shadow(vector(p1[1]-11,p1[2]-16 + posw.y), vector(p1[1]+ 11+m1[1], p1[2]+6 + posw.y), (menu.visual.interface_color:get():alpha_modulate(25 * ((h>255 and 0 or h)/255)*0.8)), 5, 7)
            --render.pop_clip_rect()

            render.push_clip_rect(vector(p1[1]-1,p1[2]+20+ posw.y), vector(p1[1]-15,p1[2] - 20+ posw.y))
            render.circle(vector(p1[1]-1,p1[2]-5 + posw.y), color(25,25,25, 255 * ((h>255 and 0 or h)/255)), 11)
            render.pop_clip_rect()
            render.push_clip_rect(vector(p1[1]+ 1 +m1[1], p1[2]+20 + posw.y), vector(p1[1]+ 20+m1[1], p1[2]- 20 + posw.y))
            render.circle(vector(p1[1]+ 1+m1[1], p1[2]- 5 + posw.y), color(25,25,25,255 * ((h>255 and 0 or h)/255)), 11)
            render.pop_clip_rect()
            render.rect(vector(p1[1]-1,p1[2]-16 + posw.y), vector(p1[1]+ 1+m1[1], p1[2]+6 + posw.y), color(25,25,25, 255 * ((h>255 and 0 or h)/255)))
            render.text(1, vector(p1[1]+m1[1]/2-o[1]/2 - 3, p1[2] - 12 + posw.y),menu.visual.interface_color:get():alpha_modulate(h),"dc", "⚠")
			render.text(1, vector(p1[1]+m1[1]/2+n1[1]/2 + 2, p1[2] - 12 + posw.y), color(255,255,255,h),"dc", j.draw.."!")
           elseif menu.visual.interface_mode:get() == 0 and not menu.visual.notify_condition:get(2) then
                  render.rect(vector(p[1]-1,p[2]-18 + posw.y), vector(p[1]-149+m[1]+lerpy, p[2]-16+ posw.y), menu.visual.interface_color:get():alpha_modulate(h>255 and 255 or h))
                  render.rect(vector(p[1]-1,p[2]-16 + posw.y), vector(p[1]+ 1+m[1], p[2]+6 + posw.y), color(25,25,25, menu.visual.interface_color:get().a * ((h>255 and 0 or h)/255)))
                  render.text(1, vector(p[1]+m[1]/2-o[1]/2 - 2, p[2] - 12 + posw.y),menu.visual.interface_color:get():alpha_modulate(h),"dc", "[etnasy.gg]  ")
                  render.text(1, vector(p[1]+m[1]/2+n[1]/2 + 2, p[2] - 12 + posw.y), color(255,255,255,h),"dc", j.draw)
           elseif menu.visual.interface_mode:get() == 1 and not menu.visual.notify_condition:get(2) then
                render.rect(vector(p[1]-1,p[2]-18 + posw.y), vector(p[1]-149+m[1]+lerpy, p[2]-16+ posw.y), menu.visual.interface_color:get():alpha_modulate(h>255 and 255 or h))
                render.gradient(vector(p[1]-1,p[2]-16 + posw.y), vector(p[1]+ 1+m[1], p[2]+6 + posw.y), menu.visual.interface_color:get():alpha_modulate(255 * ((h>255 and 0 or h)/255)), menu.visual.interface_color:get():alpha_modulate(255 * ((h>255 and 0 or h)/255)), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,0 * ((h>255 and 0 or h)/255)), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b, 0 * ((h>255 and 0 or h)/255)))
                render.text(1, vector(p[1]+m[1]/2-o[1]/2 - 2, p[2] - 12 + posw.y),menu.visual.interface_color:get():alpha_modulate(h),"dc", "[etnasy.gg]  ")
                render.text(1, vector(p[1]+m[1]/2+n[1]/2 + 2, p[2] - 12 + posw.y), color(255,255,255,h),"dc", j.draw)
            end

           -- render.rect(vector(p[1]-1,p[2]-18 + posw.y), vector(p[1]-149+m[1]+lerpy, p[2]-16+ posw.y), menu.visual.interface_color:get():alpha_modulate(h>255 and 255 or h))
            e=e-33
        end
	end;

    animation.alpha = math.lerp(animation.alpha, ui.is_open() and 255 or 0, 12 * globals.frametime)
    animation.alpha1 = math.lerp(animation.alpha1, ui.is_open() and 255 or 0, 12 * globals.frametime)
    animation.anim = math.lerp(animation.anim, ui.is_open() and 0 or 255, 12 * globals.frametime)

    if #_G.angelwave_notify_cache == 0 and menu.visual.notifyx_x:get() then
        drag_logs:update(nil, main.screen_size.x/2 - 200)
        local pos = vector(drag_logs:get().x, drag_logs:get().y+30)
        local measure = render.measure_text(1,"⚠ hit zxkilla's head for 1 damage (99 hp remaining)").x /2
        local measure1 = render.measure_text(1,"⚠ missed shot due to etnasy.gg user").x /2

        if menu.visual.notify_condition:get(2) then
            
            renderer.rounded_shadow(vector(main.screen_size.x/2 - measure - 20, pos.y - 6), vector(main.screen_size.x/2 + measure + 20, pos.y +16), menu.visual.interface_color:get():alpha_modulate(25 * (animation.alpha1/255)), 5, 7)

            render.rect(vector(main.screen_size.x/2 - measure - 10, pos.y - 6), vector(main.screen_size.x/2 + measure + 10, pos.y +16), color(25,25,25,255*(animation.alpha1/255)))
            render.push_clip_rect(vector(main.screen_size.x/2 - measure - 10, pos.y - 22), vector(main.screen_size.x/2 - measure -25, pos.y + 25))
            render.circle(vector(main.screen_size.x/2 - measure - 10, pos.y + 5), color(25,25,25, 255 *(animation.alpha1/255)), 11)
            render.pop_clip_rect()

            render.push_clip_rect(vector(main.screen_size.x/2 + measure + 10, pos.y - 22), vector(main.screen_size.x/2 + measure +25, pos.y + 25))
            render.circle(vector(main.screen_size.x/2 + measure + 10, pos.y + 5), color(25,25,25, 255 *(animation.alpha1/255)), 11)
            render.pop_clip_rect()

            render.text(1, vector(main.screen_size.x/2, pos.y - 2), color(255,255,255, animation.alpha),"dc", "⚠ hit zxkilla's head for 1 damage (99 hp remaining)!")


            renderer.rounded_shadow(vector(main.screen_size.x/2 - measure1 - 20, pos.y + 23), vector(main.screen_size.x/2 + measure1 + 20, pos.y +46), menu.visual.interface_color:get():alpha_modulate(25 * (animation.alpha1/255)), 5, 7)

            render.rect(vector(main.screen_size.x/2 - measure1 - 10, pos.y + 23), vector(main.screen_size.x/2 + measure1 + 10, pos.y +46), color(25,25,25,255*(animation.alpha1/255)))
            render.push_clip_rect(vector(main.screen_size.x/2 - measure1 - 10, pos.y - 52), vector(main.screen_size.x/2 - measure1 -25, pos.y + 55))
            render.circle(vector(main.screen_size.x/2 - measure1 - 10, pos.y + 35), color(25,25,25, 255 *(animation.alpha1/255)), 11)
            render.pop_clip_rect()
            render.push_clip_rect(vector(main.screen_size.x/2 + measure1 + 10, pos.y - 52), vector(main.screen_size.x/2 + measure1 +25, pos.y + 55))
            render.circle(vector(main.screen_size.x/2 + measure1 + 10, pos.y + 35), color(25,25,25, 255 *(animation.alpha1/255)), 11)
            render.pop_clip_rect()
            render.text(1, vector(main.screen_size.x/2, pos.y + 28), color(255,255,255, animation.alpha),"dc", "⚠ missed shot due to etnasy.gg user!")

        elseif menu.visual.interface_mode:get() == 0 then
            render.rect(vector(main.screen_size.x/2 - render.measure_text(1,"[etnasy.gg] hit zxkilla's head for 1 damage (99 hp remaining)").x /2 - 10, pos.y - 8), vector(main.screen_size.x/2 + render.measure_text(1,"[etnasy.gg] hit zxkilla's head for 1 damage (99 hp remaining)").x/2 + 10 - animation.anim, pos.y -6), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,animation.alpha))
            render.rect(vector(main.screen_size.x/2 - render.measure_text(1,"[etnasy.gg] hit zxkilla's head for 1 damage (99 hp remaining)").x /2 - 10, pos.y - 6), vector(main.screen_size.x/2 + render.measure_text(1,"[etnasy.gg] hit zxkilla's head for 1 damage (99 hp remaining)").x/2 + 10, pos.y +16), color(21,21,21,menu.visual.interface_color:get().a*(animation.alpha1/255)))
            render.text(1, vector(main.screen_size.x/2, pos.y - 2), color(255,255,255, animation.alpha),"dc", "[etnasy.gg] hit zxkilla's head for 1 damage (99 hp remaining)")
            
            render.rect(vector(main.screen_size.x/2 - render.measure_text(1,"[etnasy.gg] missed shot due to etnasy.gg user").x /2 - 10, pos.y + 25), vector(main.screen_size.x/2 + render.measure_text(1,"[etnasy.gg] missed shot due to etnasy.gg user").x/2 + 10 - animation.anim, pos.y +27), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,animation.alpha))    
            render.rect(vector(main.screen_size.x/2 - render.measure_text(1,"[etnasy.gg] missed shot due to etnasy.gg user").x /2 - 10, pos.y + 27), vector(main.screen_size.x/2 + render.measure_text(1,"[etnasy.gg] missed shot due to etnasy.gg user").x/2 + 10, pos.y +49), color(21,21,21, menu.visual.interface_color:get().a*(animation.alpha1/255)))
            render.text(1, vector(main.screen_size.x/2, pos.y + 31), color(255,255,255, animation.alpha),"dc", "[etnasy.gg] missed shot due to etnasy.gg user")
        elseif menu.visual.interface_mode:get() == 1 then
            render.rect(vector(main.screen_size.x/2 - render.measure_text(1,"[etnasy.gg] hit zxkilla's head for 1 damage (99 hp remaining)").x /2 - 10, pos.y - 8), vector(main.screen_size.x/2 + render.measure_text(1,"[etnasy.gg] hit zxkilla's head for 1 damage (99 hp remaining)").x/2 + 10 - animation.anim, pos.y -6), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,animation.alpha))
            render.gradient(vector(main.screen_size.x/2 - render.measure_text(1,"[etnasy.gg] hit zxkilla's head for 1 damage (99 hp remaining)").x /2 - 10, pos.y - 6), vector(main.screen_size.x/2 + render.measure_text(1,"[etnasy.gg] hit zxkilla's head for 1 damage (99 hp remaining)").x/2 + 10, pos.y +16), menu.visual.interface_color:get():alpha_modulate(menu.visual.interface_color:get().a*(animation.alpha1/255)), menu.visual.interface_color:get():alpha_modulate(menu.visual.interface_color:get().a*(animation.alpha1/255)), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,0), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,0))
            render.text(1, vector(main.screen_size.x/2, pos.y - 2), color(255,255,255, animation.alpha),"dc", "[etnasy.gg] hit zxkilla's head for 1 damage (99 hp remaining)")
            render.rect(vector(main.screen_size.x/2 - render.measure_text(1,"[etnasy.gg] missed shot due to etnasy.gg user").x /2 - 10, pos.y + 25), vector(main.screen_size.x/2 + render.measure_text(1,"[etnasy.gg] missed shot due to etnasy.gg user").x/2 + 10 - animation.anim, pos.y +27), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,animation.alpha))
            render.gradient(vector(main.screen_size.x/2 - render.measure_text(1,"[etnasy.gg] missed shot due to etnasy.gg user").x /2 - 10, pos.y + 27), vector(main.screen_size.x/2 + render.measure_text(1,"[etnasy.gg] missed shot due to etnasy.gg user").x/2 + 10, pos.y +49), menu.visual.interface_color:get():alpha_modulate(menu.visual.interface_color:get().a*(animation.alpha1/255)), menu.visual.interface_color:get():alpha_modulate(menu.visual.interface_color:get().a*(animation.alpha1/255)), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,0), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,0))
            render.text(1, vector(main.screen_size.x/2, pos.y + 31), color(255,255,255, animation.alpha),"dc", "[etnasy.gg] missed shot due to etnasy.gg user")
        end

    end

	self.callback_registered=true end)
end;

function a:paint(q,r,p)
	local s=tonumber(q)+1;
	for g=self.maximum_count,2,-1 do
		_G.angelwave_notify_cache[g]=_G.angelwave_notify_cache[g-1]
	end;
	_G.angelwave_notify_cache[1]={time=s,def_time=s,draw=r,clr=p}
self:set_callback()end;return a end)()

angelwave_push:paint(4, "welcome back, "..info.username.." ~ build: "..info.build.." [till: "..tostring(os.date("%m.%d ", info.till)):gsub(' ', '').."]")
local RGBtoHEX = function (col, short)
    return string.format(short and "%02X%02X%02X" or "%02X%02X%02X%02X", col.r, col.g, col.b, col.a)
end
math.calcangle = function(localplayerxpos, localplayerypos, enemyxpos, enemyypos)
    local relativeyaw = math.atan( (localplayerypos - enemyypos) / (localplayerxpos - enemyxpos) )
    return relativeyaw * 180 / math.pi
 end
math.angle_vector = function(angle_x, angle_y)
    local sy = math.sin(math.rad(angle_y));
    local cy = math.cos(math.rad(angle_y));
    local sp = math.sin(math.rad(angle_x));
    local cp = math.cos(math.rad(angle_x));
    return cp * cy, cp * sy, -sp;
end
local antiaim = {
    view_angles = qangle(0, 0, 0),
    command_number = 0,
    backstab = false,
    safehead = false,
    modifier_offset = 0,
    yaw_offset = 0,
    jitter_side = false,
    desync_angle = 0,
    desync_side = 0,
    step_desync_side = false,
    delayed_side = 0,
    current_way = 1,
    side = -1,
    way_degree = 0,
    defensive = {
        ctx_force = false,
        side = 0,
        pitch_side = 0,
        max_tickbase = 0,
        pitch_cycle = 0,
        yaw_spin = 0
    },
    direction = {
        last_pressed = -1,
        peek_cache = false,
        peek_need = false
    },
    is_preset = '',
    cached_builder = {},
    handle = function(self, ctx)
        if not globals.is_in_game or not menu.aa.override:get() then return end

        -- manual direction
        if menu.aa.manual:get() and not (menu.aa.manual_left:get() or menu.aa.manual_right:get() or menu.aa.manual_back:get() or menu.aa.manual_forward:get()) then
            self.direction.last_pressed = -1
        elseif self.direction.last_pressed ~= -1 and menu.aa.manual:get() then
            self.yaw_offset = self.direction.last_pressed
            if self.yaw_offset == 0 then ctx:desync_side(-1) end
            ctx:desync_side(self.yaw_offset < 0 and -1 or 1)
            ctx:yaw_offset(self.yaw_offset)
        end

        -- auto manual reset
        if menu.aa.manual_auto_reset:get() and ui.find('Aimbot', 'Aimbot', 'Peek Assist'):get() and ui.find('Aimbot', 'Aimbot', 'Peek Assist key'):get() then self.direction.peek_cache = true end
        if menu.aa.manual_auto_reset:get() and self.direction.peek_cache and self.direction.last_pressed ~= -1 and ui.find('Aimbot', 'Aimbot', 'Peek Assist'):get() and not ui.find('Aimbot', 'Aimbot', 'Peek Assist key'):get() then
            self.direction.peek_need = true
            self.direction.peek_cache = false
        end
        if menu.aa.manual_auto_reset:get() and self.direction.peek_need then
            menu.aa.manual_left:set(false)
            menu.aa.manual_right:set(false)
            menu.aa.manual_forward:set(false)
            menu.aa.manual_back:set(false)
            self.direction.last_pressed = -1
            self.direction.peek_need = false
        end

        -- duck exploit
        if menu.aa.duck_exploit:get() and self.direction.last_pressed ~= -1 and get_cond() == '*crouch*' then
            self.defensive.ctx_force = true
            if globals.choked_commands == 1 and rage.get_exploit_charge() == 1 and rage.is_defensive_active() and rage.get_defensive_ticks() < 10 then
                ctx:yaw_offset(self.direction.last_pressed == 180 and 0 or (self.direction.last_pressed == 0 and 180 or self.direction.last_pressed * -1))
                ctx:pitch(89)
            end
        end

        -- anti backstab
        local lp = entity.get_local_player()
        local weap = lp:get_active_weapon()
        local is_melee = weap and (weap:weapon_index() == 31 or weap:is_knife())

        if self.backstab then
            self.defensive.ctx_force = false
            ctx:yaw_offset(180)
            ctx:pitch(-89)
            ctx:desync(true)
            ctx:desync_angle(180)
        end

        -- safe head
        if menu.aa.safe_head:get() and rage.get_antiaim_target() then
            local threat = rage.get_antiaim_target()
            for i = 1, globals.max_players do
                local ent = entity.get(i)
                if ent and threat == ent and not ent:is_dormant() and ent:is_enemy() then
                    local threat = rage.get_antiaim_target()
                    local threat_origin = threat:get_abs_origin()
                    local distance = lp:get_abs_origin():dist(threat_origin)
                    local height_diff = lp:get_abs_origin().z - threat_origin.z

                    local trace = utils.trace_line(lp:get_eye_position(), vector(threat_origin.x, threat_origin.y, threat_origin.z + 56), 0x600400B, lp)
                    local is_visible = trace.hit_entity == lp

                    --
                    local air_melee = menu.aa.safe_head_conds:get(0)
                    local height_difference = menu.aa.safe_head_conds:get(1)

                    if ((air_melee and (get_cond() == '*aero-crouch*' or get_cond() == '*aero*') and is_melee and height_diff > -32)
                    or (height_difference and height_diff > 64 and (is_visible or distance < 1024))) and not self.backstab then
                        self.safehead = true
                        ctx:yaw_offset(0)
                        ctx:pitch(89)
                        ctx:desync(true)
                        ctx:desync_angle(180)
                    else self.safehead = false end
                end
            end
        else
            self.safehead = false
        end

        if menu.aa.setting_type:get() == 2 or self.is_preset ~= '' then -- custom
            if self.direction.last_pressed ~= -1 and menu.aa.manual:get() then return end
            local cond = get_cond(true)
            if cond == nil then return end
            if not menu.builder[cond].override:get() or not menu.builder[cond] then cond = 1 end
            local cur = menu.builder[cond]

            -- overriding cheat anti-aim
            refs.antiaim.yaw_jitter:set(false)
            refs.antiaim.body_yaw:set(cur.body_options:get() ~= 0)
            refs.antiaim.limit:set(0)
            refs.antiaim.body_yaw_options:set(false, 0)
            refs.antiaim.body_yaw_options:set(false, 1)
            refs.antiaim.body_yaw_options:set(false, 2)
            refs.antiaim.body_yaw_options:set(false, 3)

            self.yaw_offset = math.floor(cur.yaw_add_degree:get() / 2)
            
            -- updating desync_side only on desync tick
            self.side = get_side()

            -- yaw modifier
            if cur.yaw_modifier:get() == 0 then self.modifier_offset = 0
            elseif cur.yaw_modifier:get() == 1 then -- jitter
                if cur.body_options:get() ~= 0 then -- not disabled
                    if globals.choked_commands == 1 then self.jitter_side = not self.jitter_side end -- making side on real choke tick
                    
                    if cur.body_options:get() == 1 then
                        self.modifier_offset = self.jitter_side and cur.modifier_left:get() or cur.modifier_right:get()
                    else
                        self.modifier_offset = self.side == 1 and cur.modifier_left:get() or cur.modifier_right:get() -- side-based center jitter
                    end
                else -- desync disabled
                    if globals.choked_commands == 1 then self.jitter_side = not self.jitter_side end -- making side on real choke tick
                    self.modifier_offset = self.jitter_side and cur.modifier_left:get()/2 or cur.modifier_right:get()/2
                end
            elseif cur.yaw_modifier:get() == 2 then -- delayed
                local delay_tick = cur.delay_tick:get()*2 -- simple in calculating
                self.delayed_side = (self.command_number % delay_tick*2)+1 <= delay_tick
                self.modifier_offset = self.delayed_side and cur.modifier_left:get()/2 or cur.modifier_right:get()/2
            elseif cur.yaw_modifier:get() == 3 then
                math.randomseed(self.command_number) -- random based on commands
                if globals.choked_commands == 1 then 
                    self.modifier_offset = math.random(cur.modifier_left:get()/2, cur.modifier_right:get()/2) * self.side -- desync_side (synchronization)
                end
            else -- x-way
                if globals.choked_commands == 1 then self.current_way = self.current_way + 1 if self.current_way > cur.way_count:get() then self.current_way = 1 end end
                self.way_degree = cur.way_deg[self.current_way]:get() / 2
                self.modifier_offset = self.way_degree
            end

            -- desync (body yaw)
            local opposite_desync = cur.fake_yaw_limit:get()*1.93
            local left_desync = cur.left_fake_yaw_limit:get()*1.93
            local right_desync = cur.right_fake_yaw_limit:get()*1.93

            local lp = entity.get_local_player()
            if cur.body_options:get() == 1 then -- opposite
                if globals.choked_commands == 0 then
                    self.desync_side = opposite_desync <= 0 and -1 or 1
                    self.desync_angle = math.abs(opposite_desync)
                end
            elseif cur.body_options:get() == 2 then
                if globals.choked_commands == 0 and cur.yaw_modifier:get() ~= 2 then
                    self.step_desync_side = not self.step_desync_side
                elseif cur.yaw_modifier:get() == 2 then
                    self.step_desync_side = self.delayed_side
                end

                self.desync_side = self.step_desync_side and -1 or 1
                self.desync_angle = self.desync_side == -1 and left_desync or right_desync
            end

            --- applying antiaim
            if not self.backstab and not self.safehead then
                if globals.choked_commands == 0 then
                    ctx:desync(cur.body_options:get() ~= 0)
                    ctx:desync_angle(self.desync_angle)
                    ctx:desync_side(self.desync_side)
                end
                ctx:yaw_offset(self.yaw_offset + self.modifier_offset) 
            end

            -- defensive yaw anti-aim (DISABLED to prevent conflicts with fakeduck)
            -- self.defensive.ctx_force = (cur.defensive_shift:get() ~= 0 or (menu.aa.duck_exploit:get() and self.direction.last_pressed ~= -1 and get_cond(true) == '*crouch*')) and not self.backstab and not self.safehead
            -- local is_defensive = (self.defensive.ctx_force and true or rage.get_antiaim_target()) and rage.get_exploit_charge() == 1 and rage.is_defensive_active() and rage.get_defensive_ticks() ~= 0 and not (menu.aa.duck_exploit:get() and self.direction.last_pressed ~= -1 and get_cond(true) == '*crouch*') and not self.backstab and not self.safehead
            -- local def_ticks = cur.defensive_ticks:get()*3
            -- if cur.defensive_yaw:get() == 1 and is_defensive then -- opposite
            --     ctx:yaw_offset(180)
            -- elseif cur.defensive_yaw:get() == 2 and is_defensive then -- sideways
            --     if globals.choked_commands == 1 then
            --         if cur.defensive_shift:get() == 1 then
            --             self.defensive.side = (self.command_number % def_ticks*2)+1 <= def_ticks and -1 or 1
            --         else
            --             self.defensive.side = self.defensive.side == -1 and 1 or -1
            --         end
            --         ctx:yaw_offset(self.defensive.side * 90)
            --     end
            -- elseif cur.defensive_yaw:get() == 3 and is_defensive then -- spin
            --     if globals.choked_commands == 1 then
            --         if cur.defensive_shift:get() == 1 then -- delayed shifting
            --             local deg = (globals.tickcount % cur.defensive_ticks:get()*2)
            --             if deg <= cur.defensive_ticks:get() then self.defensive.yaw_spin = self.defensive.yaw_spin + 39 end
            --         else self.defensive.yaw_spin = self.defensive.yaw_spin + 39 end

            --         if self.defensive.yaw_spin >= cur.defensive_spin_limit:get() then self.defensive.yaw_spin = 0 end
            --         ctx:yaw_offset(self.defensive.yaw_spin)
            --     end
            -- elseif cur.defensive_yaw:get() == 4 and is_defensive then -- custom jitter
            --     if globals.choked_commands == 1 then
            --         if cur.defensive_shift:get() == 1 then
            --             self.defensive.side = (globals.tickcount % cur.defensive_ticks:get()*2)+1 <= cur.defensive_ticks:get() and -1 or 1
            --         else
            --             self.defensive.side = self.defensive.side == -1 and 1 or -1
            --         end
            --         ctx:yaw_offset(self.defensive.side * cur.custom_defensive_yaw:get())
            --     end
            -- end

            -- defensive pitch anti-aim (DISABLED to prevent conflicts with fakeduck)
            -- if cur.defensive_pitch:get() == 1 and is_defensive then -- up
            --     ctx:pitch(-89)
            -- elseif cur.defensive_pitch:get() == 2 and is_defensive then -- down
            --     ctx:pitch(89)
            -- elseif cur.defensive_pitch:get() == 3 and is_defensive then -- zero
            --     ctx:pitch(0)
            -- elseif cur.defensive_pitch:get() == 4 and is_defensive then -- custom
            --     ctx:pitch(cur.custom_defensive_pitch:get())
            -- elseif cur.defensive_pitch:get() == 5 and is_defensive then -- custom jitter
            --     if cur.defensive_shift:get() == 1 then
            --         self.defensive.pitch_side = (globals.tickcount % cur.defensive_ticks:get()*2)+1 <= cur.defensive_ticks:get() and -1 or 1
            --     else       
            --         if globals.choked_commands == 1 then
            --             self.defensive.pitch_side = self.defensive.pitch_side == -1 and 1 or -1
            --         end
            --     end
            --     self.defensive.pitch_cycle = self.defensive.pitch_cycle + 1
            --     if self.defensive.pitch_cycle >= 4 then -- auto inverting pitch
            --         ctx:pitch(self.defensive.pitch_side * cur.custom_defensive_pitch:get())
            --         if self.defensive.pitch_cycle >= 8 then self.defensive.pitch_cycle = 0 end
            --     else -- inverting
            --         ctx:pitch(-1*self.defensive.pitch_side * cur.custom_defensive_pitch:get())
            --     end
            -- end

            if self.is_preset ~= '' and menu.aa.setting_type:get() == 2 then
                for i = 1, #self.cached_builder do
                    for k, v in pairs(self.cached_builder[i]) do
                        if type(v) == 'table' then
                            for a, b in pairs(v) do
                                menu.builder[i][k][a]:set(b)
                            end
                        else
                            menu.builder[i][k]:set(v)
                        end 
                    end 
                end
                self.is_preset = ''
            end
        end
        if menu.aa.setting_type:get() == 1 then
            --if self.direction.last_pressed ~= -1 and menu.aa.manual:get() then return end
            local current_preset = menu.aa.preset:get() == 0 and 'aggressive' or 'meta'
            local builder_cached = false
            if self.is_preset == '' then
                local cfg_settings = {}
                for i = 1, #menu.builder do 
                    if i ~= 0 then
                        for k, v in pairs(menu.builder[i]) do
                            if type(v) == 'table' then 
                                for a, b in pairs(v) do
                                    if cfg_settings[i] == nil then cfg_settings[i] = {} end
                                    if cfg_settings[i][k] == nil then cfg_settings[i][k] = {} end
                                    if cfg_settings[i][k][a] == nil then cfg_settings[i][k][a] = b:get() end
                                end 
                            else
                                if cfg_settings[i] == nil then cfg_settings[i] = {} end
                                if cfg_settings[i][k] == nil then cfg_settings[i][k] = v:get() end
                            end 
                        end 
                    end
                end
                self.cached_builder = cfg_settings
            end
            if current_preset == 'meta' then
                if not is_ZALUPA_executing and (self.is_preset == '' or self.is_preset == 'aggressive') then
                    config_frequency = 50
                    exec_import([[y3ZiVauZUTldbaljWxe6HxsiUm9kcu9rYvQpX25zejosFGBkVyVlXnJpbmudYal0U2fiKjAZenbgcu9jX3uqbGe6HxsiXy9kWyVpVTBdXaumbGe6HGsiVmwIVu95UTbdXalDWTOiKjAZemQlVmuqY2l2Vu90WyJIYxe6HxsiVaumVy5zWTVlT3lgbxe6HGsiXy9kWyVpVTBdYmlnWvOiKjAZemJ1Y3QrXu9kVyVlXnJpbmudYal0U2fiKjf5FGBxWybobw9mUyDlT3lgb19ZWy1pbGe6JSfZenbgcu9kVyYiKlZsFEAZHGssFEAZHGssTRsiVaumVy5zWTVlT3JsWy5dXalDWTOiKjH2HGsiVaumVy5zWTVlT3JoWyV0ejosFGB5UTbdUyQkT2QlV3BlVRe6HGsiU3uzba9DT2QlVmuqY2l2Vu95UTYiKjksFGB5UTbdXy9kWyVpVTeiKjAZemtlVnQdVmwIVu95UTbdXalDWTOiKjh4FGBrbmuxYmlkVRe6VmwZY2u9FvZiVauZUTldbaljWxe6JisiUm9kcu9rYvQpX25zejoxFGBkVyVlXnJpbmudYal0U2fiKjAZenbgcu9jX3uqbGe6HxsiXy9kWyVpVTBdXaumbGe6HRsiVmwIVu95UTbdXalDWTOiKi0tKEAZemQlVmuqY2l2Vu90WyJIYxe6HxsiVaumVy5zWTVlT3lgbxe6HGsiXy9kWyVpVTBdYmlnWvOiKi0tFGBjbTJ0X21dVaumVy5zWTVlT3NpbaJoejo4KRsiYmlnWvQdVmwIVu95UTbdXalDWTOiKjh4FGB3UTldVaunejpXHGssFEAZHGssFEAZHw0ZemQlVmuqY2l2Vu9zYalqT2tpXyl0ejozJjAZemQlVmuqY2l2Vu9zWalmbGe6HGsicyw3T2wkVw9kVybxVyhiKjAZemJ1Y3QrXu9kVyVlXnJpbmudcyw3ejo5HGsicyw3T21rValmWyuxejotFGBZVyV0T2VgW2udcyw3T2tpXyl0ejo1KGsiX3VlYnBpVahiKnQxbyu9FvZiVauZUTldbaljWxe6KGsiUm9kcu9rYvQpX25zejoxFGBkVyVlXnJpbmudYal0U2fiKjOZenbgcu9jX3uqbGe6HxsiXy9kWyVpVTBdXaumbGe6FSLsFGBmUyDlT3lgb19ZWy1pbGe6FSetFGBkVyVlXnJpbmudbaljW3HiKjHZemQlVmuqY2l2Vu95UTYiKjHZem1rValmWyuxT3BpV2g0ejoxJGsiU3uzba9DT2QlVmuqY2l2Vu9sWTQjWGe6HzOZenBpV2g0T2VgW2udcyw3T2tpXyl0ejo0KRsib2w5T2QlVxe6yzAZHGssFEAZHGssFENbFGBkVyVlXnJpbmudY3NpXl9ZWy1pbGe6HzUsFGBkVyVlXnJpbmudY2gpVnOiKjAZenlgb19gVaQdVaunYmulejosFGBjbTJ0X21dVaumVy5zWTVlT3lgbxe6KSAZenlgb19DX2QpVmllYie6HisiXaumbw9mUyDlT3lgb19ZWy1pbGe6JSOZem92VTBxWyQlejp0YnuldRt7emQlXaw5T3QpU2ZiKjL0FGBiX2Q5T29sbalrXnHiKjLZemQlVmuqY2l2Vu9sWTQjWGe6JRsib2w5T2Jrby50ejozFGBDX2QpVmllYl9ZVyV0ejoDHjOZemVgW2udcyw3T2tpXyl0ejo1KGsiVaumVy5zWTVlT3QpU2DzejozFGBkVyVlXnJpbmudcyw3ejo0FGBDX2QpVmllYl9xWybobGe6HzLZemJ1Y3QrXu9kVyVlXnJpbmudYal0U2fiKje4FGBxWybobw9mUyDlT3lgb19ZWy1pbGe6HGsib2w5T2QlVxe6yzAZHGssFEAZHGssFENbFGBkVyVlXnJpbmudY3NpXl9ZWy1pbGe6HzUsFGBkVyVlXnJpbmudY2gpVnOiKjeZenlgb19gVaQdVaunYmulejosFGBjbTJ0X21dVaumVy5zWTVlT3lgbxe6HSL3FGB5UTbdXy9kWyVpVTeiKjeZemtlVnQdVmwIVu95UTbdXalDWTOiKjAZem92VTBxWyQlejp0YnuldRt7emQlXaw5T3QpU2ZiKjHZemBrVvldX3N0Wy9qYxe6HisiVaumVy5zWTVlT3NpbaJoejotFGB3UTldU291XnOiKjHZem1rValmWyuxT2tlVnOiKi0xJRsiVmwIVu95UTbdXalDWTOiKjAZemQlVmuqY2l2Vu90WyJIYxe6HxsiVaumVy5zWTVlT3lgbxe6HxsiXy9kWyVpVTBdYmlnWvOiKjHtFGBjbTJ0X21dVaumVy5zWTVlT3NpbaJoejo4KRsiYmlnWvQdVmwIVu95UTbdXalDWTOiKjh4FGB3UTldVaunejpXHGssFEAZHGssFEAZHw0ZemQlVmuqY2l2Vu9zYalqT2tpXyl0ejozJjAZemQlVmuqY2l2Vu9zWalmbGe6Hisicyw3T2wkVw9kVybxVyhiKjAZemJ1Y3QrXu9kVyVlXnJpbmudcyw3ejo5HGsicyw3T21rValmWyuxejozFGBZVyV0T2VgW2udcyw3T2tpXyl0ejo1KGsiX3VlYnBpVahiKnQxbyu9FvZiVauZUTldbaljWxe6JGsiUm9kcu9rYvQpX25zejotFGBkVyVlXnJpbmudYal0U2fiKjHZenbgcu9jX3uqbGe6HxsiXy9kWyVpVTBdXaumbGe6FSHzFGBmUyDlT3lgb19ZWy1pbGe6HRsiVaumVy5zWTVlT3QpU2DzejozHisiVaumVy5zWTVlT3lgbxe6HRsiXy9kWyVpVTBdYmlnWvOiKjHzFGBjbTJ0X21dVaumVy5zWTVlT3NpbaJoejo4KRsiYmlnWvQdVmwIVu95UTbdXalDWTOiKjAZenbgcu9kVyYiKlZsFEAZHGssFEAZHGssTRsiVaumVy5zWTVlT3JsWy5dXalDWTOiKjH2HGsiVaumVy5zWTVlT3JoWyV0ejoxFGB5UTbdUyQkT2QlV3BlVRe6HGsiU3uzba9DT2QlVmuqY2l2Vu95UTYiKjksFGB5UTbdXy9kWyVpVTeiKjeZemtlVnQdVmwIVu95UTbdXalDWTOiKjAZem92VTBxWyQlejp0YnuldRt7emQlXaw5T3QpU2ZiKjYZemBrVvldX3N0Wy9qYxe6HRsiVaumVy5zWTVlT3NpbaJoejo1FGB3UTldU291XnOiKjHZem1rValmWyuxT2tlVnOiKi0zHGsiVmwIVu95UTbdXalDWTOiKjh4FGBkVyVlXnJpbmudbaljW3HiKjHZemQlVmuqY2l2Vu95UTYiKjOZem1rValmWyuxT3BpV2g0ejozHGsiU3uzba9DT2QlVmuqY2l2Vu9sWTQjWGe6FSH1FGBxWybobw9mUyDlT3lgb19ZWy1pbGe6HGsib2w5T2QlVxe6yzAZHGssFEAZHGssFENbFGBkVyVlXnJpbmudY3NpXl9ZWy1pbGe6HzUsFGBkVyVlXnJpbmudY2gpVnOiKjeZenlgb19gVaQdVaunYmulejosFGBjbTJ0X21dVaumVy5zWTVlT3lgbxe6JSfZenlgb19DX2QpVmllYie6HisiXaumbw9mUyDlT3lgb19ZWy1pbGe6HGsiX3VlYnBpVahiKnQxbyu9TO==]])
                    self.is_preset = current_preset
                end
            elseif current_preset == 'aggressive' then
                if not is_ZALUPA_executing and (self.is_preset == '' or self.is_preset == 'meta') then
                    config_frequency = 50
                    exec_import([[y3ZiVauZUTldbaljWxe6JGsiUm9kcu9rYvQpX25zejotFGBkVyVlXnJpbmudYal0U2fiKjLZenbgcu9jX3uqbGe6JxsiXy9kWyVpVTBdXaumbGe6JEeZemVgW2udcyw3T2tpXyl0ejo1KGsiVaumVy5zWTVlT3QpU2DzejozFGBkVyVlXnJpbmudcyw3ejozFGBDX2QpVmllYl9xWybobGe6FShzFGBjbTJ0X21dVaumVy5zWTVlT3NpbaJoejo4KRsiYmlnWvQdVmwIVu95UTbdXalDWTOiKjh4FGB3UTldVaunejpXFSUxFG0zJGsDHSHZHRstHxszJGs2Hl0ZemQlVmuqY2l2Vu9zYalqT2tpXyl0ejozJjAZemQlVmuqY2l2Vu9zWalmbGe6HRsicyw3T2wkVw9kVybxVyhiKjAZemJ1Y3QrXu9kVyVlXnJpbmudcyw3ejo5HGsicyw3T21rValmWyuxejo0FGBZVyV0T2VgW2udcyw3T2tpXyl0ejo1KGsiX3VlYnBpVahiKmVgXvJldRt7emQlXaw5T3QpU2ZiKjHZemBrVvldX3N0Wy9qYxe6HGsiVaumVy5zWTVlT3NpbaJoejosFGB3UTldU291XnOiKjHZem1rValmWyuxT2tlVnOiKjAZemVgW2udcyw3T2tpXyl0ejosFGBkVyVlXnJpbmudbaljW3HiKjHZemQlVmuqY2l2Vu95UTYiKjAZem1rValmWyuxT3BpV2g0ejosFGBjbTJ0X21dVaumVy5zWTVlT3NpbaJoejo4KRsiYmlnWvQdVmwIVu95UTbdXalDWTOiKjAZenbgcu9kVyYiKlZsFEAZHGssFEAZHGssTRsiVaumVy5zWTVlT3JsWy5dXalDWTOiKjH2HGsiVaumVy5zWTVlT3JoWyV0ejosFGB5UTbdUyQkT2QlV3BlVRe6HGsiU3uzba9DT2QlVmuqY2l2Vu95UTYiKjksFGB5UTbdXy9kWyVpVTeiKjAZemtlVnQdVmwIVu95UTbdXalDWTOiKjAZem92VTBxWyQlejpmUytzVT0ZcxBkVytgcu90WyJIejo2FGBiX2Q5T29sbalrXnHiKjeZemQlVmuqY2l2Vu9sWTQjWGe6Hxsib2w5T2Jrby50ejozFGBDX2QpVmllYl9ZVyV0ejo1KGsiVmwIVu95UTbdXalDWTOiKjAZemQlVmuqY2l2Vu90WyJIYxe6JRsiVaumVy5zWTVlT3lgbxe6HxsiXy9kWyVpVTBdYmlnWvOiKi0zJGsiU3uzba9DT2QlVmuqY2l2Vu9sWTQjWGe6KEkZenBpV2g0T2VgW2udcyw3T2tpXyl0ejozJRsib2w5T2QlVxe6yzAZHGssFEAZHGssFENbFGBkVyVlXnJpbmudY3NpXl9ZWy1pbGe6HzUsFGBkVyVlXnJpbmudY2gpVnOiKjAZenlgb19gVaQdVaunYmulejosFGBjbTJ0X21dVaumVy5zWTVlT3lgbxe6KSAZenlgb19DX2QpVmllYie6HisiXaumbw9mUyDlT3lgb19ZWy1pbGe6HzhZem92VTBxWyQlejp0YnuldRt7emQlXaw5T3QpU2ZiKjhZemBrVvldX3N0Wy9qYxe6HisiVaumVy5zWTVlT3NpbaJoejo0FGB3UTldU291XnOiKjHZem1rValmWyuxT2tlVnOiKi03HisiVmwIVu95UTbdXalDWTOiKjAZemQlVmuqY2l2Vu90WyJIYxe6HxsiVaumVy5zWTVlT3lgbxe6JGsiXy9kWyVpVTBdYmlnWvOiKjf1FGBjbTJ0X21dVaumVy5zWTVlT3NpbaJoejoDHzAZenBpV2g0T2VgW2udcyw3T2tpXyl0ejo1KGsib2w5T2QlVxe6yzAZHGssFEAZHGssFENbFGBkVyVlXnJpbmudY3NpXl9ZWy1pbGe6HzUsFGBkVyVlXnJpbmudY2gpVnOiKjeZenlgb19gVaQdVaunYmulejosFGBjbTJ0X21dVaumVy5zWTVlT3lgbxe6FSL1KRsicyw3T21rValmWyuxejoxFGBZVyV0T2VgW2udcyw3T2tpXyl0ejo1KGsiX3VlYnBpVahiKnQxbyu9FvZiVauZUTldbaljWxe6HxsiUm9kcu9rYvQpX25zejoxFGBkVyVlXnJpbmudYal0U2fiKjOZenbgcu9jX3uqbGe6HxsiXy9kWyVpVTBdXaumbGe6HzhZemVgW2udcyw3T2tpXyl0ejosFGBkVyVlXnJpbmudbaljW3HiKjHZemQlVmuqY2l2Vu95UTYiKjHZem1rValmWyuxT3BpV2g0ejoDHzOZemJ1Y3QrXu9kVyVlXnJpbmudYal0U2fiKjO3FGBxWybobw9mUyDlT3lgb19ZWy1pbGe6JSfZenbgcu9kVyYiKlZsFEAZHGssFEAZHGssTRsiVaumVy5zWTVlT3JsWy5dXalDWTOiKjH2HGsiVaumVy5zWTVlT3JoWyV0ejoxFGB5UTbdUyQkT2QlV3BlVRe6HGsiU3uzba9DT2QlVmuqY2l2Vu95UTYiKjksFGB5UTbdXy9kWyVpVTeiKjLZemtlVnQdVmwIVu95UTbdXalDWTOiKjh4FGBrbmuxYmlkVRe6bvB1VT0ZcxBkVytgcu90WyJIejotHRsiUm9kcu9rYvQpX25zejoxFGBkVyVlXnJpbmudYal0U2fiKjhZenbgcu9jX3uqbGe6JGsiXy9kWyVpVTBdXaumbGe6FSY4FGBmUyDlT3lgb19ZWy1pbGe6HGsiVaumVy5zWTVlT3QpU2DzejotJisiVaumVy5zWTVlT3lgbxe6JGsiXy9kWyVpVTBdYmlnWvOiKi0tHSkZemJ1Y3QrXu9kVyVlXnJpbmudYal0U2fiKjf5FGBxWybobw9mUyDlT3lgb19ZWy1pbGe6JSfZenbgcu9kVyYiKlZzHxstFEH0FG01HGssFEAZHw0ZemQlVmuqY2l2Vu9zYalqT2tpXyl0ejozJjAZemQlVmuqY2l2Vu9zWalmbGe6HRsicyw3T2wkVw9kVybxVyhiKjAZemJ1Y3QrXu9kVyVlXnJpbmudcyw3ejoDHShxFGB5UTbdXy9kWyVpVTeiKjeZemtlVnQdVmwIVu95UTbdXalDWTOiKjh4FGBrbmuxYmlkVRe6bvB1VT0ZcxBkVytgcu90WyJIejo3FGBiX2Q5T29sbalrXnHiKjeZemQlVmuqY2l2Vu9sWTQjWGe6JRsib2w5T2Jrby50ejo3FGBDX2QpVmllYl9ZVyV0ejo0HRsiVmwIVu95UTbdXalDWTOiKjh4FGBkVyVlXnJpbmudbaljW3HiKjUZemQlVmuqY2l2Vu95UTYiKjOZem1rValmWyuxT3BpV2g0ejoDHSfZemJ1Y3QrXu9kVyVlXnJpbmudYal0U2fiKjLsFGBxWybobw9mUyDlT3lgb19ZWy1pbGe6JSfZenbgcu9kVyYiKlZDHSkZHzLZFSOZHjAZFSLxFEH0FG05TRsiVaumVy5zWTVlT3JsWy5dXalDWTOiKjH2HGsiVaumVy5zWTVlT3JoWyV0ejotFGB5UTbdUyQkT2QlV3BlVRe6HGsiU3uzba9DT2QlVmuqY2l2Vu95UTYiKi0tJEfZenlgb19DX2QpVmllYie6JGsiXaumbw9mUyDlT3lgb19ZWy1pbGe6JSfZem92VTBxWyQlejp0Ynuldu0=]])
                    self.is_preset = current_preset
                end
            end
        end
    end,
    nfl_trace = function(length)
        local origin = entity.get_local_player():get_abs_origin()
        local max_radias = math.pi * 2
        local step = max_radias / 8
    
        for a = 0, max_radias, step do
            local ptX, ptY = ((10 * math.cos(a)) + origin.x), ((10 * math.sin(a)) + origin.y)
            local trace = utils.trace_line(vector(ptX, ptY, origin.z), vector(ptX, ptY, origin.z-length), 0x600400B, entity.get_local_player())
    
            if trace.fraction ~= 1 then
                return true
            end
        end
        return false
    end,
    no_fall_damage = false,
    tweaks = function(self, ctx)
        local lp = entity.get_local_player()
        if not lp or not lp:is_alive() or not rage.get_antiaim_target() then self.backstab = false return end
        if menu.aa.avoid_backstab:get() and rage.get_antiaim_target() then 
            for i = 1, globals.max_players do
                local ent = entity.get(i)
                if ent and ent:is_enemy() and not ent:is_dormant() and ent:is_alive() then
                    local weap = ent:get_active_weapon()
                    local hb_pos = ent:get_hitbox_position(3)
                    local dist = lp:get_abs_origin():dist(ent:get_abs_origin())
                    self.backstab = hb_pos and weap and weap:is_knife() and dist < 256
                end
            end
        else
            self.backstab = false
        end

        if menu.aa.fast_ladder:get() then
            local lp_ptr = lp:ptr()
            if not lp_ptr then return end

            if ffi.cast('int*', lp_ptr + 604)[0] == 9 then -- m_nMoveType
                local move_x = ctx.move.x
                if move_x == 0 then return end

                ctx.viewangles.yaw = ctx.viewangles.yaw + 90
                ctx.viewangles.pitch = 89

                if move_x > 1 then
                    ctx.buttons = bit.bor(ctx.buttons, 4260880)
                elseif move_x < -1 then
                    ctx.buttons = bit.bor(ctx.buttons, 4260360)
                end
            end
        end

        if menu.aa.no_fall_damage:get() then
            if lp['m_vecVelocity[2]'] >= -500 then
                self.no_fall_damage = false
            else
                if self.nfl_trace(15) then
                    self.no_fall_damage = false
                elseif self.nfl_trace(75) then
                    self.no_fall_damage = true
                end
            end
            if lp['m_vecVelocity[2]'] < -500 then
                if self.no_fall_damage then
                    ctx.buttons = bit.bor(bit.band(ctx.buttons, 0x2000000), 4)
                else
                    ctx.buttons = bit.band(ctx.buttons, 0x2000000)
                end
            end
        end
    end
}
menu.aa.import:set_callback(function()
    if antiaim.is_preset ~= '' then
        angelwave_push:paint(8, 'you are using preset, disable it to import anti-aim data')
        utils.console_exec('play ui/menu_invalid.wav')
        return 
    end
    is_ZALUPA_executing = true
end)
menu.aa.export:set_callback(function()
    if antiaim.is_preset ~= '' then
        angelwave_push:paint(8, 'you are using preset, disable it to export anti-aim data')
        utils.console_exec('play ui/menu_invalid.wav')
        return 
    end
    is_PARASHA_executing = true
end)
utils.set_keybind_callback(menu.aa.manual_left, function(bool)
    menu.aa.manual_back:set(false)
    menu.aa.manual_right:set(false)
    menu.aa.manual_forward:set(false)
    antiaim.direction.last_pressed = bool and -90 or -1
end)
utils.set_keybind_callback(menu.aa.manual_back, function(bool)
    menu.aa.manual_left:set(false)
    menu.aa.manual_right:set(false)
    menu.aa.manual_forward:set(false)
    antiaim.direction.last_pressed = bool and 0 or -1
end)
utils.set_keybind_callback(menu.aa.manual_right, function(bool)
    menu.aa.manual_back:set(false)
    menu.aa.manual_left:set(false)
    menu.aa.manual_forward:set(false)
    antiaim.direction.last_pressed = bool and 90 or -1
end)
utils.set_keybind_callback(menu.aa.manual_forward, function(bool)
    menu.aa.manual_back:set(false)
    menu.aa.manual_left:set(false)
    menu.aa.manual_right:set(false)
    antiaim.direction.last_pressed = bool and 180 or -1
end)
local hitmarker = {}
local shot_info = {
    hitgroup_str = {
        [0] = 'generic',
        'head', 'chest', 'stomach',
        'left arm', 'right arm',
        'left leg', 'right leg',
        'neck', 'generic', 'gear'
    },
    shots = {},
    render = function(self)
        if menu.visual.logs:get() and globals.is_in_game then
        local render_offset = 0
        local default_alpha = 255 / 255
        for i, log in ipairs(self.shots) do
            if i > 10 and log.expiry_time > globals.realtime then
                log.expiry_time = globals.realtime
            end
            local fraction = 1
            if globals.realtime - log.expiry_time > 0 then
                fraction = 1 - (globals.realtime - log.expiry_time) * 5
            elseif globals.realtime - log.spawn_time < 0.2 then
                fraction = (globals.realtime - log.spawn_time) * 4
            end
            local alpha = fraction
            local shift = 12 * fraction
            if globals.realtime - log.expiry_time > 0.2 then
                table.remove(self.shots, i)
            else
                local text_size = render.measure_text(1, log.full_text).x
                local cursor_pos = vector(5, 5 * 0.75 + render_offset)

                for _, text in ipairs(log.text) do
                    local color = text[1]:clone()
                    render.text(fonts.verdana, cursor_pos, color:alpha_modulatef(alpha), "d", text[2])
                    cursor_pos.x = cursor_pos.x + render.measure_text(fonts.verdana, text[2]).x
                end

                render_offset = render_offset + shift
            end
        end
        end
    end,
    on_shot = function(self, shot)
        if globals.is_in_game then
        if shot.damage > 0 then
            return
        end
        local hitchance = shot.hitchance* 100
        local backtrack = shot.backtrack
        local accent = color(menu.visual.logs_color:get().r,menu.visual.logs_color:get().g,menu.visual.logs_color:get().b,255)
        local miss_reason = shot.miss_reason
        local full_text = string.format("missed shot due to %s", miss_reason)
        local text = {
            {accent, "\x20" .. "etnasy.gg - "},
            {color(255,255,255,255), " Missed shot due to"},
            {accent, "\x20" .. miss_reason},
            {color(255,255,255,255), " ("},
            {accent, "" .. math.floor(hitchance)},
            {color(255,255,255,255), "% | history: "},
            {accent, "\x20" .. math.floor(backtrack)},
            {color(255,255,255,255), " tick)"}
        }
        if menu.visual.notifyx_x:get() and menu.visual.notify_condition:get(1) then
        angelwave_push:paint(4,full_text)
    end
    if menu.visual.logs:get() then
        table.insert(self.shots, 1, {
            spawn_time = globals.realtime,
            expiry_time = globals.realtime + 5,
            full_text = full_text,
            text = text
        })
    end
        end
    end,
    on_event = function(self, event)
        if event:get_name() ~= "player_hurt" then
            return
        end
        local attacker = entity.get(event.attacker, true)

        if attacker ~= entity.get_local_player() then
            return
        end

        local player = entity.get(event.userid, true)
        local accent = color(menu.visual.logs_color:get().r,menu.visual.logs_color:get().g,menu.visual.logs_color:get().b,255)
        local name = player:get_name()
        local group = self.hitgroup_str[event.hitgroup]
        local damage = event.dmg_health
        local health = event.health
        local weapon = event.weapon
        local full_text, text
        if group == "generic" then
            local word = "Hurt"
            if weapon == "taser" then
                word = "Zeused"
            elseif weapon == "hegrenade" then
                word = "Naded"
            elseif weapon == "inferno" then
                word = "Burned"
            elseif weapon == "knife" then
                word = "Knifed"
            end
            full_text = string.format("%s %s for %d damage (%d health remaining)", word:lower(), name:lower(), damage, health)
            text = {
                {accent, "\x20" .."etnasy.gg - "},
                {color(255,255,255,255), "\x20" .. word},
                {accent, "\x20" .. name},
                {color(255,255,255,255), "\x20" .."for"},
                {accent, "\x20" .. damage},
                {color(255,255,255,255), "\x20" .. "damage ("},
                {accent, tostring(health)},
                {color(255,255,255,255), "\x20" .. "health remaining)"}
            }
        else
            full_text = string.format("hit %s's %s for %d damage (%d health remaining)", name:lower(), group, damage, health)
            text = {
                {accent, "\x20" .. "etnasy.gg - "},
                {color(255,255,255,255), " Hit"},
                {accent, "\x20" .. name},
                {color(255,255,255,255), "'s "},
                {accent, "\x20" .. group},
                {color(255,255,255,255), " for"},
                {accent, "\x20" .. damage},
                {color(255,255,255,255), " damage ("},
                {accent, tostring(health)},
                {color(255,255,255,255), " health remaining)"}
            }
        end
        if menu.visual.notifyx_x:get() and menu.visual.notify_condition:get(0) then
             angelwave_push:paint(4,full_text)
        end
        if menu.visual.logs:get() then
        table.insert(self.shots, 1, {
            spawn_time = globals.realtime,
            expiry_time = globals.realtime + 5,
            full_text = full_text,
            text = text
        }  
        )
    end
end,
    hitmarker_table = function(shot)
        if globals.is_in_game then
            if shot.damage > 0 then
                local hit_pos2 = shot.hit_point
                table.insert(hitmarker, {shot_pos = hit_pos2, times = globals.curtime})
            end
        end
    end
}

local animation_slowdown = { x_add = 0, rectfill = 0, alpha = 0 }
local animation_defensive = { x_add = 0, rectfill = 0, alpha = 0 }
local slowing = draggable:new("slow_down", vector(main.screen_size.x/2 - 100, main.screen_size.y/2-300), vector(200, 100))
local defensive_ = draggable:new("defensive_drag", vector(main.screen_size.x/2 - 100, main.screen_size.y/2-400), vector(200, 100))

local widgets = {
    keybinds = {
        drag = draggable:new("keybinds"),
        modes = {"holding", "toggled", "always on"},
        alpha = 0,
        width = 120,
        anims = {},
        render = function(self)
            if not (menu.visual.enable_interface:get() and menu.visual.interface_additional:get(1) and globals.is_in_game) then return end

            local binds = ui.get_binds()
            local should_draw = false
            local draw_list = {}
            local cursor_pos = 0
            local new_width = 145
            for i = 1, #binds do
                bind = binds[i]
                local bind_name = bind:get_name()
                if bind_name == "Peek Assist key" then
                    bind_name = "Peek Assist"
                end
                if bind:get_key() ~= 0 and bind_name ~= "Force thirdperson" and bind:get_mode() ~= 2 then
                    if bind_name == "Double Tap" then
                        bind_name = "Double tap"
                    end
                    if bind_name == "Hide Shots" then
                        bind_name = "On shot anti-aim"
                    end
                    if bind_name == "Force Body Aim" then
                        bind_name = "Force body aim"
                    end
                    if bind_name == "Peek Assist" then
                        bind_name = "Quick peek assist"
                    end
                    if bind_name == "Min. damage override" then
                        bind_name = "Damage override"
                    end
                    if bind_name == "Fake duck" then
                        bind_name = "Duck peek assist"
                    end
                    if bind_name == "Slow walk" then
                        bind_name = "Slow motion"
                    end
                    if bind_name == "» left direction" then
                        bind_name = "Left direction"
                    end
                    if bind_name == "» right direction" then
                        bind_name = "Right direction"
                    end
                    if bind_name == "» back direction" then
                        bind_name = "Back direction"
                    end
                    if bind_name == "» forward direction" then
                        bind_name = "Forward direction"
                    end
                    if self.anims[bind_name] == nil then
                        self.anims[bind_name] = 0
                    end
                    local enabled = bind:get()
                    if enabled or ui.is_open() then
                        should_draw = true
                    end
                    self.anims[bind_name] = math.anim(self.anims[bind_name], enabled and 1 or 0, 30)
                    local alpha = self.anims[bind_name]

                    if alpha > 0.01 then
                        local bind_mode = "[" .. self.modes[bind:get_mode() + 1] .. "]"
                        local text_size = render.measure_text(1, bind_name .. bind_mode).x + 15
                        if text_size > new_width then
                            new_width = text_size
                        end
                        table.insert(draw_list, {bind_name, cursor_pos, alpha, bind_mode})
                        cursor_pos = cursor_pos + 14 * alpha
                    end
                end
            end
            self.alpha = math.anim(self.alpha, should_draw and 1 or 0, 16)
            self.width = math.anim(self.width, new_width, 16)
            if self.alpha < 0.01 then
                return
            end
            self.drag:update(vector(self.width, 20))
            local pos = self.drag:get()
            
            render.rect(pos, pos + vector(self.width, 2), menu.visual.interface_color:get():alpha_modulate(255 * self.alpha))
            if menu.visual.interface_mode:get() == 0 then
                render.rect(pos + vector(0, 2), pos + vector(self.width, 20), color(17, math.floor(menu.visual.interface_color:get().a * self.alpha)))
            elseif menu.visual.interface_mode:get() == 1 then
                render.gradient(pos + vector(0, 2), pos + vector(self.width, 20), menu.visual.interface_color:get():alpha_modulate(menu.visual.interface_color:get().a * self.alpha), menu.visual.interface_color:get():alpha_modulate(menu.visual.interface_color:get().a * self.alpha), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,0* self.alpha), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,0* self.alpha))
            end
            render.text(fonts.verdana, pos + vector(self.width * 0.5, 4), color(255, self.alpha * 255), "cd", "keybinds")

            for _, cmd in ipairs(draw_list) do
                render.text(fonts.verdana, pos + vector(5, 22 + cmd[2]), color(255, cmd[3] * 255), "d", cmd[1])
                render.text(fonts.verdana, pos + vector(self.width - 5 - render.measure_text(1, cmd[4]).x, 22 + cmd[2]), color(255, cmd[3] * 255), "d", cmd[4])
            end
        end
    },
    watermark = {
        render = function()
            if not (menu.visual.enable_interface:get() and menu.visual.interface_additional:get(0)) then return end

            local net_channel = utils.get_net_channel()
            local system_time = utils.get_date()
            local system_time_string = string.format("%02d:%02d:%02d", system_time.hour, system_time.minute, system_time.second)


            local text = "etnasy.gg | " .. main.steamname .. " | " .. system_time_string
            
            if globals.is_in_game then
                  local ping = net_channel:get_latency(0)*1000 
                  text = "etnasy.gg | " .. main.steamname .. (net_channel:is_loopback() and " | loopback | " or " | delay: " .. math.floor(ping) .. "ms | ") .. system_time_string
            end
            
            local text_size = render.measure_text(fonts.verdana, text)
            render.rect(vector(main.screen_size.x - 10, 8), vector(main.screen_size.x - 20, 22) - text_size, color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,255))
            if menu.visual.interface_mode:get() == 0 then
                render.rect(vector(main.screen_size.x - 10, 10), vector(main.screen_size.x - 20, 40) - text_size, color(21,21,21,menu.visual.interface_color:get().a))
            elseif menu.visual.interface_mode:get() == 1 then
                render.gradient(vector(main.screen_size.x - 10, 10), vector(main.screen_size.x - 20, 40) - text_size, menu.visual.interface_color:get(), menu.visual.interface_color:get(), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,0), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,0))
            end
            render.text(fonts.verdana, vector(main.screen_size.x - 15, 24) - text_size, color(255, 255, 255, 255), "d", text)
        end
    },
    panel = {
        render = function()
            if not (menu.visual.enable_interface:get() and menu.visual.interface_additional:get(2) and globals.is_in_game) then return end

            if menu.visual.interface_panelposition:get() == 0 then
                render.text(fonts.verdana, vector(80, main.screen_size.y /2), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b, 255), "d", string.format("[ALPHA]", info.build:upper()))
                --render.text(fonts.verdana, vector(36, main.screen_size.y /2), color(205, 205, 205, 255), "d", "GAME")
                enchantedTextEffect(fonts.verdana, 5,main.screen_size.y /2, color(205,205,205,255), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,255), "d", "GAMESENSE.PL", 1)
            elseif menu.visual.interface_panelposition:get() == 1 then
                render.text(fonts.verdana, vector(info.build == 'stable' and main.screen_size.x - 46 or main.screen_size.x - 34, main.screen_size.y /2), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b, 255), "d", string.format("[%s]", info.build:upper()))
                --render.text(fonts.verdana, vector(info.build == 'stable' and main.screen_size.x - 76 or main.screen_size.x - 64, main.screen_size.y /2), color(205, 205, 205, 255), "d", "GAME")
                --enchantedTextEffect(fonts.verdana, info.build == 'stable' and main.screen_size.x - 107 or main.screen_size.x - 95, main.screen_size.y /2, color(205,205,205,255), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,255), "d", "GAME", 1)
            elseif menu.visual.interface_panelposition:get() == 2 then
                render.text(fonts.verdana, vector(main.screen_size.x /2 + 15, main.screen_size.y - 15), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b, 255), "d", string.format("[%s]", info.build:upper()))
                --render.text(fonts.verdana, vector(main.screen_size.x /2 - 15, main.screen_size.y - 15), color(205, 205, 205, 255), "d", "GAME")
                --enchantedTextEffect(fonts.verdana, main.screen_size.x /2 - 46,main.screen_size.y - 15, color(205,205,205,255), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,255), "d", "GAME", 1)
            end
        end
   },
   alternative_wigets = {
        render = function()
            if not (menu.visual.enable_interface:get() and menu.visual.interface_additional:get(3) and globals.is_in_game) then return end

            local offset_with_watermark = menu.visual.interface_additional:get(0) and 25 or 0

            local net_channel = netchannel.get()
            local inputbytes = net_channel.got_bytes/2248
            local outputbytes = net_channel.sent_bytes/1024

            local text = "IO | "
            local text_size = render.measure_text(fonts.verdana, text)
            local accent = color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,255)

            if menu.visual.interface_mode:get() == 0 then
                render.rect(vector(main.screen_size.x - 140, 10 + offset_with_watermark), vector(main.screen_size.x - 70, 40 + offset_with_watermark) - text_size, color(21,21,21,menu.visual.interface_color:get().a))
            elseif menu.visual.interface_mode:get() == 1 then
                render.gradient(vector(main.screen_size.x - 140, 10 + offset_with_watermark), vector(main.screen_size.x - 70, 40 + offset_with_watermark) - text_size, menu.visual.interface_color:get(), menu.visual.interface_color:get(), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,0), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,0))
            end

            render.text(fonts.verdana, vector(main.screen_size.x - 118, 24 + offset_with_watermark) - text_size, color(255, 255, 255, 255), "d", text)

            render.gradient(vector(main.screen_size.x - 113, 24 + offset_with_watermark), vector(main.screen_size.x - 108, 19 + offset_with_watermark), accent, accent, accent:alpha_modulate(0), accent:alpha_modulate(0))
            render.gradient(vector(main.screen_size.x - 108, 24 + offset_with_watermark), vector(main.screen_size.x - 103,  20 - inputbytes/4 + offset_with_watermark), accent, accent, accent:alpha_modulate(0), accent:alpha_modulate(0))
            render.gradient(vector(main.screen_size.x - 103, 24 + offset_with_watermark), vector(main.screen_size.x - 98, 17 + offset_with_watermark), accent, accent, accent:alpha_modulate(0), accent:alpha_modulate(0))
            render.gradient(vector(main.screen_size.x - 98, 24 + offset_with_watermark), vector(main.screen_size.x - 93, 11 + outputbytes/2 + offset_with_watermark), accent, accent, accent:alpha_modulate(0), accent:alpha_modulate(0))

            local text_for_another = string.format('%sms | %shz', math.floor(net_channel.loss*100), main.hz)
            local text_size_for_another = render.measure_text(fonts.verdana, text_for_another)

            if menu.visual.interface_mode:get() == 0 then
                render.rect(vector(main.screen_size.x - 17, 22+ offset_with_watermark) - text_size_for_another, vector(main.screen_size.x - 10, 28+ offset_with_watermark) , color(21,21,21,menu.visual.interface_color:get().a))
            elseif menu.visual.interface_mode:get() == 1 then
                render.gradient(vector(main.screen_size.x - 17, 22+ offset_with_watermark) - text_size_for_another, vector(main.screen_size.x - 10, 28+ offset_with_watermark), menu.visual.interface_color:get(), menu.visual.interface_color:get(), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,0), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,0))
            end
            render.text(fonts.verdana, vector(main.screen_size.x - 14, 24+ offset_with_watermark) - text_size_for_another, color(255,255,255, 255), "d", text_for_another)
            render.gradient(vector(main.screen_size.x - 18, 41+ offset_with_watermark) - text_size_for_another, vector(main.screen_size.x - 41, 28+ offset_with_watermark), accent:alpha_modulate(0), accent, accent:alpha_modulate(0), accent)
            render.gradient(vector(main.screen_size.x - 41, 29+ offset_with_watermark), vector(main.screen_size.x - 10, 28+ offset_with_watermark), accent, accent:alpha_modulate(0), accent, accent:alpha_modulate(0))
        end
    },
    defensive_indicator = {
        defensive_icon = render.load_image(defensive_link, vector(19, 17)),
        render = function(self)
            if not (menu.visual.enable_interface:get() and menu.visual.interface_additional:get(4) and globals.is_in_game) then return end
            local velmodifier; if not velmodifier then velmodifier = 0 end

            if rage.get_exploit_charge() == 1 and (rage.get_defensive_ticks() > 0 or antiaim.defensive.ctx_force) then
                velmodifier = math.clamp(0.1, 0.9, rage.get_defensive_ticks() / 13)
            else velmodifier = 0 end
            if ui.is_open() then velmodifier = 0.5 end
    
            if animation_defensive.rectfill == 0 then animation_defensive.rectfill = 105 * velmodifier end
            animation_defensive.alpha = math.lerp(animation_defensive.alpha, ((velmodifier > 0 and entity.get_local_player() and entity.get_local_player():is_alive()) or ui.is_open()) and 255 or 0, 5 * globals.frametime)
            defensive_:update(nil, main.screen_size.x/2 - 80)
            local pos = vector(defensive_:get().x, defensive_:get().y-10)
            animation_defensive.rectfill = math.lerp(animation_defensive.rectfill, -60 * velmodifier, 10 * globals.frametime)
            
            local text_size_slowdown = render.measure_text(fonts.verdana, "defensive ~ "..math.floor(velmodifier*100).."%")
            renderer.rounded_shadow(vector(main.screen_size.x/2 - text_size_slowdown.x + text_size_slowdown.x/2 - 25, pos.y + 56), vector(main.screen_size.x/2 + (text_size_slowdown.x - text_size_slowdown.x /2)-45 + 67, pos.y + 80), menu.visual.interface_color:get():alpha_modulate(25 * (animation_defensive.alpha/255)), 5, 7)
            render.rect(vector(main.screen_size.x/2 - text_size_slowdown.x + text_size_slowdown.x/2 - 5, pos.y + 56), vector(main.screen_size.x/2 + (text_size_slowdown.x - text_size_slowdown.x /2) + 20, pos.y + 80), color(35,35,35, 255 * (animation_defensive.alpha/255)), 6)
                
            render.push_clip_rect(vector(main.screen_size.x/2 - text_size_slowdown.x + text_size_slowdown.x/2 - 56, pos.y + 56), vector(main.screen_size.x/2 - text_size_slowdown.x + text_size_slowdown.x/2, pos.y + 80))
            render.rect(vector(main.screen_size.x /2 - text_size_slowdown.x + text_size_slowdown.x/2 -25, pos.y + 56), vector(main.screen_size.x/2 + (text_size_slowdown.x - text_size_slowdown.x /2.5)-141 + 65, pos.y + 80), color(50,50,50, 255 * (animation_defensive.alpha/255)), 6)
            render.pop_clip_rect()
    
            render.rect(vector(main.screen_size.x/2 - text_size_slowdown.x + text_size_slowdown.x/2 + 10, pos.y + 73), vector(main.screen_size.x/2 - text_size_slowdown.x/6 - 2 + 61, pos.y + 75), color(15, 15, 15, 255 * (animation_defensive.alpha/255)))
            render.rect(vector(main.screen_size.x/2 - text_size_slowdown.x + text_size_slowdown.x/2 + 10, pos.y + 73), vector(main.screen_size.x/2 - text_size_slowdown.x/6 - 2 - animation_defensive.rectfill, pos.y + 75), menu.visual.interface_color:get():alpha_modulate(255 * (animation_defensive.alpha/255)))
            render.rect(vector(main.screen_size.x/2 - text_size_slowdown.x + text_size_slowdown.x/2 - 2, pos.y + 56), vector(main.screen_size.x/2 - text_size_slowdown.x + text_size_slowdown.x/2, pos.y + 80), menu.visual.interface_color:get():alpha_modulate(255 * (animation_defensive.alpha/255)))
            if self.defensive_icon then render.texture(self.defensive_icon, vector(main.screen_size.x /2 - text_size_slowdown.x + text_size_slowdown.x /2 - 22, pos.y + 59), color():alpha_modulate(255 * (animation_defensive.alpha/255))) end
            render.text(fonts.verdana, vector(main.screen_size.x /2 + 9, pos.y + 58), color(255, 255, 255, 255 * (animation_defensive.alpha/255)), 'dc', "defensive ~ "..math.floor(velmodifier*100).."%")
        end
    },
    slowed_down_indicator = {
        slowed_icon = render.load_image(slowed_link, vector(19, 17)),
        render = function(self)
        if not (menu.visual.slowed_down:get() and globals.is_in_game) then return end
            local velmodifier = entity.get_local_player()["m_flVelocityModifier"]
            if velmodifier == 1 and ui.is_open() then velmodifier = 0.5 end

            if animation_slowdown.rectfill == 0 then animation_slowdown.rectfill = 105 * velmodifier end
            animation_slowdown.alpha = math.lerp(animation_slowdown.alpha, (velmodifier ~= 1 and entity.get_local_player() and entity.get_local_player():is_alive() or ui.is_open()) and 255 or 0, 10 * globals.frametime)
            slowing:update(nil, main.screen_size.x/2 - 80)
            local pos = vector(slowing:get().x, slowing:get().y-10)
            animation_slowdown.rectfill = math.lerp(animation_slowdown.rectfill, -60 * velmodifier, 10 * globals.frametime)
            
            if menu.visual.slowed_down_style:get() == 0 then
                local text_size_slowdown = render.measure_text(fonts.verdana, "recovery ~ "..math.floor(velmodifier*100).."%")
                renderer.rounded_shadow(vector(main.screen_size.x/2 - text_size_slowdown.x + text_size_slowdown.x/2 - 25, pos.y + 56), vector(main.screen_size.x/2 + (text_size_slowdown.x - text_size_slowdown.x /2)-45 + 67, pos.y + 80), menu.visual.interface_color:get():alpha_modulate(25 * (animation_slowdown.alpha/255)), 5, 7)
                render.rect(vector(main.screen_size.x/2 - text_size_slowdown.x + text_size_slowdown.x/2 - 5, pos.y + 56), vector(main.screen_size.x/2 + (text_size_slowdown.x - text_size_slowdown.x /2) + 20, pos.y + 80), color(35,35,35, 255 * (animation_slowdown.alpha/255)), 6)
                
                render.push_clip_rect(vector(main.screen_size.x/2 - text_size_slowdown.x + text_size_slowdown.x/2 - 56, pos.y + 56), vector(main.screen_size.x/2 - text_size_slowdown.x + text_size_slowdown.x/2, pos.y + 80))
                render.rect(vector(main.screen_size.x /2 - text_size_slowdown.x + text_size_slowdown.x/2 -25, pos.y + 56), vector(main.screen_size.x/2 + (text_size_slowdown.x - text_size_slowdown.x /2.5)-141 + 65, pos.y + 80), color(50,50,50, 255 * (animation_slowdown.alpha/255)), 6)
                render.pop_clip_rect()

                render.rect(vector(main.screen_size.x/2 - text_size_slowdown.x + text_size_slowdown.x/2 + 10, pos.y + 73), vector(main.screen_size.x/2 - text_size_slowdown.x/6 - 2 + 61, pos.y + 75), color(15, 15, 15, 255 * (animation_slowdown.alpha/255)))
                render.rect(vector(main.screen_size.x/2 - text_size_slowdown.x + text_size_slowdown.x/2 + 10, pos.y + 73), vector(main.screen_size.x/2 - text_size_slowdown.x/6 - 2 - animation_slowdown.rectfill, pos.y + 75), menu.visual.interface_color:get():alpha_modulate(255 * (animation_slowdown.alpha/255)))
                render.rect(vector(main.screen_size.x/2 - text_size_slowdown.x + text_size_slowdown.x/2 - 2, pos.y + 56), vector(main.screen_size.x/2 - text_size_slowdown.x + text_size_slowdown.x/2, pos.y + 80), menu.visual.interface_color:get():alpha_modulate(255 * (animation_slowdown.alpha/255)))
                if self.slowed_icon then render.texture(self.slowed_icon, vector(main.screen_size.x /2 - text_size_slowdown.x + text_size_slowdown.x /2 - 22, pos.y + 59), color():alpha_modulate(255 * (animation_slowdown.alpha/255))) end
                render.text(fonts.verdana, vector(main.screen_size.x /2 + 9, pos.y + 58), color(255, 255, 255, 255 * (animation_slowdown.alpha/255)), 'dc', "recovery ~ "..math.floor(velmodifier*100).."%")
            else
                local text_size_slowdown = render.measure_text(fonts.verdana, "velocity decreased ~ "..math.floor(velmodifier*100).."%")
                render.rect(vector(main.screen_size.x/2 - text_size_slowdown.x + 55, pos.y + 56), vector(main.screen_size.x/2 + text_size_slowdown.x -110 -animation_slowdown.rectfill, pos.y + 58) , color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,255 * (animation_slowdown.alpha/255)))
                if menu.visual.interface_mode:get() == 0 then
                    render.rect(vector(main.screen_size.x/2 - text_size_slowdown.x + 55, pos.y + 80), vector(main.screen_size.x/2 + text_size_slowdown.x - 55, pos.y + 58) , color(21,21,21,menu.visual.interface_color:get().a * (animation_slowdown.alpha/255)))
                elseif menu.visual.interface_mode:get() == 1 then
                    render.gradient(vector(main.screen_size.x/2 - text_size_slowdown.x + 55, pos.y + 80), vector(main.screen_size.x/2 + text_size_slowdown.x - 55, pos.y + 58), menu.visual.interface_color:get():alpha_modulate(0), menu.visual.interface_color:get():alpha_modulate(0), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,menu.visual.interface_color:get().a* (animation_slowdown.alpha/255)), color(menu.visual.interface_color:get().r,menu.visual.interface_color:get().g,menu.visual.interface_color:get().b,menu.visual.interface_color:get().a* (animation_slowdown.alpha/255)))
                end
                render.text(fonts.verdana, vector(main.screen_size.x /2, pos.y + 62), color(255, 255, 255, 255 * (animation_slowdown.alpha/255)), 'dc', "velocity decreased ~ "..math.floor(velmodifier*100).."%")
            end
        end
    }
}

local anim_num = 0
local scoped = 0
local m_alpha = 0
local visual_functions = {
    indicators_classic = {
        render = function()
           if not (menu.visual.enable_indicators:get() and menu.visual.indicators_mode:get() == 0 and globals.is_in_game and entity.get_local_player():is_alive()) then return end
           local isinscope = entity.get_local_player()['m_bIsScoped']
   
           if isinscope == true then scoped = 1 else scoped = 0 end
           local accent = color(menu.visual.indicators_color:get().r,menu.visual.indicators_color:get().g,menu.visual.indicators_color:get().b,255)
           local accent_gradient = color(menu.visual.indicators_color:get().r /1.2,menu.visual.indicators_color:get().g /1.2,menu.visual.indicators_color:get().b /1.2,180)
           local animation_offset = 29
           anim_num = math.lerp(anim_num, scoped, 17 * globals.frametime)
           animation_offset = 1 and animation_offset * anim_num or animation_offset
           local add_y = 0
           local condit = get_cond():gsub("*", "")
           if condit == "aero-crouch" then condit = "air+duck" end
           if condit == "aero" then condit = "air" end
           if condit == nil then return end 
           local textcond = render.measure_text(fonts.pixel, "-".. condit .. "-").x /2
           if condit == "slow" then
               textcond = render.measure_text(fonts.pixel, "-".. condit .. "-").x /2 + 1
           end
           local animation_offset1 = textcond + 6
           animation_offset1 = 1 and animation_offset1 * anim_num or animation_offset1
   
           local animation_offset2 = 11
           anim_num = math.lerp(anim_num, scoped, 17 * globals.frametime)
           animation_offset2 = 1 and animation_offset2 * anim_num or animation_offset2
           
           local animation_offset3 = 14
           animation_offset3 = 1 and animation_offset3 * anim_num or animation_offset3

           local animation_offset4 = 16
           animation_offset4 = 1 and animation_offset4 * anim_num or animation_offset4

              -- @main text
           local chargecolor = color(253, 34, 56, 255)
           if rage.get_exploit_charge() >= 1 then chargecolor = color(255, 255, 255, 255) end
            local text_size = render.measure_text(fonts.pixel, 'etnasy.gg')
              renderer.rounded_shadow(vector(main.screen_size.x /2 + animation_offset - (text_size.x / 2), main.screen_size.y/2 + 25), vector(main.screen_size.x /2 + animation_offset + (text_size.x / 2), main.screen_size.y/2 + 25 + text_size.y),menu.visual.indicators_color:get():alpha_modulate(menu.visual.indicators_color:get().a/6), 2, 5)
            --render.rect(vector(main.screen_size.x /2 + animation_offset - (text_size.x / 2), main.screen_size.y/2 + 25), vector(main.screen_size.x /2 + animation_offset + (text_size.x / 2), main.screen_size.y/2 + 25 + text_size.y), color())
              render.text(fonts.pixel, vector(main.screen_size.x /2 + animation_offset, main.screen_size.y/2 + 25), color(255,255,255, 255), "oc", "etnasy.gg")
              render.text(fonts.pixel, vector(main.screen_size.x /2 + animation_offset, main.screen_size.y/2 + 25), color(255,255,255, 255), "oc", "etnasy.gg")
              enchantedTextEffect(fonts.pixel, main.screen_size.x /2 - 23+ animation_offset,main.screen_size.y/2 + 25, color(40,40,40, 255), accent, "o", "etnasy.gg",1.8)

              render.text(fonts.pixel, vector(main.screen_size.x /2 + animation_offset1, main.screen_size.y/2 + 34), accent, "oc", "-".. condit .. "-")
              render.text(fonts.pixel, vector(main.screen_size.x /2 + animation_offset1, main.screen_size.y/2 + 34), accent, "oc", "-".. condit .. "-")
              render.text(fonts.pixel, vector(main.screen_size.x /2 + animation_offset1, main.screen_size.y/2 + 34), accent, "oc", "-".. condit .. "-")

              -- @main indicators
              if ui.find("Aimbot", "Aimbot", "Force Body Aim"):get() then
                render.text(fonts.pixel, vector(main.screen_size.x /2 + animation_offset4, main.screen_size.y/2 + 43 +add_y), color(255,255,255,255), "oc", "body")
                render.text(fonts.pixel, vector(main.screen_size.x /2 + animation_offset4, main.screen_size.y/2 + 43 +add_y), color(255,255,255,255), "oc", "body")
                render.text(fonts.pixel, vector(main.screen_size.x /2 + animation_offset4, main.screen_size.y/2 + 43 +add_y), color(255,255,255,255), "oc", "body")
                add_y = add_y + 9
             end
             if ui.find("Aimbot", "Aimbot", "Force safepoint"):get() then
                render.text(fonts.pixel, vector(main.screen_size.x /2 + animation_offset4, main.screen_size.y/2 + 43 +add_y), color(255,255,255,255), "oc", "safe")
                render.text(fonts.pixel, vector(main.screen_size.x /2 + animation_offset4, main.screen_size.y/2 + 43 +add_y), color(255,255,255,255), "oc", "safe")
                render.text(fonts.pixel, vector(main.screen_size.x /2 + animation_offset4, main.screen_size.y/2 + 43 +add_y), color(255,255,255,255), "oc", "safe")
                add_y = add_y + 9
             end
             if ui.find("Aimbot", "Aimbot", "Min. damage override"):get() then
                render.text(fonts.pixel, vector(main.screen_size.x /2 + animation_offset3, main.screen_size.y/2 + 43 +add_y), color(255,255,255,255), "oc", "dmg")
                render.text(fonts.pixel, vector(main.screen_size.x /2 + animation_offset3, main.screen_size.y/2 + 43 +add_y), color(255,255,255,255), "oc", "dmg")
                render.text(fonts.pixel, vector(main.screen_size.x /2 + animation_offset3, main.screen_size.y/2 + 43 +add_y), color(255,255,255,255), "oc", "dmg")
                add_y = add_y + 9
             end
              if ui.find("Aimbot", "Aimbot", "Double Tap"):get(0) then
                render.text(fonts.pixel, vector(main.screen_size.x /2 + animation_offset2, main.screen_size.y/2 + 43 + add_y), chargecolor, "oc", "dt")
                render.text(fonts.pixel, vector(main.screen_size.x /2 + animation_offset2, main.screen_size.y/2 + 43 + add_y), chargecolor, "oc", "dt")
                render.text(fonts.pixel, vector(main.screen_size.x /2 + animation_offset2, main.screen_size.y/2 + 43 + add_y), chargecolor, "oc", "dt")
                add_y = add_y + 9
            elseif ui.find("Aimbot", "Aimbot", "Hide Shots"):get(0) then
                render.text(fonts.pixel, vector(main.screen_size.x /2 + animation_offset2 , main.screen_size.y/2 + 43 + add_y), chargecolor, "oc", "os")
                render.text(fonts.pixel, vector(main.screen_size.x /2 + animation_offset2 , main.screen_size.y/2 + 43 + add_y), chargecolor, "oc", "os")
                render.text(fonts.pixel, vector(main.screen_size.x /2 + animation_offset2 , main.screen_size.y/2 + 43 + add_y), chargecolor, "oc", "os")
                add_y = add_y + 9
             end

        end
    },
        indicators_old = {
            render = function()
               if not (menu.visual.enable_indicators:get() and menu.visual.indicators_mode:get() == 1 and globals.is_in_game and entity.get_local_player():is_alive()) then return end
               local isinscope = entity.get_local_player()['m_bIsScoped']
       
               if isinscope == true then scoped = 1 else scoped = 0 end
               local accent = color(menu.visual.indicators_color:get().r,menu.visual.indicators_color:get().g,menu.visual.indicators_color:get().b,255)
               local add_y = 0

               local animation_offset = 29
               anim_num = math.lerp(anim_num, scoped, 17 * globals.frametime)
               animation_offset = 1 and animation_offset * anim_num or animation_offset
       
               local animation_offset1 = 10
               animation_offset1 = 1 and animation_offset1 * anim_num or animation_offset1
       
               local animation_offset2 = 15
               animation_offset2 = 1 and animation_offset2 * anim_num or animation_offset2

               local animation_offset3 = 13
               animation_offset3 = 1 and animation_offset3 * anim_num or animation_offset3

                  -- @main text
                  enchantedTextEffect(fonts.verdana, main.screen_size.x /2 - 25+ animation_offset,main.screen_size.y/2 + 25, color(25,25,25, 255), accent, "d", "etnasy.gg", 1)

                  -- @this shitty method bc with using space indicators have many free space
                  -- @main indicators
                  if ui.find("Aimbot", "Aimbot", "Double Tap"):get(0) then
                  render.text(fonts.pixel, vector(main.screen_size.x /2 + 1 + animation_offset1, main.screen_size.y/2 + 36 + add_y), accent, "oc", "dt")
                  add_y = add_y + 9
                  elseif ui.find("Aimbot", "Aimbot", "Hide Shots"):get(0) then
                  render.text(fonts.pixel, vector(main.screen_size.x /2 + 1 + animation_offset2 , main.screen_size.y/2 + 36 + add_y), accent, "oc", "osaa")
                  add_y = add_y + 9
                  end
                  if ui.find("Aimbot", "Aimbot", "Peek Assist key"):get(3) then
                    render.text(fonts.pixel, vector(main.screen_size.x /2  + 1 + animation_offset2, main.screen_size.y/2 + 36 + add_y), accent, "oc", "peek")
                    add_y = add_y + 9
                  end
                  if ui.find("Aimbot", "Aimbot", "Min. damage override"):get() then
                  render.text(fonts.pixel, vector(main.screen_size.x /2  + 1 + animation_offset3, main.screen_size.y/2 + 36 + add_y), accent, "oc", "dmg")
                  add_y = add_y + 9
                  end
                  if ui.find("Aimbot", "Aimbot", "Force safepoint"):get() then
                         render.text(fonts.pixel, vector(main.screen_size.x /2  + 1 + animation_offset2, main.screen_size.y/2 + 36 + add_y), accent, "oc", "safe")
                  add_y = add_y + 9
                  end
                    if ui.find("Aimbot", "Aimbot", "Force Body Aim"):get() then
                        render.text(fonts.pixel, vector(main.screen_size.x /2 + 1 + animation_offset2, main.screen_size.y/2 + 36 + add_y), accent, "oc", "baim")
                  add_y = add_y + 9
                  end
                  if ui.find("Anti aim", "Other", "Fake duck"):get(3) then
                  render.text(fonts.pixel, vector(main.screen_size.x /2 + 1 + animation_offset2, main.screen_size.y/2 + 36 + add_y), accent, "oc", "duck")
                  add_y = add_y + 9
                  end
            end
        },
        damage_shower = {
            render = function()
                if not (menu.visual.damage_shower:get() and globals.is_in_game and entity.get_local_player():is_alive()) then return end

                local lp = entity.get_local_player()
                if not lp then return end
                local lp_index = entity.get_local_player():ent_index()
                if not lp:is_alive() or not globals.is_in_game then return end
                local drawtype = 1
                if drawtype == 0 then return end

                local name_enable = ui.find("Player", "ESP", "Name"):get()


                entity.get_players(function(player)
                      if not player:is_alive() or player:ent_index() == lp_index or not player:is_enemy() then return end
                    local totalwidth = 0
                    local weapon = lp:get_active_weapon()
                    local weapon_og = weapon:weapon_index() or 0
                    if weapon_og == 0 then return end

                    local xy, xy1 = player:get_bounding_box()
                    --print(string.format('x: %s  |  y: %s  |  w: %s  |  h: %s', xy.x, xy.y, xy1.x, xy1.y))
                    if xy and xy1 then
                        local offset = {x = 0, y = 0}
                        if drawtype == 1 then
                            offset.y = name_enable and 14 or 4
                        end

                        local w223 = 0
                        local haha9mice = 0

                        -- weapon
                        if weapon_og==40 then w223=94;haha9mice=0.90 elseif weapon_og==1 or weapon_og==64 then w223=69;haha9mice=0.93 elseif weapon_og==2 then w223=22;haha9mice=0.92 elseif weapon_og==4 or weapon_og==32 or weapon_og==61 then w223=26;haha9mice=0.82 elseif weapon_og==7 or weapon_og==8 or weapon_og==10 or weapon_og==13 or weapon_og==14 or weapon_og==16 or weapon_og==28 or weapon_og==39 or weapon_og==60 then w223=38;haha9mice=0.95 elseif weapon_og==3 or weapon_og==30 or weapon_og==36 or weapon_og==63 then w223=41;haha9mice=0.80 elseif weapon_og==9 then w223=115;haha9mice=1 elseif weapon_og==11 or weapon_og==38 then w223=80;haha9mice=0.95 elseif weapon_og==17 or weapon_og==19 or weapon_og==23 or weapon_og==24 or weapon_og==26 or weapon_og==33 or weapon_og==34 then w223=27;haha9mice=0.77 elseif weapon_og==25 or weapon_og==27 or weapon_og==29 or weapon_og==35 then w223=55;haha9mice=0.66 else w223=65;haha9mice=1 end

                        local drawpos = {x = xy.x + (xy1.x - xy.x) / 2 - totalwidth / 2, y = (drawtype == 1 and xy.y - offset.y or xy1.y + offset.y)}
                        local min = drawtype == 1 and {x = drawpos.x + offset.x, y = drawpos.y} or {x = drawpos.x + offset.x, y = drawpos.y}
                        local max = drawtype == 1 and {x = drawpos.x + offset.x, y = drawpos.y} or {x = drawpos.x + Offset.x, y = drawpos.y}
                        local distance = player:get_abs_origin():dist(lp:get_abs_origin())

                        local aftercalculate_dmg = (w223 * math.pow(haha9mice, (distance * 0.002)))
                        if weapon_og == 9 then 
                            aftercalculate_dmg = w223
                        elseif aftercalculate_dmg > w223 then
                            aftercalculate_dmg = w223
                        end
        
                        local originmult = aftercalculate_dmg < 100 and 13 or 16
                        local fixnumber = aftercalculate_dmg < 100 and 2 or 0

                        local hp = player["m_iHealth"]
                        local esp_alpha = player:get_esp_alpha() * 255
                        if esp_alpha < 0 then esp_alpha = 0 end
                        local aftercalculate_dmg_size = render.measure_text(fonts.verdana_bold, tostring(math.floor(aftercalculate_dmg)))

                        local center_position = (min.x + (max.x - min.x) - aftercalculate_dmg_size.x/3)
                        local centered_position = aftercalculate_dmg < 100 and center_position or center_position + 2
                        render.text(fonts.verdana_bold, vector(centered_position - originmult + 4, min.y - 10), color(255, 255, 255, esp_alpha), 'd', '-')
                        render.text(fonts.verdana_bold, vector(centered_position - originmult + 10, min.y - 10), (hp >= aftercalculate_dmg and color(255, 255, 255, esp_alpha) or color(253, 69, 106, esp_alpha)), 'd', tostring(math.floor(aftercalculate_dmg)))
                        render.text(fonts.verdana_bold, vector(centered_position - originmult + aftercalculate_dmg_size.x + (aftercalculate_dmg < 100 and 11 or 12), min.y - 10), color(255, 255, 255, esp_alpha), 'd', '-')
                            
                    end
                end)
            end
        },
        kibit_hitmarker = {
            render = function()
               if not (menu.visual.kibitmarker:get() and globals.is_in_game) then return end
               for _, a in pairs(hitmarker) do
                if globals.curtime <= a.times + 2 then
                        local pos3 = render.world_to_screen(a.shot_pos)
                        if pos3 then
                            if menu.visual.kibitmarker_mode:get() == 0 then 
                                render.rect(vector(pos3.x - 2, pos3.y + 1), vector(pos3.x + 2, pos3.y - 1), menu.visual.kibitmarker_color:get())
                                render.rect(vector(pos3.x - 1, pos3.y + 2), vector(pos3.x + 1, pos3.y - 2), menu.visual.kibitmarker_color:get())
                            end
                            if menu.visual.kibitmarker_mode:get() == 1 then 
                                render.line(vector(pos3.x - 6, pos3.y), vector(pos3.x + 5, pos3.y), menu.visual.kibitmarker_color:get())
                                render.line(vector(pos3.x, pos3.y - 6), vector(pos3.x, pos3.y + 5), menu.visual.kibitmarker_color:get())
                            end
                            
                        end
                else
                    table.remove(hitmarker, _)
                end
            end
            end
        },
        custom_scopex_x = {
            render = function()
               if not (menu.visual.custom_scope:get() and globals.is_in_game) then return end
                    local width, height = render.screen_size().x, render.screen_size().y
                    local offset, initial_position, speed, clr = 
                    menu.visual.overlay_offset:get(), 
                    menu.visual.overlay_position:get(), 
                    menu.visual.fade_time:get(),
                    menu.visual.custom_scope_color:get()
                
                    local me = entity.get_local_player()
                
                    local scoped = me['m_bIsScoped'] == true
                    local resume_zoom = me['m_bResumeZoom'] == true
                    local is_valid = me:is_alive() and globals.is_connected
                    local act = is_valid and scoped and not resume_zoom
                    local FT = speed > 3 and globals.frametime * speed or 1
                    local alpha = linear(m_alpha, 0, 1, 1)
                
                    render.gradient(vector(width/2 - offset+ 1, height / 2), vector(width/2 - offset - initial_position, height / 2 +1), color(clr.r, clr.g,clr.b,alpha*255), color(clr.r, clr.g,clr.b,alpha*0), color(clr.r, clr.g,clr.b,alpha*255), color(clr.r, clr.g,clr.b,alpha*0))
                    render.gradient(vector(width/2 + offset, height / 2), vector(width/2 + offset + initial_position, height / 2 +1), color(clr.r, clr.g,clr.b,alpha*255), color(clr.r, clr.g,clr.b,alpha*0), color(clr.r, clr.g,clr.b,alpha*255), color(clr.r, clr.g,clr.b,alpha*0))
                    render.gradient(vector(width/2, height / 2 + offset), vector(width/2 + 1, height / 2 +1+ offset + initial_position), color(clr.r, clr.g,clr.b,alpha*255), color(clr.r, clr.g,clr.b,alpha*255), color(clr.r, clr.g,clr.b,alpha*0), color(clr.r, clr.g,clr.b,alpha*0))
                    if not menu.visual.custom_scope_t_style:get() then
                        render.gradient(vector(width/2, height / 2 - offset + 1), vector(width/2+ 1, height / 2 - offset - initial_position), color(clr.r, clr.g,clr.b,alpha*255), color(clr.r, clr.g,clr.b,alpha*255), color(clr.r, clr.g,clr.b,alpha*0), color(clr.r, clr.g,clr.b,alpha*0))
                    end
                    m_alpha = clamp(m_alpha + (act and FT or -FT), 0, 1)
            end
        },
        manual_arrows = {
            render = function()
                if not (menu.visual.manual_arrows:get() and globals.is_in_game and entity.get_local_player():is_alive()) then return end
                if menu.visual.manual_arrows_mode:get() == 0 then
                if menu.aa.manual_right:get() then
                    render.text(fonts.acta_symols, vector(main.screen_size.x /2 - 35 - menu.visual.manual_arrows_yadd:get(), main.screen_size.y/2 - 9), color(21,21,21,90), "c", "Q")
                    render.text(fonts.acta_symols, vector(main.screen_size.x /2 + 35 + menu.visual.manual_arrows_yadd:get(), main.screen_size.y/2 - 9), color(menu.visual.manual_arrows_color:get().r,menu.visual.manual_arrows_color:get().g,menu.visual.manual_arrows_color:get().b,255), "c", "R")
                elseif menu.aa.manual_left:get() then
                    render.text(fonts.acta_symols, vector(main.screen_size.x /2 - 35 - menu.visual.manual_arrows_yadd:get(), main.screen_size.y/2 - 9), color(menu.visual.manual_arrows_color:get().r,menu.visual.manual_arrows_color:get().g,menu.visual.manual_arrows_color:get().b,255), "c", "Q")
                    render.text(fonts.acta_symols, vector(main.screen_size.x /2 + 35 + menu.visual.manual_arrows_yadd:get(), main.screen_size.y/2 - 9), color(21,21,21,90), "c", "R")
                else
                    render.text(fonts.acta_symols, vector(main.screen_size.x /2 - 35 - menu.visual.manual_arrows_yadd:get(), main.screen_size.y/2 - 9), color(21,21,21,90), "c", "Q")
                    render.text(fonts.acta_symols, vector(main.screen_size.x /2 + 35 + menu.visual.manual_arrows_yadd:get(), main.screen_size.y/2 - 9), color(21,21,21,90), "c", "R") 
                end 
            
                if get_side() == 1 then
                    render.text(fonts.verdana_arrows, vector(main.screen_size.x /2 - 23 - menu.visual.manual_arrows_yadd:get(), main.screen_size.y/2 - 12), color(menu.visual.manual_arrows_color:get().r,menu.visual.manual_arrows_color:get().g,menu.visual.manual_arrows_color:get().b,255), "c", "|")
                    render.text(fonts.verdana_arrows, vector(main.screen_size.x /2 + 23 + menu.visual.manual_arrows_yadd:get(), main.screen_size.y/2 - 12), color(21,21,21,90), "c", "|")
                elseif get_side() == -1 then
                    render.text(fonts.verdana_arrows, vector(main.screen_size.x /2 - 23 - menu.visual.manual_arrows_yadd:get(), main.screen_size.y/2 - 12), color(21,21,21,90), "c", "|")
                    render.text(fonts.verdana_arrows, vector(main.screen_size.x /2 + 23 + menu.visual.manual_arrows_yadd:get(), main.screen_size.y/2 - 12), color(menu.visual.manual_arrows_color:get().r,menu.visual.manual_arrows_color:get().g,menu.visual.manual_arrows_color:get().b,255), "c", "|")
                end
            elseif menu.visual.manual_arrows_mode:get() == 1 then
                if menu.aa.manual_right:get() then
                    render.text(fonts.acta_symols_low, vector(main.screen_size.x /2 - 35 - menu.visual.manual_arrows_yadd:get(), main.screen_size.y/2 - 6), color(21,21,21,90), "c", "Q")
                    render.text(fonts.acta_symols_low, vector(main.screen_size.x /2 + 35 + menu.visual.manual_arrows_yadd:get(), main.screen_size.y/2 - 6), color(menu.visual.manual_arrows_color:get().r,menu.visual.manual_arrows_color:get().g,menu.visual.manual_arrows_color:get().b,255), "c", "R")
                elseif menu.aa.manual_left:get() then
                    render.text(fonts.acta_symols_low, vector(main.screen_size.x /2 - 35 - menu.visual.manual_arrows_yadd:get(), main.screen_size.y/2 - 6), color(menu.visual.manual_arrows_color:get().r,menu.visual.manual_arrows_color:get().g,menu.visual.manual_arrows_color:get().b,255), "c", "Q")
                    render.text(fonts.acta_symols_low, vector(main.screen_size.x /2 + 35 + menu.visual.manual_arrows_yadd:get(), main.screen_size.y/2 - 6), color(21,21,21,90), "c", "R")
                else
                    render.text(fonts.acta_symols_low, vector(main.screen_size.x /2 - 35 - menu.visual.manual_arrows_yadd:get(), main.screen_size.y/2 - 6), color(21,21,21,90), "c", "Q")
                    render.text(fonts.acta_symols_low, vector(main.screen_size.x /2 + 35 + menu.visual.manual_arrows_yadd:get(), main.screen_size.y/2 - 6), color(21,21,21,90), "c", "R") 
                end 
            end
        end
        },
}

local clantag_table = {
   
}

local trashtalk_phrases = {
    
}

local misc_functions = {
    trashtalk = {
        on_event = function(self, event)
            if event:get_name() ~= "player_death" or not menu.misc.enable_trashtalk:get() then return end
                    local victim_id, attacker_id = event.userid, event.attacker
                    if victim_id == nil or attacker_id == nil then return end
                    local victim, attacker = entity.get(victim_id, true), entity.get(attacker_id, true)
                    if attacker == entity.get_local_player() and victim:is_enemy() then
                        utils.console_exec("say " .. trashtalk_phrases[math.random(0, #trashtalk_phrases)])
                end
            end
    },
    animation_breaker = {
        leg_jitter = false,
        breaking = function(self, local_player)
            local poseparams = local_player.m_flPoseParameter
            local animlayers = local_player:get_animlayers()
            self.leg_jitter = not self.leg_jitter
            
            if menu.misc.animations_mode:get() == 0 and menu.misc.enable_animbreaker:get() then --default
				ui.find("Anti aim", "Other", "Leg movement"):set(0)
            elseif menu.misc.animations_mode:get() == 3 and menu.misc.enable_animbreaker:get() then --static legs
                poseparams[0] = 1
                ui.find("Anti aim", "Fake lag", "Variabaility"):set(0)
                ui.find("Anti aim", "Other", "Leg movement"):set(1)
			elseif menu.misc.animations_mode:get() == 1 and menu.misc.enable_animbreaker:get() then --moonwalk
				poseparams[7] = 0
				ui.find("Anti aim", "Fake lag", "Variabaility"):set(0)
				ui.find("Anti aim", "Other", "Leg movement"):set(2)
			elseif menu.misc.animations_mode:get() == 2 and menu.misc.enable_animbreaker:get() then --jitter
				ui.find("Anti aim", "Other", "Leg movement"):set(1)
			if self.leg_jitter then
				poseparams[0] = (poseparams[0] + 0.5) % 1.0
			    end
			end

            if menu.misc.animations_mode_air:get() == 0 and menu.misc.enable_animbreaker:get() then --default
                
			elseif menu.misc.animations_mode_air:get() == 1 and menu.misc.enable_animbreaker:get() and entity.get_local_player()['m_hGroundEntity'] == -1 then --moonwalk
				animlayers[4].weight = 0
				animlayers[6].weight = 1
			elseif menu.misc.animations_mode_air:get() == 2 and menu.misc.enable_animbreaker:get() and entity.get_local_player()['m_hGroundEntity'] == -1 then --jitter
				poseparams[6] = globals.tickcount % 4 > 1 and 2 / 10 or 1
            elseif menu.misc.animations_mode_air:get() == 3 and menu.misc.enable_animbreaker:get() and entity.get_local_player()['m_hGroundEntity'] == -1 then --static
				poseparams[6] = 1
			    end
            end
    },
    clantag = {
        executed_stop = false,
        on_frame = function(self, frame)
                if menu.misc.enable_clantag:get() then
                    if type(globals.curtime) == 'string' then return end
                    local clantagtimer = math.floor(globals.curtime * main.clantag_speed + 0.5 )
                    ctindexer = clantagtimer % # clantag_table + 1
                    if main.clantag_stage == ctindexer then return else main.clantag_stage = ctindexer end
                    utils.set_clantag(clantag_table[main.clantag_stage])
                    self.executed_stop = false
                else
                    if not self.executed_stop then
                        utils.set_clantag('')
                        self.executed_stop = true
                    end
                end
        end
    },
}
--[[
if (menu.aa.manual_left:get_mode() == 2 or menu.aa.manual_right:get_mode() == 2 or menu.aa.manual_back:get_mode() == 2 or menu.aa.manual_forward:get_mode() == 2) then
    angelwave_push:paint(12, 'warning! you have turned on "always on" manual mode ~ check console for details')
    local col = '\a'..RGBtoHEX(menu.visual.interface_color:get(), true)..'[angelwave]\a_MAIN_'

    print_raw(string.format('\n\n\a%s warning! you have turned on "always on" manual mode.\n%s if you havent done this turn it off here\n%s antiaim > additions > manual direction > right click on manual\n\n', col, col, col))
    utils.console_exec('play ui/menu_invalid.wav')
end
--]]
utils.set_window_name(string.format('etnasy.gg%s', info.build ~= 'stable' and ' alpha' or ''))
client.add_callback('frame_stage', function(stage)
    misc_functions.clantag:on_frame(stage)
end)

client.add_callback("antiaim", function(ctx)
    antiaim:handle(ctx)
end)

client.add_callback("createmove", function(ctx)
    local lp = entity.get_local_player()
    if lp == nil then return end

    antiaim.command_number = ctx.command_number
    antiaim.view_angles = ctx.viewangles

    -- Disabled defensive logic to prevent conflicts with fakeduck
    -- if antiaim.defensive.ctx_force and refs.ragebot.doubletap:get() then
    --     ctx.override_defensive = true
    --     if rage.get_defensive_ticks() > 10 then
    --         rage.force_charge()
    --         rage.override_tickbase_shift(0)
    --     end
    -- elseif not ui.find('Aimbot', 'Aimbot', 'Peek Assist key'):get() and rage.get_exploit_charge() ~= 0 then
    --     rage.force_charge()
    --     ctx.override_defensive = nil
    -- else ctx.override_defensive = nil end

    antiaim:tweaks(ctx)

end)
client.add_callback('unload', function()
    utils.set_clantag("")
end)

client.add_callback("post_anim_update", function(local_player)
    misc_functions.animation_breaker:breaking(local_player)
end)

client.add_callback("aim_ack", function(shot)
    shot_info:on_shot(shot)
    shot_info.hitmarker_table(shot)
end)
client.add_callback("game_events", function(event)
    shot_info:on_event(event)
    misc_functions.trashtalk:on_event(event)
end)
client.add_callback("render", function()
    if gcinfo() >= 1200 then _G.collectgarbage('collect') end

    menu:visibility()
    widgets.keybinds:render()
    widgets.watermark:render()
    widgets.panel:render()
    widgets.slowed_down_indicator:render()
    widgets.defensive_indicator:render()
    widgets.alternative_wigets:render()
    shot_info:render()
    visual_functions.indicators_classic:render()
    visual_functions.indicators_old:render()
    visual_functions.damage_shower:render()
    visual_functions.kibit_hitmarker:render()
    visual_functions.custom_scopex_x:render()
    visual_functions.manual_arrows:render()

    xpcall(function() if is_ZALUPA_executing then config_frequency = config_frequency + 1 if config_frequency >= 50 then safe_call(function()
        local show_notify = type(is_custom_zalupa) ~= 'string'
        is_custom_zalupa = type(is_custom_zalupa) == 'string' and is_custom_zalupa or clipboard.get()
        local data = _json.decode(base64:decode(is_custom_zalupa))
        for i = 1, #data do
        for k, v in pairs(data[i]) do
            if type(v) == 'table' then
                for a, b in pairs(v) do
                    menu.builder[i][k][a]:set(b)
                end
            else
                menu.builder[i][k]:set(v)
            end 
        end end if show_notify then angelwave_push:paint(3, 'anti-aim data succesfully imported from clipboard') end utils.console_exec('play ui/beepclear.wav') end)
        config_frequency = 0 is_ZALUPA_executing = false is_PARASHA_executing = false is_custom_zalupa = false end end
        end, function()
        utils.console_exec('play ui/menu_invalid.wav')
        angelwave_push:paint(3, 'failed to import anti-aim data.')
    end)
    xpcall(function()
        if is_PARASHA_executing then config_frequency = config_frequency + 1 if config_frequency >= 50 then cfg_settings = {} for i = 1, #menu.builder do if i ~= 0 then
            for k, v in pairs(menu.builder[i]) do 
                if type(v) == 'table' then for a, b in pairs(v) do
                    if cfg_settings[i] == nil then cfg_settings[i] = {} end
                    if cfg_settings[i][k] == nil then cfg_settings[i][k] = {} end
                    if cfg_settings[i][k][a] == nil then cfg_settings[i][k][a] = b:get() end
                end else
                    if cfg_settings[i] == nil then cfg_settings[i] = {} end
                    if cfg_settings[i][k] == nil then cfg_settings[i][k] = v:get() end
                end end end
            end
            local PARASHA = _json.encode(cfg_settings)
            clipboard.set('~etnasy.gg~'..base64:encode(PARASHA))
            angelwave_push:paint(3, 'anti-aim data succesfully exported to clipboard')
            utils.console_exec('play ui/beepclear.wav') config_frequency = 0 is_PARASHA_executing = false is_ZALUPA_executing = false end
        end
    end, function() utils.console_exec('play ui/menu_invalid.wav') angelwave_push:paint(3, 'failed to export anti-aim data') end)

    for k, v in pairs(keybinds_callback_table) do v:update() end
    
end)
