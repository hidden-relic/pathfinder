global.cfg = {}
global.cfg.showpath = ""
global.cfg.start = {}
global.cfg.goal = {}
global.cfg.logger = true
global.cfg.belt = "express-transport-belt"
commands.add_command("chart", "charts what has been loaded of the map", function(command)
    local player = game.players[command.player_index]
    player.force.chart_all()
end)

commands.add_command("path", "attempts to visualize pathfinder for you. supply an in-game entity name to use that entity's collision data for the pathfinder. will default to transport-belt", function(command)
    local player = game.players[command.player_index]
    local entity = command.parameter or nil
    global.cfg.showpath = "line"
    get_path(player, player.position, entity, player.selected.position)
end)

commands.add_command("beltpath", "attempts to visualize pathfinder for you. supply an in-game entity name to use that entity's collision data for the pathfinder. will default to transport-belt", function(command)
    local player = game.players[command.player_index]
    local grain = command.parameter or nil
    global.cfg.showpath = "belt"
    global.cfg.start = {x=player.position.x, y=player.position.y}
    global.cfg.goal = player.selected.position
    get_path(player, player.position, grain, player.selected.position)
end)

commands.add_command("test", "loads a new blank surface with lab tiles", function(command)
    local player = game.players[command.player_index]
    game.create_surface("test")
    game.surfaces["test"].generate_with_lab_tiles = true
    player.teleport({0, 0}, game.surfaces["test"])
end)

-- Builder = {}

-- function Builder:new(definition)
--     local obj = {}
--     setmetatable(obj, self)
--     self.__index = self
--     obj.actions = {}
--     obj.index = 1
--     obj.position = definition.position
--     obj.last_tick = definition.tick
--     return obj
-- end

-- function Builder:addbuild(builddata)
--     self.actions[#self.actions + 1] = builddata
-- end

-- function Builder:update(tick)
--     if self.index > #self.actions then return end
--     action = self.actions[self.index]
--     if tick < action.tick + self.last_tick then return end

--     -- perform action
--     self.position = action.positionfunction(self.position)
--     self.index = self.index + 1
--     game.surfaces["nauvis"].create_entity{name=action.name, position=self.position, direction=action.direction}
--     self.last_tick = self.last_tick + action.tick
-- end

local M ={}

function get_path(player, start, grain, goal)
    local player = player or game.player
    local start = start or player.position
    local entity = 'transport-belt'
    local goal = goal or player.selected.position
    if not game.entity_prototypes[entity] then
        game.print("invalid entity. use the internal name: transport-belt")
        return
    else
        local proto = game.entity_prototypes[entity]
        return player.surface.request_path{bounding_box=proto.collision_box, collision_mask=proto.collision_mask, start=start, goal=goal, force=player.force, path_resolution_modifier=grain}
    end
end

local function fdown(position) return {x=position.x, y=position.y + 1} end
local function fright(position) return {x=position.x + 1, y=position.y} end
local function fup(position) return {x=position.x, y=position.y - 1} end
local function fleft(position) return {x=position.x - 1, y=position.y} end

local function head(pos1, pos2)
    local x = pos2.x-pos1.x
    local y = pos2.y-pos1.y
    
end

function l(msg)
    if global.cfg.logger == true then
    game.write_file("beltpath.txt", msg.."\n", true)
    end
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
        if global.cfg.showpath == "line" then
            render_path(event.path, 60*60*10)
        elseif global.cfg.showpath == "belt" then
            
            belt_path(event.path)
        end
    end
end

Creator = {}

function Creator:new(definition)
    game.write_file("beltpath.txt", "")
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    obj.position = definition.position
    obj.last_position = definition.last_position
    obj.direction = definition.direction
    obj.next_position = {}
    l("init creator")
    l(serpent.block(obj))
    return obj
end

function Creator:get_direction(next_pos)
    l("getting direction "..serpent.line(next_pos))
    local x = next_pos.x
    local y = next_pos.y
    if math.abs(x) == math.abs(y) then
        local roll = math.random(2)
        if roll == 1 then 
            if x > 0 then
                self.direction = defines.direction.east
            elseif x < 0 then
                self.direction = defines.direction.west
            end
        else
            if y > 0 then
                self.direction = defines.direction.south
            elseif y < 0 then
                self.direction = defines.direction.north
            end
        end
    elseif math.abs(x) > math.abs(y) then
        if x > 0 then
            self.direction = defines.direction.east
        elseif x < 0 then
            self.direction = defines.direction.west
        end
    else
        if y > 0 then
            self.direction = defines.direction.south
        elseif y < 0 then
            self.direction = defines.direction.north
        end
    end
end

function Creator:get_next_position(this_waypoint, next_waypoint)
    local x = this_waypoint.x-self.position.x
    local y = this_waypoint.y-self.position.y
    local next_pos = {}
    l("getting next pos "..serpent.line({x, y}))
    
    if math.abs(x) == math.abs(y) then
        local roll = math.random(2)
        if roll == 1 then 
            if x > 0 then
                self.next_position = {x=self.position.x + 1, y = self.position.y}
                next_pos.x = next_waypoint.x-self.next_position.x
                next_pos.y = next_waypoint.y-self.next_position.y
                return next_pos
            elseif x < 0 then
                self.next_position = {x=self.position.x - 1, y = self.position.y}
                next_pos.x = next_waypoint.x-self.next_position.x
                next_pos.y = next_waypoint.y-self.next_position.y
                return next_pos
            end
        else
            if y > 0 then
                self.next_position = {x=self.position.x, y=self.position.y + 1}
                next_pos.x = next_waypoint.x-self.next_position.x
                next_pos.y = next_waypoint.y-self.next_position.y
                return next_pos
            elseif y < 0 then
                self.next_position = {x=self.position.x, y=self.position.y - 1}
                next_pos.x = next_waypoint.x-self.next_position.x
                next_pos.y = next_waypoint.y-self.next_position.y
                return next_pos
            end
        end
    elseif math.abs(x) > math.abs(y) then
        if x > 0 then
            self.next_position = {x=self.position.x + 1, y = self.position.y}
            next_pos.x = next_waypoint.x-self.next_position.x
            next_pos.y = next_waypoint.y-self.next_position.y
            return next_pos
        elseif x < 0 then
            self.next_position = {x=self.position.x - 1, y = self.position.y}
            next_pos.x = next_waypoint.x-self.next_position.x
            next_pos.y = next_waypoint.y-self.next_position.y
            return next_pos
        end
    else
        if y > 0 then
            self.next_position = {x=self.position.x, y=self.position.y + 1}
            next_pos.x = next_waypoint.x-self.next_position.x
            next_pos.y = next_waypoint.y-self.next_position.y
            return next_pos
        elseif y < 0 then
            self.next_position = {x=self.position.x, y=self.position.y - 1}
            next_pos.x = next_waypoint.x-self.next_position.x
            next_pos.y = next_waypoint.y-self.next_position.y
            return next_pos
        end
    end
end

function Creator:create()
    l("creating belt")
    l(serpent.block(self))
    game.surfaces[1].create_entity{name=global.cfg.belt, position=self.next_position, direction=self.direction, force=game.forces["player"]}
end

function next_step(c, waypoints)
    l("creator pos: "..serpent.line(c.position))
    local next_pos = c:get_next_position(waypoints[1], waypoints[2])
    l(serpent.line(next_pos))
    c:get_direction(next_pos)
    l(serpent.line(c.direction))
    c:create()
    c.last_position = c.position
    c.position = c.next_position
    l("creator new pos: "..serpent.line(c.position))
    if math.abs(c.position.x - waypoints[1].x) > 1 or math.abs(c.position.y - waypoints[1].y) > 1 then
        next_step(c, waypoints[1])
    end
end

function belt_path(path)
    local last_pos = global.cfg.start
    global.creator = Creator:new({position={x=last_pos.x, y=last_pos.y}, last_position={x=last_pos.x, y=last_pos.y}, direction=defines.direction.north})
    local creator = global.creator
    for i = 2, #path do
        if i < #path then
            pcall(next_step, creator, {path[i].position, path[i+1].position})
        end
    end
end

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

local function on_player_created(event)
    local player = game.players[event.player_index]
    player.print("Hover mouse over an entity (can be used from map, do '/chart' to see through the fog) and use '/path' to see colored path.\nusing /beltpath will draw a belt line from you to the selected entity.\n/maze <width> <height> will design a random maze for you to test with")
end

local function on_tick(event)
    if global.builder then
        global.builder:update(game.tick)
    end
end

M.events = {
    [defines.events.on_script_path_request_finished] = on_script_path_request_finished,
    [defines.events.on_player_created] = on_player_created,
}

return M