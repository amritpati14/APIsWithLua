-- eatyguy5.lua

local eatyguy = {}


-- Globals.

local percent_extra_paths = 15
local grid                = nil     -- grid[x][y]: falsy = wall.
local grid_w, grid_h      = nil, nil
local player = {pos      = {1, 1},
                dir      = {1, 0},
                next_dir = {1, 0}}


-- Internal functions.

local function is_in_bounds(x, y)
  return (1 <= x and x <= grid_w and
          1 <= y and y <= grid_h)
end

local function get_neighbor_directions(x, y, percent_extra)
  -- percent_extra is the percent chance of adding extra paths.
  percent_extra = percent_extra or 0
  local neighbor_directions = {}
  local all_directions = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
  for _, direction in pairs(all_directions) do
    local nx, ny = x + 2 * direction[1], y + 2 * direction[2]
    local is_extra_ok = (math.random(100) <= percent_extra)
    -- Add `direction` if the neighbor is not yet in a path, or
    -- if we randomly got an extra ok using percent_extra.
    if is_in_bounds(nx, ny) and
       (not grid[nx][ny] or is_extra_ok) then
      table.insert(neighbor_directions, direction)
    end
  end
  return neighbor_directions
end

local function drill_path_from(x, y)
  grid[x][y] = '. '
  local neighbor_directions = get_neighbor_directions(x, y)
  while #neighbor_directions > 0 do
    local direction = table.remove(neighbor_directions,
                          math.random(#neighbor_directions))
    grid[x + direction[1]][y + direction[2]] = '. '
    drill_path_from(x + 2 * direction[1], y + 2 * direction[2])
    neighbor_directions = get_neighbor_directions(x, y,
                                          percent_extra_paths)
  end
end

-- Check whether a character can move in a given direction.
-- Return can_move, new_pos.
local function can_move_in_dir(character, dir)
  local pos = character.pos
  local grid_x, grid_y = pos[1] + dir[1], pos[2] + dir[2]
  local can_move = grid[grid_x] and grid[grid_x][grid_y]
  return can_move, {grid_x, grid_y}
end

local move_delta     = 0.2  -- seconds
local next_move_time = nil

local function update(state)

  -- Ensure any dot under the player has been eaten.
  local cur_pos = player.pos
  grid[cur_pos[1]][cur_pos[2]] = '  '

  -- Update the next direction if an arrow key was pressed.
  local direction_of_key = {left = {-1, 0}, right = {1, 0},
                            up   = {0, -1}, down  = {0, 1}}
  local new_dir = direction_of_key[state.key]
  if new_dir then player.next_dir = new_dir end

  -- Only move every move_delta seconds.
  if next_move_time == nil then
    next_move_time = state.clock + move_delta
  end
  if state.clock < next_move_time then return end
  next_move_time = next_move_time + move_delta

  -- Try to change direction; if we can't, next_dir will take
  -- effect at a corner where we can turn in that direction.
  if can_move_in_dir(player, player.next_dir) then
    player.dir = player.next_dir
  end

  -- Move in direction player.dir if possible.
  local can_move, new_pos = can_move_in_dir(player, player.dir)
  if can_move then
    player.old_pos = player.pos  -- Save the old position.
    player.pos = new_pos
  end
end

local function draw(clock)

  -- Choose the sprite to draw. For example, a right-facing
  -- player is drawn as '< alternated with '-
  local draw_data = {
    [ '1,0'] = {"'<", "'-"},
    ['-1,0'] = {">'", "-'"},
    [ '0,1'] = {"^'", "|'"},
    ['0,-1'] = {"v.", "'."}
  }
  local anim_timestep = 0.2
  local dirkey = ('%d,%d'):format(player.dir[1],
                                  player.dir[2])
  -- framekey switches between 1 & 2; basic sprite animation.
  -- We now use `clock` instead of calling timestamp().
  local framekey = math.floor(clock / anim_timestep) % 2 + 1
  local chars    = draw_data[dirkey][framekey]

  -- Draw the player.
  set_color('b', 3)  -- Yellow background.
  set_color('f', 0)  -- Black foreground.
  local x = 2 * player.pos[1]
  local y =     player.pos[2]
  set_pos(x, y)
  io.write(chars)
  io.flush()

  -- Erase the old player pos if appropriate.
  if player.old_pos then
    local x = 2 * player.old_pos[1]
    local y =     player.old_pos[2]
    set_pos(x, y)
    set_color('b', 0)  -- Black background.
    io.write('  ')
    io.flush()
    player.old_pos = nil
  end
end


-- Public functions.

function eatyguy.init()

  -- Set up the grid size and pseudorandom number generation.
  grid_w, grid_h = 39, 21
  math.randomseed(os.time())

  -- Build the maze.
  grid = {}
  for x = 1, grid_w do grid[x] = {} end
  drill_path_from(1, 1)

  -- Draw the maze.
  set_color('f', 7)                  -- White foreground.
  for y = 0, grid_h + 1 do
    for x = 0, grid_w + 1 do
      if grid[x] and grid[x][y] then
        set_color('b', 0)            -- Black; open space color.
        io.write(grid[x][y])
      else
        set_color('b', 4)            -- Blue; wall color.
        io.write('  ')
      end
      io.flush()                     -- Needed for color output.
    end
    set_color('b', 0)                -- End the lines in black.
    io.write(' \r\n')                -- Move cursor to next row.
  end
end

function eatyguy.loop(state)
  update(state)
  draw(state.clock)
end

return eatyguy
