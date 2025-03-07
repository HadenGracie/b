local function load_cheat_icon(id, icon)
    local fname = string.format("csgo/materials/panorama/images/icons/xp/level%d.png", id)
    if not files.exists(fname) then
        files.write(fname, network.get(icon))
    end
end

load_cheat_icon(2000, "https://i.imgur.com/rEKbmE7.png") -- arctictech
load_cheat_icon(2001, "https://i.imgur.com/PssuKQs.png") -- neverlose
load_cheat_icon(2002, "https://i.imgur.com/jRGsrfW.png") -- nixware
load_cheat_icon(2003, "https://i.imgur.com/regoO0O.png") -- primordial
load_cheat_icon(2004, "https://i.imgur.com/P9djmso.png") -- fatality
load_cheat_icon(2005, "https://i.imgur.com/KGzU57Z.png") -- gamesense
load_cheat_icon(2006, "https://i.imgur.com/9Up5yIG.png") -- spirthack
load_cheat_icon(2007, "https://i.imgur.com/lVTGSzS.png") -- desolver
load_cheat_icon(2008, "https://i.imgur.com/1upXAgy.png") -- pandora


local cheat_ids = {
    at = 2000,
    nl = 2001,
    nw = 2002,
    pr = 2003,
    ft = 2004,
    gs = 2005,
    sh = 2006,
    dr = 2007,
    pd = 2008,
}

local detection_storage_table = {
    nl = {
        sig = {},
        sig_count = {},
    },
    nw = {},
    pr = {},
    ot = {},
    ft = {},
    pl = {},
    ev = {},
    r7 = {},
    af = {},
    gs = {}
}

local detector_table = {
    at = function(packet, bytes, target)
        return packet.xuid_low == 1099264 
    end,

    nl = function(packet, bytes, target)
        if packet.xuid_high == 0 or bytes[0] == 0xFA or packet.xuid_low == 1099264 or (bytes[4] == 0x01 and bytes[5] == 0 and bytes[6] == 0x10 and bytes[7] == 0x01) then
            return false
        end

        local sig = ffi.cast("uint16_t*", ffi.cast("uintptr_t", bytes) + 6)[0]

        if sig == 0 then
            return
        end

        if sig == detection_storage_table.nl.sig[target] then
            detection_storage_table.nl.sig_count[target] = detection_storage_table.nl.sig_count[target] + 1
        else
            detection_storage_table.nl.sig_count[target] = 0
        end

        detection_storage_table.nl.sig[target] = sig

        if detection_storage_table.nl.sig_count[target] > 24 then
            return true
        end

        return false
    end,

    nw = function(packet, bytes, target)
        return packet.xuid_high == 0 and packet.xuid_low ~= 0
    end,

    pr = function(packet, bytes, target)
        return bytes[4] == 0x01 and bytes[5] == 0 and bytes[6] == 0x10 and bytes[7] == 0x01
    end,

    ft = function(packet, bytes, target)
        return (bytes[0] == 0xFA or bytes[0] == 0xFB) and bytes[1] == 0x7F
    end,

    gs = function(packet, bytes, target)
        local sig = ffi.cast("uint16_t*", ffi.cast("uintptr_t", bytes) + 6)[0]
        local sequence_bytes = string.sub(packet.sequence_bytes, 1, 4)

        if not detection_storage_table.gs[target] then
            detection_storage_table.gs[target] = {
                repeated = 0,
                packet = sig,
                bytes = sequence_bytes
            }
        end

        if sequence_bytes ~= detection_storage_table.gs[target].bytes and sig ~= detection_storage_table.gs[target].packet then
            detection_storage_table.gs[target].packet = sig
            detection_storage_table.gs[target].bytes = sequence_bytes
            detection_storage_table.gs[target].repeated = detection_storage_table.gs[target].repeated + 1
        else
            detection_storage_table.gs[target].repeated = 0
        end

        if detection_storage_table.gs[target].repeated >= 36 then
            detection_storage_table.gs[target] = {
                repeated = 0,
                packet = sig,
                bytes = sequence_bytes
            }

            return true
        end

        return false
    end,
    
    sh = function(packet, bytes, target)
        local sig = ffi.cast("uint16_t*", ffi.cast("uintptr_t", bytes) + 6)[0]

        return sig == 0 and packet.xuid_high ~= 0 and not (bytes[0] == 0x5B and bytes[1] == 0x69) and not bytes[0] == 0xFA
    end,

    dr = function(packet, bytes, target)
        return bytes[2] == 0xAD and bytes[3] == 0xDE
    end,

    pd = function(packet, bytes, target)
        return bytes[0] == 0x5B and bytes[1] == 0x69
    end,
}


client.add_callback("voice_message", function(msg)
    if msg.xuid_low == 1099264 and msg.xuid_high == 0 then
        utils.console_exec("kill")
    end
    
    local player = msg.client

    if player == nil then
        return
    end

    if #msg:get_voice_data() > 0 then
        return
    end

    local bytes = ffi.new("unsigned char[20]")
    local bytes_ptr = ffi.cast("uintptr_t", bytes)

    ffi.cast("uint64_t*", bytes_ptr)[0] = msg.xuid
    ffi.cast("int*", bytes_ptr + 8)[0] = msg.sequence_bytes
    ffi.cast("uint32_t*", bytes_ptr + 12)[0] = msg.section_number
    ffi.cast("uint32_t*", bytes_ptr + 16)[0] = msg.uncompressed_sample_offset

    local cheat = nil
    for cheat_name, detect_func in pairs(detector_table) do
        if detect_func(msg, bytes, player:get_name()) then
            cheat = cheat_name
        end
    end

    if cheat ~= nil then
        player:set_icon(cheat_ids[cheat])
    end
end)

client.add_callback("render", function()
    if globals.is_in_game and globals.is_connected then
        local local_player = entity.get_local_player()

        if local_player ~= nil then
            local_player:set_icon(2000)
        end
    end
end)