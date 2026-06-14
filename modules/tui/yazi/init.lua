require("starship"):setup()
require("git"):setup()

require("custom-shell"):setup({
	history_path = "default",
	save_history = true,
})

local home = os.getenv("HOME") or "~"

local hops = {}

local function add_hop(key, path, desc)
	if fs.cha(Url(path)) ~= nil then
		table.insert(hops, {
			key = key,
			path = path,
			desc = desc,
		})
	end
end

add_hop("~", home, "Home")
add_hop("d", home .. "/Downloads", "Downloads")
add_hop(".", home .. "/.config", "Config files")
add_hop("c", home .. "/GitHub", "Coding Directory")
add_hop("b", home .. "/vault/Books/Physics", "Books")
add_hop("t", home .. "/vault/Internship", "Thesis")

require("bunny"):setup({
	hops = hops,
	desc_strategy = "path",
	ephemeral = true,
	tabs = true,
	notify = false,
	fuzzy_cmd = "fzf",
})
