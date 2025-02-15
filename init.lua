---@type mod_calllbacks
local M = { api_version = 2, version = "0.0.0" }
dofile_once("data/scripts/lua_mods/mods/local_multiplayer/cdef.lua")
dofile_once("data/scripts/lua_mods/mods/local_multiplayer/types.lua")

local ffi = require("ffi")

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

---We don't know what thread the brain runs in, so we need to make sure that the api we use is available
---@type unsafe_api
local unsafe_api = dofile_once("data/scripts/lua_mods/unsafe_api.lua")

---@enum
local val = {
	counter = 1,
	cursor_x = 2,
	cursor_y = 3,
	player_x = 4,
	player_y = 5,
	managed_player = 6,
}

-- NOTE: keep in sync with manager_thread
local mem_name = "local_multiplayer.shared_memory"
local mem_size = 4096

local function manager_thread()
	-- we can't safely read any data not in this thread, so recreate things here
	---@diagnostic disable-next-line: redefined-local
	local mem_name = "local_multiplayer.shared_memory"
	---@diagnostic disable-next-line: redefined-local
	local mem_size = 4096
	---@diagnostic disable-next-line: redefined-local
	local ffi = require("ffi")
	dofile("data/scripts/lua_mods/mods/local_multiplayer/cdef.lua")
	dofile("data/scripts/lua_mods/mods/local_multiplayer/types.lua")

	local file_handle = ffi.C.OpenFileMappingA(0x06, false, mem_name) -- readwrite open the mapping
	local mem_view = ffi.cast("MultiplayerManager *", ffi.C.MapViewOfFile(file_handle, 0x06, 0, 0, mem_size)) --[[@as MultiplayerManager]]

	---This variant doesn't throw, instead will just corrupt memory
	---@param id body_id
	local function set_player_body_id(id)
		local p_player_body_id = ffi.cast("int *", mem_view.config.player_body_id_addr)
		p_player_body_id[0] = id
	end

	---Returns whether the key is currently pressed, not tied to the framerate.
	---@param code key_code
	---@return boolean
	local function key_pressed(code)
		local state = ffi.C.GetAsyncKeyState(code)
		local pressed = bit.band(state, bit.lshift(1, 15)) ~= 0
		return pressed
	end

	while true do
		ffi.C.Sleep(1)
		local down = key_pressed(mem_view.config.swap_key)
		if not mem_view.swap_down_last_frame and down then
			mem_view.cur_player_idx = (mem_view.cur_player_idx + 1) % mem_view.n_players
			set_player_body_id(mem_view.player_ids[mem_view.cur_player_idx])
		end
		mem_view.swap_down_last_frame = down
	end
end

---@type MultiplayerManager
local manager

local multiplayer_brain = make_global(function(body)
	---@cast body body
	-- lsp doesn't work with annotations of types on anonymous functions
	---@type brain
	local brain = { values = {} }

	local our_counter = body.values[val.counter]
	if our_counter ~= 1 then
		return brain -- when the api supports more stuff we will destroy ourself here
	end

	local player = get_player_body_id()
	if body.values[val.managed_player] ~= 1 and player then
		brain.values[val.managed_player] = 1
		local file_handle = ffi.C.OpenFileMappingA(0x06, false, mem_name) -- readwrite open the mapping
		local mem_view = ffi.cast("MultiplayerManager *", ffi.C.MapViewOfFile(file_handle, 0x06, 0, 0, mem_size)) --[[@as MultiplayerManager]]
		print(mem_view)

		if mem_view.cur_player_idx == -1 then
			mem_view.player_ids[mem_view.n_players] = player
			mem_view.n_players = mem_view.n_players + 1 -- casual race condition, mutex sounds like too much hassle
			mem_view.cur_player_idx = mem_view.n_players - 1
		end

		ffi.C.UnmapViewOfFile(mem_view) -- we need to do this if we are no fun and don't want to leak mem
		ffi.C.CloseHandle(file_handle)
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

	draw_circle(cursor.x, cursor.y)
	brain.movement = forward
	brain.rotation = rotation
	brain.ability = ability
	brain.grab_target_x = cursor.x
	brain.grab_target_y = cursor.y
	brain.grab_weight = grab_abs
	brain.grab_dir = grab_weight

	brain.values[val.cursor_x] = cursor.x
	brain.values[val.cursor_y] = cursor.y
	brain.values[val.player_x] = old_player.x
	brain.values[val.player_y] = old_player.y

	return brain
end)

local counter = 0

-- this runs in the same thread as the first call of creature_list, so we can use it
local multiplayer_spawn = make_global(function(body_id)
	---@cast body_id body_id
	counter = counter + 1
	if counter == 1 then
		manager.player_ids[manager.n_players] = body_id
		manager.n_players = manager.n_players + 1

		print("bt: ", ffi.C.GetCurrentThreadId())
		print(body_id)
	end
	-- all the spawns seem to be on the same thread, so we can safely have a global in our lua_State*
	return { [val.counter] = counter, [val.managed_player] = 0 }
end)

local done_manager_creation = false
-- post hook is for defining creatures
function M.post(api, _)
	local old_creature_list = creature_list
	creature_list = function(...)
		if not done_manager_creation then
			done_manager_creation = true -- pretty sure theres a race condition here, its good enough for now
			print("mt: ", ffi.C.GetCurrentThreadId())
			-- io.popen("Z:\\home\\nathan\\Documents\\CE\\Cheat_Engine.exe")
			local file_mapping = ffi.C.CreateFileMappingA(nil, nil, 0x04, 0, mem_size, mem_name) -- creature a virtual file with 4kb backing size, readwrite perms
			local mem_view = ffi.C.MapViewOfFile(file_mapping, 0x06, 0, 0, mem_size) -- readwrite access the mem
			manager = ffi.cast("MultiplayerManager *", mem_view) --[[@as MultiplayerManager]]
			print(manager)
			manager.cur_player_idx = -1
			manager.n_players = 0
			manager.config.swap_key = KEY_CODES.N_0
			manager.config.player_body_id_addr = unsafe_api.addrs.player_body_addr

			package.cpath = package.cpath .. ";./data/scripts/lua_mods/mods/local_multiplayer/?.dll"
			local effil = require("effil")
			local thread = effil.thread(manager_thread)()
			print(thread)
		end
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
