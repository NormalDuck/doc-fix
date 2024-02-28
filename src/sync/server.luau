local Players = game:GetService("Players")

local atom = require(script.Parent.Parent.atom)
type Atom<T> = atom.Atom<T>
local setInterval = require(script.Parent.Parent.utils.setInterval)
local patch = require(script.Parent.patch)
local types = require(script.Parent.types)

type ServerSyncOptions = {
	atoms: { [string]: Atom<any> },
	interval: number?,
}

type ServerSync = {
	onSync: (self: ServerSync, callback: (player: Player, payload: types.SyncPayload) -> ()) -> () -> (),
	flush: (self: ServerSync, player: Player?) -> (),
	hydrate: (self: ServerSync, player: Player) -> (),
}

local function server(options: ServerSyncOptions): ServerSync
	local atoms = options.atoms
	local interval = options.interval or 0
	local self = {} :: ServerSync
	local sync: (player: Player, payload: types.SyncPayload) -> ()
	local state: {}

	local function getState()
		local state = {}
		for key, atom in atoms do
			state[key] = atom:get()
		end
		return state
	end

	function self:onSync(callback)
		sync = callback
		state = getState()

		return setInterval(function()
			self:flush()
		end, interval)
	end

	function self:flush(player: Player?)
		local current = getState()
		local previous = state or current
		state = current

		if current ~= previous then
			local payload: types.SyncPayload = {
				type = "patch",
				data = patch.diff(previous, current),
			}

			if player then
				return sync(player, payload)
			end

			for _, player in Players:GetPlayers() do
				sync(player, payload)
			end
		end
	end

	function self:hydrate(player)
		assert(sync, "onSync must be called before onJoin")

		sync(player, {
			type = "set",
			data = getState(),
		})
	end

	return self
end

return server