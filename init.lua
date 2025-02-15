---@type mod_calllbacks
local M = { api_version = 2, version = "0.0.0" }

local global_n = 0
---@param impl function
---@return string
local function make_global(impl)
	local id = "local_multiplayer." .. global_n
	_G[id] = impl
	global_n = global_n + 1
	return id
end

---@param b boolean
---@return integer
local function int(b)
	return b and 1 or 0
end

---@enum
local val = {
	counter = 1,
	cursor_x = 2,
	cursor_y = 3,
	player_x = 4,
	player_y = 5,
}

---@type body_id?
local og_player

---We don't know what thread the brain runs in, so we need to make sure that the api we use is available
---@type unsafe_api
local unsafe_api = dofile_once("data/scripts/lua_mods/unsafe_api.lua")

local multiplayer_brain = make_global(function(body)
	---@cast body body
	-- lsp doesn't work with annotations of types on anonymous functions
	---@type brain
	local brain = {}

	if not og_player then
		og_player = get_player_body_id()
	end

	local our_counter = body.values[val.counter]
	if our_counter ~= 1 then
		return brain -- when the api supports more stuff we will destroy ourself here
	end

	local cursor = { x = body.values[val.cursor_x], y = body.values[val.cursor_y] }
	local old_player = { x = body.values[val.player_x], y = body.values[val.player_y] }

	local forward = int(unsafe_api.key_pressed(KEY_CODES.U)) - int(unsafe_api.key_pressed(KEY_CODES.J))
	local rotation = int(unsafe_api.key_pressed(KEY_CODES.H)) - int(unsafe_api.key_pressed(KEY_CODES.K))

	cursor.x = cursor.x
		+ int(unsafe_api.key_pressed(KEY_CODES.VK_RIGHT))
		- int(unsafe_api.key_pressed(KEY_CODES.VK_LEFT))
	cursor.y = cursor.y + int(unsafe_api.key_pressed(KEY_CODES.VK_UP)) - int(unsafe_api.key_pressed(KEY_CODES.VK_DOWN))

	local ability = unsafe_api.key_pressed(KEY_CODES.I)
	local grab_weight = int(unsafe_api.key_pressed(KEY_CODES.O)) - int(unsafe_api.key_pressed(KEY_CODES.P))
	local grab_mul = grab_weight == -1 and -1 or 1
	local grab_abs = grab_weight * grab_mul

	local player_id = get_player_body_id()
	if player_id then
		local player_body = get_body_info(player_id)
		if player_body then
			local new_pos = { x = player_body.com_x, y = player_body.com_y }
			local delta = { x = new_pos.x - old_player.x, y = new_pos.y - old_player.y }
			old_player.x = new_pos.x
			old_player.y = new_pos.y
			cursor.x = cursor.x + delta.x
			cursor.y = cursor.y + delta.y
		end
	end

	if unsafe_api.key_pressed(KEY_CODES.N_0) then
		unsafe_api.set_player_body_id(body.id)
	end

	draw_circle(cursor.x, cursor.y)
	brain.movement = forward
	brain.rotation = rotation
	brain.ability = ability
	brain.grab_target_x = cursor.x -- * grab_mul
	brain.grab_target_y = cursor.y -- * grab_mul
	brain.grab_weight = grab_abs
	brain.grab_dir = grab_weight

	brain.values = {}
	brain.values[val.cursor_x] = cursor.x
	brain.values[val.cursor_y] = cursor.y
	brain.values[val.player_x] = old_player.x
	brain.values[val.player_y] = old_player.y
	return brain
end)

local counter = 0

local multiplayer_spawn = make_global(function(body_id)
	---@cast body_id body_id
	counter = counter + 1
	if counter == 1 then
		print(body_id)
	end
	-- all the spawns seem to be on the same thread, so we can safely have a global in our lua_State*
	return { counter }
end)

-- post hook is for defining creatures
function M.post(api, _)
	local old_creature_list = creature_list
	creature_list = function(...)
		-- io.popen("Z:\\home\\nathan\\Documents\\CE\\Cheat_Engine.exe")
		local r = { old_creature_list(...) }

		register_creature(
			api.acquire_id("local_multiplayer.multiplayer_creature"),
			"body plans/start_player.bod",
			multiplayer_brain,
			multiplayer_spawn
		)

		return unpack(r)
	end

	local old_init_biomes = init_biomes
	init_biomes = function(...)
		local r = { old_init_biomes(...) }
		add_creature_spawn_chance("TUTR", api.acquire_id("local_multiplayer.multiplayer_creature"), 1000, 0)
		return unpack(r)
	end
end

return M
