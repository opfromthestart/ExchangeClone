local stone_group = "cracky"
if exchangeclone.mineclone then
	stone_group = "pickaxey"
end

exchangeclone.hammer_action = {
	start_action = function(player, center, range)
		if exchangeclone.check_cooldown(player, "hammer") then return end
		local data = {}
		exchangeclone.multidig[player:get_player_name()] = true -- to prevent doing 3x3 as well as AOE
		exchangeclone.play_ability_sound(player)
		data.player_energy = exchangeclone.get_player_energy(player)
		data.energy_cost = 0
		return data
	end,
	action = function(player, pos, node, data)
		if data.energy_cost + 8 > data.player_energy then return end
		if minetest.get_item_group(node.name, stone_group) ~= 0 then
			if minetest.is_protected(pos, player:get_player_name()) then
				minetest.record_protection_violation(pos, player:get_player_name())
			else
				data.energy_cost = data.energy_cost + 8
				local drops = minetest.get_node_drops(node.name, "exchangeclone:red_matter_hammer")
				exchangeclone.drop_items_on_player(pos, drops, player)
				minetest.set_node(pos, {name = "air"})
			end
		end
		return data
	end,
	end_action = function(player, center, range, data)
		exchangeclone.set_player_energy(player, data.player_energy - data.energy_cost)
		exchangeclone.multidig[player:get_player_name()] = nil
		exchangeclone.start_cooldown(player, "hammer", range/2) -- The hammer has by far the most lag potential and therefore a long cooldown.
	end
}

local function hammer_on_place(itemstack, player, pointed_thing)
    local click_test = exchangeclone.check_on_rightclick(itemstack, player, pointed_thing)
    if click_test ~= false then
        return click_test
    end

    if player:get_player_control().aux1 then
        if itemstack:get_name():find("dark") then
            return exchangeclone.range_update(itemstack, player, 3)
        else
            return exchangeclone.range_update(itemstack, player, 4)
        end
    end

	if player:get_player_control().sneak then
		local current_name = itemstack:get_name()
		if string.sub(current_name, -4, -1) == "_3x3" then
			itemstack:set_name(string.sub(current_name, 1, -5))
			minetest.chat_send_player(player:get_player_name(), "Single node mode")
		else
			itemstack:set_name(current_name.."_3x3")
			minetest.chat_send_player(player:get_player_name(), "3x3 mode")
		end
		return itemstack
	end

    local range = itemstack:get_meta():get_int("exchangeclone_item_range")
    local center = player:get_pos()
    if pointed_thing.type == "node" then
        center = pointed_thing.under
    end
    exchangeclone.node_radius_action(player, center, range, exchangeclone.hammer_action)
end

minetest.register_tool("exchangeclone:dark_matter_hammer", {
	description = "Dark Matter Hammer",
	wield_image = "exchangeclone_dark_matter_hammer.png",
	inventory_image = "exchangeclone_dark_matter_hammer.png",
	groups = { tool=1, hammer=1, dig_speed_class=7, enchantability=0, dark_matter_hammer = 1 },
	wield_scale = exchangeclone.wield_scale,
	tool_capabilities = {
		-- 1/1.2
		full_punch_interval = 0.5,
		max_drop_level=5,
		damage_groups = {fleshy=7},
		punch_attack_uses = 0,
		groupcaps={
			cracky = {times={[1]=1.5, [2]=0.75, [3]=0.325}, uses=0, maxlevel=4},
		},
	},
	sound = { breaks = "default_tool_breaks" },
	_mcl_toollike_wield = true,
	_mcl_diggroups = {
		pickaxey = { speed = 16, level = 7, uses = 0 }
	},
    on_place = hammer_on_place,
    on_secondary_use = hammer_on_place,
})

minetest.register_tool("exchangeclone:dark_matter_hammer_3x3", {
	description = "Dark Matter Hammer",
	wield_image = "exchangeclone_dark_matter_hammer.png",
	inventory_image = "exchangeclone_dark_matter_hammer.png",
	groups = { tool=1, hammer=1, dig_speed_class=7, enchantability=0, dark_matter_hammer = 1, not_in_creative_inventory = 1 },
	wield_scale = exchangeclone.wield_scale,
	tool_capabilities = {
		-- 1/1.2
		full_punch_interval = 0.5,
		max_drop_level=5,
		damage_groups = {fleshy=7},
		punch_attack_uses = 0,
		groupcaps={
			cracky = {times={[1]=1.8, [2]=0.9, [3]=0.5}, uses=0, maxlevel=4},
		},
	},
	sound = { breaks = "default_tool_breaks" },
	_mcl_toollike_wield = true,
	_mcl_diggroups = {
		pickaxey = { speed = 12, level = 7, uses = 0 }
	},
    on_place = hammer_on_place,
    on_secondary_use = hammer_on_place,
})

minetest.register_tool("exchangeclone:red_matter_hammer", {
	description = "Red Matter Hammer",
	wield_image = "exchangeclone_red_matter_hammer.png",
	inventory_image = "exchangeclone_red_matter_hammer.png",
	groups = { tool=1, hammer=1, dig_speed_class=7, enchantability=0, red_matter_hammer = 1 },
	wield_scale = exchangeclone.wield_scale,
	tool_capabilities = {
		-- 1/1.2
		full_punch_interval = 0.3,
		max_drop_level=5,
		damage_groups = {fleshy=9},
		punch_attack_uses = 0,
		groupcaps={
			cracky = {times={[1]=1, [2]=0.5, [3]=0.2}, uses=0, maxlevel=5},
		},
	},
	sound = { breaks = "default_tool_breaks" },
	_mcl_toollike_wield = true,
	_mcl_diggroups = {
		pickaxey = { speed = 19, level = 8, uses = 0 }
	},
    on_place = hammer_on_place,
    on_secondary_use = hammer_on_place,
})

minetest.register_tool("exchangeclone:red_matter_hammer_3x3", {
	description = "Red Matter Hammer",
	wield_image = "exchangeclone_red_matter_hammer.png",
	inventory_image = "exchangeclone_red_matter_hammer.png",
	groups = { tool=1, hammer=1, dig_speed_class=7, enchantability=0, red_matter_hammer = 1, not_in_creative_inventory = 1 },
	wield_scale = exchangeclone.wield_scale,
	tool_capabilities = {
		-- 1/1.2
		full_punch_interval = 0.3,
		max_drop_level=5,
		damage_groups = {fleshy=9},
		punch_attack_uses = 0,
		groupcaps={
			cracky = {times={[1]=1.25, [2]=0.6, [3]=0.3}, uses=0, maxlevel=5},
		},
	},
	sound = { breaks = "default_tool_breaks" },
	_mcl_toollike_wield = true,
	_mcl_diggroups = {
		pickaxey = { speed = 14, level = 8, uses = 0 }
	},
    on_place = hammer_on_place,
    on_secondary_use = hammer_on_place,
})

minetest.register_craft({
    output = "exchangeclone:dark_matter_hammer",
    recipe = {
        {"exchangeclone:dark_matter", exchangeclone.diamond_itemstring, "exchangeclone:dark_matter"},
        {"", exchangeclone.diamond_itemstring, ""},
        {"", exchangeclone.diamond_itemstring, ""}
    }
})

minetest.register_craft({
    output = "exchangeclone:red_matter_hammer",
    recipe = {
        {"exchangeclone:red_matter", "exchangeclone:dark_matter", "exchangeclone:red_matter"},
        {"", "group:dark_matter_hammer", ""},
        {"", "exchangeclone:dark_matter", ""}
    }
})