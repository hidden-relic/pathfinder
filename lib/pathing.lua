local M ={}

function get_path(entity)
    local player = player or game.player
    if not game.entity_prototypes[entity] then
        game.print("invalid entity. use the internal name: transport-belt")
        return
    else
        local proto = game.entity_prototypes[entity]
        return player.surface.request_path{bounding_box=proto.collision_box, collision_mask=proto.collision_mask, start=player.position, goal=player.selected.position, force=player.force}
    end
end

local function on_player_created(event)
    local player = game.players[event.player_index]
    player.print("Hover mouse over an entity (can be used from map, do '/sc game.player.force.chart_all()' to see through the fog) and use '/sc get_path(entityname)' where entityname is the internal name for the entity whose collision data we'll use")
    player.print("/sc get_path('transport-belt')")
end

local function on_script_path_request_finished(event)
    if not event.path then
        game.print("Failed")
        if event.try_again_later then
            game.print("try later")
            return
        end
        return
    elseif event.path then
        render_path(event.path, 60*60*10    )
    end
end

M.events = {
    [defines.events.on_script_path_request_finished] = on_script_path_request_finished,
    [defines.events.on_player_created] = on_player_created,
}

function render_path(path, ttl)
    local last_pos = path[1].position
    local color = {r = 1, g = 0, b = 0, a = 0.5}
    
    for i, v in pairs(path) do
        if (i ~= 1) then
            
            color = {
                r = 1 / (1 + (i % 3)),
                g = 1 / (1 + (i % 5)),
                b = 1 / (1 + (i % 7)),
                a = 0.5
            }
            rendering.draw_line {
                color = color,
                width = 16,
                from = v.position,
                to = last_pos,
                surface = game.surfaces[1],
                time_to_live = ttl
            }
        end
        last_pos = v.position
    end
end

return M