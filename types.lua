local ffi = require("ffi")
ffi.cdef([[
typedef struct {
	DWORD swap_key;
	uint64_t player_body_id_addr;
} Config;

typedef struct {
	Config config;
	bool swap_down_last_frame;
	int32_t cur_player_idx;
	uint32_t n_players;
	uint32_t player_ids[32];
} MultiplayerManager;
]])

---@class (exact) Config
---@field swap_key key_code
---@field player_body_id_addr integer

---@class (exact) MultiplayerManager
---@field config Config
---@field swap_down_last_frame boolean
---@field cur_player_idx integer
---@field n_players integer
---@field player_ids body_id[]
