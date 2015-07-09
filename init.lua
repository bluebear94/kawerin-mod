default = {}
dofile(minetest.get_modpath("default") .. "/functions.lua") -- Import default sounds

minetest.register_node(
	"kawerin:doujin_block",
	{
		description = "同人ブロック",
		tiles = {"kawerin_dame.png"},
		groups = {cracky = 3, stone = 1}
	}
)

minetest.register_node(
	"kawerin:master_spark",
	{
		description = "マスタースパーク",
		tiles = {"kawerin_masterspark.png"},
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
			"kawerin_mini_hakkero_top.png", "kawerin_mini_hakkero_bottom.png", 
			"kawerin_mini_hakkero_side.png", "kawerin_mini_hakkero_side.png", 
			"kawerin_mini_hakkero_side.png", "kawerin_mini_hakkero_side.png", 
		},
		groups = {snappy = 1, choppy = 2, oddly_breakable_by_hand = 2},
		sounds = default.node_sound_wood_defaults()
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

function isConduit(node)
	return minetest.get_item_group(node.name, "conduit") ~= 0
end

function isThereConduit(pos)
	return isConduit(minetest.get_node(pos))
end

function getPowerLevel(pos, pr)
	local node = minetest.get_node_or_nil(pos)
	if not node then return 0 end
	if node.name == "kawerin:power_block" then
		return 255 + pr -- Compensate for power loss through wires
	end
	if isConduit(node) then
		return node.param2
	end
	return 0
end

function getPowerLevelG(pos) -- used for gates
	local node = minetest.get_node_or_nil(pos)
	if not node then return 0 end
	if node.name == "kawerin:power_block" then
		return 255
	end
	if isConduit(node) then
		return node.param2
	end
	return 0
end

CONDUIT_MODEL = {
	{-0.5, -0.125, -0.125, 0.5, 0.125, 0.125},
	{-0.125, -0.125, -0.5, 0.125, 0.125, 0.5},
	{-0.125, -0.5, -0.125, 0.125, 0.5, 0.125}
}

function registerConduit(name, description, tile, pr)
	minetest.register_node(
		name,
		{
			description = description,
			tiles = {tile, tile, tile},
			groups = {cracky = 3, oddly_breakable_by_hand = 2, conduit = pr},
			drawtype = "nodebox",
			paramtype = "light",
			node_box = {
				type = "fixed",
				fixed = CONDUIT_MODEL
			},
			on_rightclick = function(pos, node, player, itemstack, pointed_thing)
				minetest.chat_send_player(player:get_player_name(), tostring(node.param2))
			end,
			on_construct = function(pos)
				minetest.get_node(pos).param2 = 0
				updateConduitMain(pos)
			end,
			after_destruct = updateSurroundingConduits,
			sounds = default.node_sound_stone_defaults()
		}
	)
end

registerConduit("kawerin_kawerin:conduit", "コンデュイット", "default_copper_block.png", 12)
registerConduit("kawerin_kawerin:silver_conduit", "銀のコンデュイット", "silver_block.png", 6)
registerConduit("kawerin_kawerin:gold_conduit", "金のコンデュイット", "default_gold_block.png", 4)
registerConduit("kawerin_kawerin:nyan_conduit", "にゃんにゃんコンデュイット", "default_nc_rb.png", 2)

minetest.register_craft({
	output = "kawerin:conduit 48",
	recipe = {
		{"", "default:copper_ingot", ""},
		{"default:copper_ingot", "default:copper_ingot", "default:copper_ingot"},
		{"", "default:copper_ingot", ""}
	}
})

minetest.register_craft({
	output = "kawerin:silver_conduit 8",
	recipe = {
		{"group:conduit", "group:conduit", "group:conduit"},
		{"group:conduit", "kawerin:silver_ingot", "group:conduit"},
		{"group:conduit", "group:conduit", "group:conduit"}
	}
})

minetest.register_craft({
	output = "kawerin:gold_conduit 8",
	recipe = {
		{"group:conduit", "group:conduit", "group:conduit"},
		{"group:conduit", "default:gold_ingot", "group:conduit"},
		{"group:conduit", "group:conduit", "group:conduit"}
	}
})

minetest.register_craft({
	output = "kawerin:nyan_conduit 4",
	recipe = {
		{"default:nyancat_rainbow", "group:conduit", "default:nyancat_rainbow"},
		{"group:conduit", "default:nyancat", "group:conduit"},
		{"default:nyancat_rainbow", "group:conduit", "default:nyancat_rainbow"}
	}
})

minetest.register_node(
	"kawerin:power_block",
	{
		description = "パワーブロック",
		tiles = {"kawerin_power_block.png"},
		groups = {cracky = 3},
		light_source = 7,
		after_destruct = updateSurroundingConduits
	}
)

minetest.register_craft({
	output = "kawerin:power_block",
	recipe = {
		{"group:conduit", "group:conduit", "group:conduit"},
		{"group:conduit", "default:copper_ingot", "group:conduit"},
		{"group:conduit", "group:conduit", "group:conduit"}
	}
})

conductors = {
	["default:steelblock"] = true,
	["default:goldblock"] = true,
	["default:copperblock"] = true,
	["default:bronzeblock"] = true
}

function updateSurroundingConduits(pos)
	local n = vector.new(pos.x, pos.y, pos.z - 1)
	local s = vector.new(pos.x, pos.y, pos.z + 1)
	local w = vector.new(pos.x - 1, pos.y, pos.z)
	local e = vector.new(pos.x + 1, pos.y, pos.z)
	local u = vector.new(pos.x, pos.y + 1, pos.z)
	local d = vector.new(pos.x, pos.y - 1, pos.z)
	updateConduitMain(n)
	updateConduitMain(s)
	updateConduitMain(w)
	updateConduitMain(e)
	updateConduitMain(u)
	updateConduitMain(d)
end

function updateConduitMain(pos)
	local coUpdate = coroutine.create(updateConduit)
	coroutine.resume(coUpdate, pos, nil)
	while coroutine.resume(coUpdate) do end
end

function updateConduitP(nx, cr, previous)
	if (isThereConduit(nx)) then updateConduitD(pos, previous) end
end

function updateConduitD(nx, cr, previous)
	if (nx ~= previous) then updateConduit(nx, cr) end
end

function updateConduit(pos, previous)
	print(pos.x .. " " .. pos.y .. " " .. pos.z)
	coroutine.yield()
	local node = minetest.get_node(pos)
	local name = node.name
	local n = vector.new(pos.x, pos.y, pos.z - 1)
	local s = vector.new(pos.x, pos.y, pos.z + 1)
	local w = vector.new(pos.x - 1, pos.y, pos.z)
	local e = vector.new(pos.x + 1, pos.y, pos.z)
	local u = vector.new(pos.x, pos.y + 1, pos.z)
	local d = vector.new(pos.x, pos.y - 1, pos.z)
	local pr = minetest.get_item_group(node.name, "conduit")
	if not pr then pr = 8 end
	if isConduit(node) then
		local oldPower = node.param2
		local newPower = math.max(0,
				getPowerLevel(n, pr) - pr, getPowerLevel(s, pr) - pr,
				getPowerLevel(e, pr) - pr, getPowerLevel(w, pr) - pr,
				getPowerLevel(u, pr) - pr, getPowerLevel(d, pr) - pr)
		if newPower ~= oldPower then
			node.param2 = newPower
			minetest.add_node(pos, node)
			updateConduitD(n, pos, previous)
			updateConduitD(s, pos, previous)
			updateConduitD(w, pos, previous)
			updateConduitD(e, pos, previous)
			updateConduitD(u, pos, previous)
			updateConduitD(d, pos, previous)
		end
	else return end
end

function createOreSet(properties)
	minetest.register_node(
		properties.oreName,
		{
			description = properties.oreDescription,
			tiles = {"default_stone.png^" .. properties.oreTexture},
			is_ground_content = true,
			groups = {cracky = properties.crackyLevel},
			drop = properties.lumpName,
			sounds = default.node_sound_stone_defaults()
		}
	)
	minetest.register_node(
		properties.blockName,
		{
			description = properties.blockDescription,
			tiles = {properties.blockTexture},
			is_ground_content = true,
			groups = {cracky = properties.crackyLevel, level = properties.mineLevel},
			sounds = default.node_sound_stone_defaults()
		}
	)
	minetest.register_craftitem(
		properties.lumpName,
		{
			description = properties.lumpDescription,
			inventory_image = properties.lumpTexture
		}
	)
	minetest.register_craftitem(
		properties.ingotName,
		{
			description = properties.ingotDescription,
			inventory_image = properties.ingotTexture
		}
	)
	minetest.register_craft({
		type = "cooking",
		output = properties.ingotName,
		recipe = properties.lumpName
	})
	local row = {properties.ingotName, properties.ingotName, properties.ingotName}
	minetest.register_craft({
		output = properties.blockName,
		recipe = {row, row, row}
	})
	minetest.register_craft({
		type = "shapeless",
		output = properties.ingotName .. " 9",
		recipe = {properties.blockName}
	})
	local oreDist = properties.oreDist
	for _, o in ipairs(oreDist) do
		minetest.register_ore({
			ore_type = "scatter",
			ore = properties.oreName,
			wherein = "default:stone",
			clust_scarcity = o.s,
			clust_num_ores = o.n,
			clust_size = o.z,
			height_min = o.hl,
			height_max = o.hh
		})
	end
end

createOreSet({
	oreName = "kawerin:stone_with_silver",
	lumpName = "kawerin:silver_lump",
	ingotName = "kawerin:silver_ingot",
	blockName = "kawerin:silver_block",
	oreDescription = "銀の鉱石",
	lumpDescription = "銀の塊",
	ingotDescription = "銀のインゴット",
	blockDescription = "銀のブロック",
	oreTexture = "kawerin_silver_ore.png",
	lumpTexture = "kawerin_silver_lump.png",
	ingotTexture = "kawerin_silver_ingot.png",
	blockTexture = "kawerin_silver_block.png",
	crackyLevel = 2,
	mineLevel = 2,
	oreDist = {
		{
			s = 12*12*12,
			n = 4,
			z = 3,
			hl = -256,
			hh = -64
		},
		{
			s = 10*10*10,
			n = 6,
			z = 4,
			hl = -31000,
			hh = -256
		}
	}
})