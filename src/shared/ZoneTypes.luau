--!strict
-- ZoneTypes.luau

export type ZoneBehavior = {
	Id: string,
	Tag: string,
	OnEnter: (player: Player, zone: any?) -> (),
	OnLeave: (player: Player, zone: any?) -> (),
	Update: ((dt: number, players: { Player }) -> ())?,
}

local ZoneTypes = {}

ZoneTypes.Tags = {
	Safezone = "Safezone",
	Lava = "Lava",
	MusicZone = "MusicZone",
}

return ZoneTypes
