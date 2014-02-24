-- Virus Finder 0.7
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
	if os.difftime (os.time (), sets.tick) < conf.time then
		return 1
	end

	for nick, data in pairs (sets.user) do
		if os.difftime (os.time (), data [""]) >= conf.free * 60 then
			sets.user [nick] = nil
		end
	end

	VH:SendToClass ("$Search Hub:" .. sets.from .. " F?F?0?1?" .. sets.find [sets.next] .. "|", 0, conf.skip - 1)

	if sets.next == # sets.find then
		sets.next = 1
	else
		sets.next = sets.next + 1
	end

	sets.tick = os.time ()
	return 1
end

function VH_OnParsedMsgSR (nick, data)
	local ok, class = VH:GetUserClass (nick)

	if not ok or class >= conf.skip then
		return 1
	end

	local ok, _, path, name, size = data:find ("^%$SR [^ ]+ (.-)([^\\]-)" .. string.char (5) .. "(%d+) .+")

	if not ok or not path or not name or not size or # path == 0 or # name == 0 or tonumber (size) == 0 then
		return 1
	end

	local ok = false
	local lame = name:lower ()

	for _, ext in pairs (conf.exts) do
		if lame:sub (-# ext) == ext then
			if ext == ".rar" and lame:find ("%.part%d+%.rar$") then
				return 1
			else
				ok = true
				break
			end
		end
	end

	if not ok then
		return 1
	end

	local ok = false

	for _, file in pairs (conf.file) do
		local pos = true

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
				pos = false
				break
			end
		end

		if pos then
			ok = true
			break
		end
	end

	if not ok then
		return 1
	end

	size = tonumber (size)

	if not sets.user [nick] then
		sets.user [nick] = {
			[""] = os.time (),
			[path] = {
				[""] = size,
				[name] = size
			}
		}

		return 1
	end

	if not sets.user [nick][path] then
		sets.user [nick][path] = {
			[""] = size,
			[name] = size
		}

		return 1
	end

	sets.user [nick][path][""] = size

	if sets.user [nick][path][name] then
		return 1
	end

	if math.abs (sets.user [nick][path][""] - size) > conf.diff then
		return 1
	end

	sets.user [nick][path][name] = size
	local num = 0

	for _, _ in pairs (sets.user [nick][path]) do
		num = num + 1

		if num >= conf.find then
			break
		end
	end

	if num < conf.find then
		return 1
	end

	if conf.verb == 0 then
		VH:KickUser (sets.from, nick, conf.kick)
		sets.user [nick] = nil
		return 0
	end

	local ip = "0.0.0.0"
	local ok, addr = VH:GetUserIP (nick)

	if ok and addr then
		ip = addr
	end

	local ok, code = VH:GetUserCC (nick)

	if ok and code and code ~= "--" then
		ip = ip .. "." .. code
	end

	local feed = ""

	if conf.verb >= 2 then
		local list = ""

		for fame, fize in pairs (sets.user [nick][path]) do
			if # fame > 0 then
				local pref = "B"

				if fize >= 1073741824 then
					fize = fize / 1073741824
					pref = "GB"
				elseif fize >= 1048576 then
					fize = fize / 1048576
					pref = "MB"
				elseif fize >= 1024 then
					fize = fize / 1024
					pref = "KB"
				end

				list = list .. " " .. path .. fame .. " | " .. string.format ("%.2f", fize) .. " " .. pref .. "\r\n"
			end
		end

		list = list:gsub ("%$", "&#36;")
		list = list:gsub ("|", "&#124;")
		feed = "Infected user detected:\r\n\r\n"
		feed = feed .. " Nick: " .. nick .. "\r\n"
		feed = feed .. " IP: " .. ip .. "\r\n"
		feed = feed .. " Found files:\r\n\r\n"
		feed = feed .. list
	else
		feed = "Infected user detected with IP " .. ip .. ": " .. nick
	end

	VH:SendPMToAll (feed, sets.feed, conf.feed, 10)
	VH:KickUser (sets.from, nick, conf.kick)
	sets.user [nick] = nil
	return 0
end

-- end of file
