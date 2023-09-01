local function FYshuffle(t)
  for i = 1, #t - 1 do
    local r = math.random(i, #t)
    t[i], t[r] = t[r], t[i]
  end
end

local function init_grid(w, h)
  local a = {}
  for i = 1, h do
    table.insert(a, {})
    for j = 1, w do
      table.insert(a[i], true)
    end
  end
  return a
end

local function avg(a, b)
  return (a + b) / 2
end

local function addTable(tbl, num)
  local added = {}
  for index = 1, #tbl do
    added[index] = tbl[index] + num
  end
  return added
end

local directions = {
  {x = 0, y = -2}, -- north
  {x = 2, y = 0}, -- east
  {x = -2, y = 0}, -- west
  {x = 0, y = 2}, -- south
}

local function make_maze(w, h)
  
  local map = init_grid(w*2+1, h*2+1)
  
  local function walk(x, y)
    map[y][x] = false
    
    local d = { 1, 2, 3, 4 }
    FYshuffle(d)
    for i, direction_num in ipairs(d) do
      local xx = x + directions[direction_num].x
      local yy = y + directions[direction_num].y
      if map[yy] and map[yy][xx] then
        map[avg(y, yy)][avg(x, xx)] = false
        walk(xx, yy)
      end
    end
  end
  
  walk(math.random(1, w)*2, math.random(1, h)*2)
  
  local maze = {walls = {}, spaces = {}}
  local rad = 0
  if w >= h then
    rad = w/2
  else
    rad = h/2
  end
  for i = 1, h*2+1 do
    for j = 1, w*2+1 do
      if map[i][j] then
      -- if (math.sqrt((math.abs(h-j)^2)+(math.abs(w-i)^2)) <= rad) and (map[i][j]) then
        table.insert(maze.walls, {x=j, y=i})
        -- else
        --   table.insert(maze.spaces, {x=j, y=i})
      end
    end
  end
  return maze
end

commands.add_command("maze", "make a maze. you can supply a width and height. if not supplied, will default to 32x32", function(command)
  local player = game.players[command.player_index]
  local wh = command.parameter
  local args = {}
  for arg in wh:gmatch("%w+") do table.insert(args, arg) end
  local width = tonumber(args[1]) or 32
  local height = tonumber(args[2]) or 32
  local pos = player.position
  local map_gen = game.parse_map_exchange_string(game.get_map_exchange_string())
  local mapseed = map_gen.map_gen_settings.seed
  
  math.randomseed( mapseed )
  local maze = make_maze(width, height)
  for _, wall in pairs(maze.walls) do
    game.player.surface.create_entity{name="stone-wall", position={x=wall.x+pos.x, y=wall.y+pos.y}, force=player.force}
  end
end)