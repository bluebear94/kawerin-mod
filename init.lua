minetest.register_node(
	"kawerin:doujin_block",
	{
		description = "同人ブロック",
		tiles = {"dame.png"},
		groups = {cracky = 3, stone = 1}
	}
)

minetest.register_node(
	"kawerin:master_spark",
	{
		description = "マスタースパーク",
		tiles = {"masterspark.png"},
		groups = {},
		post_effect_color = {
			r = 255, g = 255, b = 255, a = 96
		},
		sunlight_propagages = true,
		walkable = false,
		buildable_to = true,
		light_source = 14,
		damage_per_second = 5,
		--[[node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, 99.5, 0.5}
		},]]
	}
)

minetest.register_abm({
	nodenames = {"kawerin:master_spark"},
	interval = 0.5,
	chance = 15,
	action = function(pos, node, active_object_count, active_object_count_wider)
		minetest.add_node(pos, {name = "air"})
	end
})

minetest.register_node(
	"kawerin:mini_hakkero",
	{
		description = "ミニ八卦炉",
		tiles = {
			"mini_hakkero_top.png", "mini_hakkero_bottom.png", 
			"mini_hakkero_side.png", "mini_hakkero_side.png", 
			"mini_hakkero_side.png", "mini_hakkero_side.png", 
		},
		groups = {snappy = 1, choppy = 2, oddly_breakable_by_hand = 2}
	}
)

MASTER_SPARK_HEIGHT = 20

minetest.register_abm({
	nodenames = {"kawerin:mini_hakkero"},
	interval = 1.0,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local n = vector.new(pos.x, pos.y, pos.z - 1)
		local s = vector.new(pos.x, pos.y, pos.z + 1)
		local w = vector.new(pos.x - 1, pos.y, pos.z)
		local e = vector.new(pos.x + 1, pos.y, pos.z)
		local isMese = function(node)
			return node.name == "default:mese" or
					node.name == "default:diamondblock"
		end
		if not (isMese(minetest.get_node(n)) and isMese(minetest.get_node(s)) and
				isMese(minetest.get_node(e)) and isMese(minetest.get_node(w))) then
			return
		end
		minetest.add_node(pos, {name = "default:tree"})
		minetest.add_node(w, {name = "air"})
		minetest.add_node(e, {name = "air"})
		minetest.add_node(n, {name = "air"})
		minetest.add_node(s, {name = "air"})
		for x = -1, 1 do
			for z = -1, 1 do
				for y = 1, MASTER_SPARK_HEIGHT do
					minetest.add_node(
						vector.new(pos.x + x, pos.y + y, pos.z + z),
						{name = "kawerin:master_spark"}
					)
				end
			end
		end
		minetest.chat_send_all("恋符「マスタースパーク」")
	end
})

minetest.register_craft({
	output = "kawerin:mini_hakkero",
	recipe = {
		{"default:steel_ingot", "default:mese", "default:steel_ingot"},
		{"default:mese", "group:wood", "default:mese"},
		{"default:steel_ingot", "default:mese", "default:steel_ingot"}
	}
})

minetest.register_craft({
	output = "kawerin:mini_hakkero",
	recipe = {
		{"default:steel_ingot", "default:diamondblock", "default:steel_ingot"},
		{"default:diamondblock", "group:wood", "default:diamondblock"},
		{"default:steel_ingot", "default:diamondblock", "default:steel_ingot"}
	}
})

power_reduction = {
	["kawerin:conduit"] = 8,
}

minetest.register_node(
	"kawerin:conduit",
	{
		description = "コンデュイット",
		tiles = {"conduit.png", "conduit.png", "conduit.png"},
		groups = {cracky = 3, oddly_breakable_by_hand = 2, conduit = 1},
		drawtype = "nodebox",
		paramtype = "light",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.125, -0.125, 0.5, 0.125, 0.125},
				{-0.125, -0.125, -0.5, 0.125, 0.125, 0.5},
				{-0.125, -0.5, -0.125, 0.125, 0.5, 0.125}
			}
		},
		on_rightclick = function(pos, node, player, itemstack, pointed_thing)
			minetest.chat_send_player(player:get_player_name(), tostring(node.param2))
		end,
		on_construct = function(pos)
			minetest.get_node(pos).param2 = 0
		end
	}
)

minetest.register_craft({
	output = "kawerin:conduit 48",
	recipe = {
		{"", "default:copper_ingot", ""},
		{"default:copper_ingot", "default:copper_ingot", "default:copper_ingot"},
		{"", "default:copper_ingot", ""}
	}
})

-- TODO replace with block update version?
minetest.register_abm({
	nodenames = {"group:conduit"},
	neighbors = {"group:conduit"},
	interval = 1.0,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local pr = power_reduction[node.name]
		local getPowerLevel = function(pos)
			local node = minetest.get_node_or_nil(pos)
			if not node then return 0 end
			if node.name == "kawerin:power_block" then
				return 255 + pr -- Compensate for power loss through wires
			end
			if minetest.get_item_group(node.name, "conduit") ~= 0 then
				return node.param2
			end
			return 0
		end
		local n = vector.new(pos.x, pos.y, pos.z - 1)
		local s = vector.new(pos.x, pos.y, pos.z + 1)
		local w = vector.new(pos.x - 1, pos.y, pos.z)
		local e = vector.new(pos.x + 1, pos.y, pos.z)
		local u = vector.new(pos.x, pos.y + 1, pos.z)
		local d = vector.new(pos.x, pos.y - 1, pos.z)
		node.param2 = math.max(0,
				getPowerLevel(n) - pr, getPowerLevel(s) - pr,
				getPowerLevel(e) - pr, getPowerLevel(w) - pr,
				getPowerLevel(u) - pr, getPowerLevel(d) - pr)
		minetest.add_node(pos, node)
	end
})

minetest.register_node(
	"kawerin:power_block",
	{
		description = "パワーブロック",
		tiles = {"power_block.png"},
		groups = {cracky = 3},
		light_source = 7
	}
)
