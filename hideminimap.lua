addon.name    = 'hideminimap'
addon.author  = 'Aesk (based on minimapmon by Atom0s)'
addon.version = '1.0.0'
addon.desc    = 'Hides minimap during expanded chat or open map'

require('common');
local ffxi = require('utils.ffxi')

local hmm = T{
	hideUnderMap = true,
	hideUnderChat = true,
    tick    = 0,
	opacity = T{
        last        = 1,
        map         = 1,
        frame       = 0,
        arrow       = 1,
        monsters    = 1,
        npcs        = 1,
        players     = 1,
	}
};

--[[
* event: packet_in
* desc : Event called when the addon is processing incoming packets.
--]]
ashita.events.register('packet_in', 'packet_in_cb', function (e)
    -- Packet: Zone Leave
    if (e.id == 0x000B) then
        hmm.zoning = true;
        return;
    end

    -- Packet: Inventory Update Completed
    if (e.id == 0x001D) then
        hmm.zoning = false;
        return;
    end
end);

--[[
* event: d3d_present
* desc : Event called when the Direct3D device is presenting a scene.
--]]
ashita.events.register('d3d_present', 'present_cb', function ()
    if (hmm.zoning) then
        return;
    end
	
    -- Throttle monitoring..
    if (os.clock() >= hmm.tick + 0.05) then
        hmm.tick = os.clock();

        -- Fade the Minimap plugin if the player is standing still..
        if (hmm.hideUnderChat and ffxi.IsChatExpanded()) or (hmm.hideUnderMap and ffxi.IsMapOpen()) then
            hmm.opacity.map         = math.clamp(hmm.opacity.map - 0.1, 0, 1);
            hmm.opacity.frame       = math.clamp(hmm.opacity.frame - 0.1, 0, 1);
            hmm.opacity.arrow       = math.clamp(hmm.opacity.arrow - 0.1, 0, 1);
            hmm.opacity.monsters    = math.clamp(hmm.opacity.monsters - 0.1, 0, 1);
            hmm.opacity.npcs        = math.clamp(hmm.opacity.npcs - 0.1, 0, 1);
            hmm.opacity.players     = math.clamp(hmm.opacity.players - 0.1, 0, 1);
        else
            hmm.opacity.map         = 1;
            hmm.opacity.frame       = 0;
            hmm.opacity.arrow       = 1;
            hmm.opacity.monsters    = 1;
            hmm.opacity.npcs        = 1;
            hmm.opacity.players     = 1;
        end

        -- Update the opacity if it has changed..
        if (hmm.opacity.last ~= hmm.opacity.map) then
            hmm.opacity.last = hmm.opacity.map;

            -- Build the event packet..
            local data = struct.pack('Lffffff', 0x01, hmm.opacity.map, hmm.opacity.frame, hmm.opacity.arrow, hmm.opacity.monsters, hmm.opacity.npcs, hmm.opacity.players);

            -- Raise the minimap event for opacity updates..
            AshitaCore:GetPluginManager():RaiseEvent('minimap', data:totable());
        end
    end
end);