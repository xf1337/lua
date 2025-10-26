--dedicated lua for etnasy.gg
local rad, cos, sin = math.rad, math.cos, math.sin

local _DEV = false
local MASK_SHOT_HULL = 0x600400B
local cache = {}

local script = ui.tab("Freestand")
local main = ui.groupbox("Freestand", "Main")

local uit = {
    freestand_type = main:combo("Freestand type", "Off", "Simple", "Edge Yaw"),
    options = main:multicombo("Freestand options", "Disable desync", "Off freestands if both sides have been detected"),
    bind = main:keybind("Freestanding"),
    yaw = main:slider_int("Freestand yaw range", 0, 120, 75),
    detect_angle = main:slider_int("Wall detect angle", 10, 60, 20),
    detect_distance = main:slider_int("Wall detect distance", 30, 100, 30),
    step = main:slider_int("Edge Yaw step", 2, 90, 30)
}

local arctic = {
    yaw = ui.find("Anti aim", "Angles", "Yaw")
}

uit.options:set(true, 0)
uit.options:set(true, 1)
uit.detect_angle:set(35)
uit.detect_distance:set(60)
uit.yaw:set(75)

uit.options:visible(false)
uit.detect_distance:visible(false)
uit.detect_angle:visible(false)
uit.step:visible(false)
uit.yaw:visible(false)

local function main(ctx)

    if not uit.bind:get() then
        if cache.yaw then
            arctic.yaw:set(cache.yaw)
            cache.yaw = nil
        end
        return
    end

    local lp = entity.get_local_player()
    if not (lp and lp:is_alive()) then
        return
    end

    local view = render.camera_angles()
    local eye = lp:get_eye_position()

    local freestand_type = uit.freestand_type:get()
    local trigger = false

    local dist = uit.detect_distance:get()

    if freestand_type == 1 then
        local sides = {}
        local angle = uit.detect_angle:get()

        for y = -angle, angle, angle * 2 do
            local yaw = rad(view.yaw + y)
            local cy, sy = cos(yaw), sin(yaw)

            local vec = eye + vector(cy * dist, sy * dist, -1)
            local tracer = utils.trace_line(eye, vec, MASK_SHOT_HULL, lp)

            sides[#sides+1] = tracer.fraction
        end

        local left, right = sides[1] ~= 1, sides[2] ~= 1

        if (left or right) and not (left and right and uit.options:get(1)) then
            local yaw = uit.yaw:get() * (sides[1] < sides[2] and -1 or 1)
            ctx:yaw_offset(-yaw)
            trigger = true
        end
    elseif freestand_type == 2 then
        local closest = { dist = math.huge }

        for i = -180, 180, uit.step:get() do
            local yaw = rad(view.yaw + i)
            local cy, sy = cos(yaw), sin(yaw)

            local vec = eye + vector(cy * dist, sy * dist, -1)
            local tracer = utils.trace_line(eye, vec, MASK_SHOT_HULL, lp)

            if tracer.fraction == 1 then
                goto continue
            end

            local delta = tracer.endpos - eye
            local len = delta:length2d_sqr()

            if len < closest.dist then
                closest.dist = len
                closest.yaw = i
            end
            ::continue::
        end

        if closest.yaw then
            ctx:yaw_offset(closest.yaw - 180)
            trigger = true
        end
    end

    if trigger then
        if uit.options:get(0) then
            ctx:desync(false)
        end
    end

    if not trigger and cache.yaw then
        arctic.yaw:set(cache.yaw)
        cache.yaw = nil
    elseif not cache.yaw then
        cache.yaw = arctic.yaw:get()
        arctic.yaw:set(1)
    end

end

uit.freestand_type:set_callback(function()
    local freestand_type = uit.freestand_type:get()

    uit.options:visible(freestand_type ~= 0)
    uit.detect_distance:visible(freestand_type ~= 0)
    uit.detect_angle:visible(freestand_type == 1)
    uit.yaw:visible(freestand_type == 1)
    uit.step:visible(freestand_type > 1)
end)

client.add_callback("antiaim", function(ctx)
    local s, m = pcall(main, ctx)

    if not s and _DEV then
        print(m)
    end
end)