-- Virus Finder 0.6
-- © 2013-2014 RoLex
-- Based on script from http://dchublist.ru/forum/viewtopic.php?f=6&t=1010

conf = {

	["file"] = {												-- list of file names to search for
		"100 best",
		"top 100",
		"top girl",
		"18 girl",
		"sexy girl",
		"top wallpaper",
		"sexy wallpaper",
		"anti virus",
		"0day",
		"apple",
		"microsoft",
		"windows",
		"office",
		"adobe",
		"google",
		"android",
		"crack",
		"patch",
		"keygen",
		"serial",
		"trojan",
		"torrent",
		"advanced",
		"ahead",
		"collection",
		"wallpaper",
		"porn",
		"ptsc",
		"pthc",
		"preteen",
		"lolita",
		"sex",
		".jpg",
		".mp3"
	},

	["exts"] = {												-- list of file extensions to search for
		".exe",
		".zip",
		".rar"
	},

	["verb"] = 2,												-- detection feed verbosity from 2 to 0
	["feed"] = 5,												-- minimum class to receive feed messages
	["skip"] = 2,												-- minimum class to skip virus detection
	["time"] = 30,												-- file search timer interval in seconds
	["find"] = 30,												-- total file match counter for detection
	["diff"] = 256,												-- detection file size difference in bytes
	["free"] = 120,												-- user give up timer interval in minutes
	["kick"] = "Virus spreaders are not welcome here _ban_"		-- kick and ban reason on virus detection

}

sets = {
	["tick"] = 0,
	["next"] = 1,
	["from"] = "",
	["feed"] = "",
	["find"] = {},
	["user"] = {}
}

function Main (name)
	local _
	_, sets.from = VH:GetConfig ("config", "hub_security")
	_, sets.feed = VH:GetConfig ("config", "opchat_name")

	for _, ext in pairs (conf.exts) do
		for _, file in pairs (conf.file) do
			local item = file:gsub (" ", "$")
			table.insert (sets.find, item .. "$" .. ext)
		end
	end

	sets.tick = os.time ()
	return 1
end

function VH_OnTimer (msec)
	if os.difftime (os.time (), sets.tick) >= conf.time then
		for nick, data in pairs (sets.user) do
			if os.difftime (os.time (), data [""]) >= conf.free * 60 then
				sets.user [nick] = nil
			end
		end

		--[[

		local ok, list = VH:GetNickList ()

		if ok and list and # list >= 11 then
			local data = sets.find [sets.next]
			list = list:sub (11)

			for nick in list:gmatch ("[^%$ ]+") do
				if # nick > 0 then
					local ok, class = VH:GetUserClass (nick)

					if ok and class and class >= 0 and class < conf.skip then
						local ok, info = VH:GetMyINFO (nick)

						if ok and info and # info > 0 then
							local ok, _, shar = info:find ("^%$MyINFO %$ALL [^ ]+ .-$.-%$.-%$.-%$(%d+)%$$")

							if ok and shar and tonumber (shar) > 0 then
								VH:SendToUser ("$Search Hub:" .. sets.from .. " F?F?0?1?" .. data .. "|", nick)
							end
						end
					end
				end
			end
		else
			VH:SendToClass ("$Search Hub:" .. sets.from .. " F?F?0?1?" .. sets.find [sets.next] .. "|", 0, conf.skip - 1)
		end

		]]--

		VH:SendToClass ("$Search Hub:" .. sets.from .. " F?F?0?1?" .. sets.find [sets.next] .. "|", 0, conf.skip - 1)

		if sets.next == # sets.find then
			sets.next = 1
		else
			sets.next = sets.next + 1
		end

		sets.tick = os.time ()
	end

	return 1
end

function VH_OnParsedMsgSR (nick, data)
	local ok, class = VH:GetUserClass (nick)

	if not ok or class >= conf.skip then
		return 1
	end

	local ok, _, path, name, size = data:find ("^%$SR [^ ]+ (.-)([^\\]-)" .. string.char (5) .. "(%d+) .+")

	if ok and path and name and size and # path > 0 and # name > 0 and tonumber (size) > 0 then
		for _, file in pairs (conf.file) do
			for _, ext in pairs (conf.exts) do
				if getname (name, file) and name:sub (-# ext):lower () == ext then
					if ext ~= ".rar" or (ext == ".rar" and not name:lower ():find ("%.part%d+%.rar$")) then
						if sets.user [nick] then
							if sets.user [nick][path] then
								if not sets.user [nick][path][name] then
									if math.abs (sets.user [nick][path][""] - tonumber (size)) <= conf.diff then
										sets.user [nick][path][name] = tonumber (size)

										if getitem (sets.user [nick][path]) >= conf.find then
											if conf.verb == 2 then
												local feed, list = "", ""

												for fame, fize in pairs (sets.user [nick][path]) do
													if # fame > 0 then
														list = list .. " " .. path .. fame .. " | " .. getsize (fize) .. "\r\n"
													end
												end

												list = list:gsub ("%$", "&#36;")
												list = list:gsub ("|", "&#124;")

												feed = "Infected user detected:\r\n\r\n"
												feed = feed .. " Nick: " .. nick .. "\r\n"
												feed = feed .. " IP: " .. getaddr (nick) .. "\r\n"
												feed = feed .. " Found files:\r\n\r\n"
												feed = feed .. list

												VH:SendPMToAll (feed, sets.feed, conf.feed, 10)
											elseif conf.verb == 1 then
												VH:SendPMToAll ("Infected user detected with IP " .. getaddr (nick) .. ": " .. nick, sets.feed, conf.feed, 10)
											end

											VH:KickUser (sets.from, nick, conf.kick)
											sets.user [nick] = nil
											return 0
										end
									end
								end

								sets.user [nick][path][""] = tonumber (size)
							else
								sets.user [nick][path] = {
									[""] = tonumber (size),
									[name] = tonumber (size)
								}
							end
						else
							sets.user [nick] = {
								[""] = os.time (),
								[path] = {
									[""] = tonumber (size),
									[name] = tonumber (size)
								}
							}
						end
					end

					return 1
				end
			end
		end
	end

	return 1
end

function getname (name, file)
	local lame = name:lower ()

	for part in file:gmatch ("[^ ]+") do
		part = part:gsub ("%%", "%%%%")
		part = part:gsub ("%^", "%%^")
		part = part:gsub ("%$", "%%$")
		part = part:gsub ("%(", "%%(")
		part = part:gsub ("%)", "%%)")
		part = part:gsub ("%.", "%%.")
		part = part:gsub ("%[", "%%[")
		part = part:gsub ("%]", "%%]")
		part = part:gsub ("%*", "%%*")
		part = part:gsub ("%+", "%%+")
		part = part:gsub ("%-", "%%-")
		part = part:gsub ("%?", "%%?")

		if not lame:find (part) then
			return false
		end
	end

	return true
end

function getitem (list)
	local back = 0

	for _, _ in pairs (list) do
		back = back + 1
	end

	return back
end

function getaddr (nick)
	local back = "0.0.0.0"
	local ok, addr = VH:GetUserIP (nick)

	if ok and addr then
		back = addr
	end

	local ok, code = VH:GetUserCC (nick)

	if ok and code and code ~= "--" then
		back = back .. "." .. code
	end

	return back
end

function getsize (size)
	local back = {
		["size"] = size,
		["pref"] = "B"
	}

	if size >= 1208925819614629174706176 then
		back.size = size / 1208925819614629174706176
		back.pref = "YB"
	elseif size >= 1180591620717411303424 then
		back.size = size / 1180591620717411303424
		back.pref = "ZB"
	elseif size >= 1152921504606846976 then
		back.size = size / 1152921504606846976
		back.pref = "EB"
	elseif size >= 1125899906842624 then
		back.size = size / 1125899906842624
		back.pref = "PB"
	elseif size >= 1099511627776 then
		back.size = size / 1099511627776
		back.pref = "TB"
	elseif size >= 1073741824 then
		back.size = size / 1073741824
		back.pref = "GB"
	elseif size >= 1048576 then
		back.size = size / 1048576
		back.pref = "MB"
	elseif size >= 1024 then
		back.size = size / 1024
		back.pref = "KB"
	end

	return string.format ("%.2f", back.size) .. " " .. back.pref
end

-- end of file
