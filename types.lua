local ffi = require("ffi")
ffi.cdef([[
typedef struct {
	int32_t cur_player_idx;
	uint32_t n_players;
	uint32_t player_ids[32];
} MultiplayerManager;
]])

---@class (exact) MultiplayerManager
---@field cur_player_idx integer
---@field n_players integer
---@field player_ids body_id[]
