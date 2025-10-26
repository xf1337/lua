--dedicated lua for etnasy.gg
local entity_get, client_add_callback, entity_get_local_player, math_cos, math_rad, math_sin, render_camera_angles, table_insert, ui_find, color, render_poly, render_screen_size, vector = entity.get, client.add_callback, entity.get_local_player, math.cos, math.rad, math.sin, render.camera_angles, table.insert, ui.find, color, render.poly, render.screen_size, vector

local entity_get_players = function (enemy, alive, esp, callback) local entity_list = {} for i = 0, globals.max_players do local ent = entity_get(i) if not (ent and ent:is_player()) then goto continue end if enemy and not ent:is_enemy() then goto continue end if alive and not ent:is_alive() then goto continue end if esp and ent:is_dormant() then goto continue end if callback then callback(ent) end table_insert(entity_list, ent) ::continue:: end return entity_list end

local menu = {
    checkbox = ui_find('Player', 'ESP'):checkbox('Out of view arrows'),
    clr = ui_find('Player', 'ESP'):color_picker('Out of view arrows', color(255, 0, 0)),
    width = ui_find('Player', 'ESP'):slider_int('Arrows size', 5, 20, 7, '%dpx'),
    distance = ui_find('Player', 'ESP'):slider_int('Arrows distance', 100, render_screen_size().y / 2, 280),
}

menu.clr:visible(false)
menu.width:visible(false)
menu.distance:visible(false)

menu.checkbox:set_callback(function ()
    if menu.checkbox:get() then
        menu.clr:visible(true)
        menu.width:visible(true)
        menu.distance:visible(true)
    elseif not menu.checkbox:get() then
        menu.clr:visible(false)
        menu.width:visible(false)
        menu.distance:visible(false)
    end
end)

local on_render = function ()
    local height = menu.distance:get() + (menu.width:get() * 3)
    local screen = render_screen_size()
    local screen_center = screen * .5
    local lp = entity_get_local_player()
    local viewangle = render_camera_angles()

    if not menu.checkbox:get() or not lp or not lp:is_alive() then return end

    entity_get_players(true, true, true, function (player)
        local lp_pos = lp:get_abs_origin()
        local enemy_pos = player:get_abs_origin()
        local angle = (enemy_pos - lp_pos):angles()

        angle.yaw = angle.yaw * -1
        angle.yaw = angle.yaw + viewangle.yaw - 90
        angle.yaw = math_rad(angle.yaw)

        local to_screen = player:get_abs_origin():to_screen()

        if to_screen.x == nil and to_screen.y == nil or to_screen.x < 0 or to_screen.y < 0 or to_screen.x > screen.x or to_screen.y > screen.y then
            render_poly(menu.clr:get(), vector(screen_center.x + (menu.distance:get() * math_cos(angle.yaw - math_rad(menu.width:get() * 100 / menu.distance:get()))), screen_center.y + (menu.distance:get() * math_sin(angle.yaw - math_rad(menu.width:get() * 100 / menu.distance:get())))), vector(screen_center.x + (menu.distance:get() * math_cos(angle.yaw + math_rad(menu.width:get() * 100 / menu.distance:get()))), screen_center.y + (menu.distance:get() * math_sin(angle.yaw + math_rad(menu.width:get() * 100 / menu.distance:get())))), vector(screen_center.x + (height * math_cos(angle.yaw)), screen_center.y + (height * math_sin(angle.yaw))))
        end
    end)
end

client_add_callback('render', on_render)