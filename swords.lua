local aoe_exclude = { --any entity not including "mobs" is automatically added to this list.
	["mobs_mc:spider_eyes"] = true,
	["mobs_mc:wither_skull"] = true,
	["mobs_mc:fireball"] = true,
	["mobs_mc:dragon_fireball"] = true,
	["mobs_mc:blaze_fireball"] = true,
	["mobs_mc:shulkerbullet"] = true,
	["mobs_mc:potion_arrow"] = true,
	["mobs_mc:llamaspit"] = true,
}

local hostile_mobs = { --for Red Matter Sword
	["mobs_mc:blaze"] = true,
	["mobs_mc:villager_zombie"] = true,
	["mobs_mc:endermite"] = true,
	["mobs_mc:killer_bunny"] = true,
	["mobs_mc:ghast"] = true,
	["mobs_mc:witch"] = true,
	["mobs_mc:zombie"] = true,
	["mobs_mc:baby_zombie"] = true,
	["mobs_mc:stray"] = true,
	["mobs_mc:enderdragon"] = true,
	["mobs_mc:magma_cube_big"] = true,
	["mobs_mc:piglin_brute"] = true,
	["mobs_mc:wither"] = true,
	["mobs_mc:skeleton"] = true,
	["mobs_mc:witherskeleton"] = true,
	["mobs_mc:slime_big"] = true,
	["mobs_mc:husk"] = true,
	["mobs_mc:evoker"] = true,
	["mobs_mc:creeper_charged"] = true,
	["mobs_mc:guardian_elder"] = true,
	["mobs_mc:guardian"] = true,
	["mobs_mc:creeper"] = true,
	["mobs_mc:vindicator"] = true,
	["mobs_mc:zoglin"] = true,
	["mobs_mc:baby_hoglin"] = true,
	["mobs_mc:silverfish"] = true,
	["mobs_mc:magma_cube_small"] = true,
	["mobs_mc:pillager"] = true,
	["mobs_mc:magma_cube_tiny"] = true,
	["mobs_mc:shulker"] = true,
	["mobs_mc:baby_husk"] = true,
	["mobs_mc:hoglin"] = true,
	["mobs_mc:slime_tiny"] = true,
	["mobs_mc:vex"] = true,
	["mobs_mc:illusioner"] = true,
}

minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_entities) do
		if not name:find("mobs") then
			aoe_exclude[name] = true
		end
	end
end)

exchangeclone.aoe_attack = function(info)
	if not info then return end
	local max_damage = info.max_damage
	local knockback = info.knockback
	local radius = info.radius
	local damage_all = info.damage_all --damage all mobs/players or just hostile ones
	local cooldown = info.cooldown or 0
	if not max_damage or not knockback or not radius then return end
	if damage_all == nil then damage_all = 1 end

	return function(itemstack, player, pointed_thing) --copied from MineClone's TNT; I would simply use the explosion function but it would hurt the player.
		-- Use pointed node's on_rightclick function first, if present
		local click_test = exchangeclone.check_on_rightclick(itemstack, player, pointed_thing)
        if click_test ~= false then
            return click_test
        end

		if exchangeclone.check_cooldown(player, "sword") then return end

		local player_energy = exchangeclone.get_player_energy(player)
		if player_energy >= 384 then
			exchangeclone.set_player_energy(player, player_energy - 384)
		else
			return
		end

		exchangeclone.play_ability_sound(player)

		local pos = player:get_pos()

		-- Entities in radius of explosion
		local objs = minetest.get_objects_inside_radius(pos, radius)

		-- Trace rays for entity damage
		for _, obj in pairs(objs) do
			local ent = obj:get_luaentity()

			-- Ignore items to lower lag
			if (obj:is_player()
				or (ent and not aoe_exclude[ent.name]
				and not (damage_all == 0 and not hostile_mobs[ent.name]))) --ignore hostile mobs if necessary
				and obj:get_hp() > 0 and obj ~= player then

				local opos = obj:get_pos()
				
				local distance = math.max(1, vector.distance(pos, opos))

				-- Punch entity with damage depending on explosion exposure and
				-- distance to explosion
				local punch_vec = vector.subtract(opos, pos)
				local punch_dir = vector.normalize(punch_vec)
				punch_dir = {x=punch_dir.x, y=punch_dir.y+0.3, z=punch_dir.z} -- knockback should be more upward
				local damage = math.min(max_damage, max_damage-distance)
				--minetest.log(dump({name=ent.name, distance=distance, damage=damage}))

				local sleep_formspec_doesnt_close_mt53 = false
				if obj:is_player() then
					local name = obj:get_player_name()
					if mcl_beds then
						local meta = obj:get_meta()
						if meta:get_string("mcl_beds:sleeping") == "true" then
							minetest.close_formspec(name, "") -- ABSOLUTELY NECESSARY FOR MT5.3 -- TODO: REMOVE THIS IN THE FUTURE
							sleep_formspec_doesnt_close_mt53 = true
						end
					end
				end

				if sleep_formspec_doesnt_close_mt53 then
					minetest.after(0.3,
						function() -- 0.2 is minimum delay for closing old formspec and open died formspec -- TODO: REMOVE THIS IN THE FUTURE
							if not obj:is_player() then
								return
							end
							if exchangeclone.mineclone then
								mcl_util.deal_damage(obj, damage, { type = "generic", direct = player})
							else
								obj:set_hp(obj:get_hp() - damage)
							end
							obj:add_velocity(vector.multiply(punch_dir, knockback/distance))
						end)
				else
					if exchangeclone.mineclone then
						mcl_util.deal_damage(obj, damage, { type = "generic", direct = player})
					else
						obj:set_hp(obj:get_hp() - damage)
					end
					obj:add_velocity(vector.multiply(punch_dir, knockback/distance))
				end
			end
		end
		exchangeclone.start_cooldown(player, "sword", cooldown)
	end
end

local red_matter_sword_action = function(itemstack, player, pointed_thing)
	local damage_all = itemstack:get_meta():get_int("exchangeclone_damage_all")
	if not damage_all == 0 then damage_all = 1 end

	if player:get_player_control().sneak then
		if damage_all == 0 then
			damage_all = 1
			minetest.chat_send_player(player:get_player_name(), "Damage all mobs")
		else
			damage_all = 0
			minetest.chat_send_player(player:get_player_name(), "Damage hostile mobs")
		end
		itemstack:get_meta():set_int("exchangeclone_damage_all", damage_all)
		return itemstack
	end

	local aoe_function = exchangeclone.aoe_attack({max_damage = 12, knockback = 20, radius = 7, damage_all = damage_all, cooldown = 0.2})
	aoe_function(itemstack, player, pointed_thing)
end

minetest.register_tool("exchangeclone:dark_matter_sword", {
	description = "Dark Matter Sword",
	wield_image = "exchangeclone_dark_matter_sword.png",
	inventory_image = "exchangeclone_dark_matter_sword.png",
	groups = { tool=1, sword=1, dig_speed_class=7, enchantability=0 },
	wield_scale = exchangeclone.wield_scale,
	tool_capabilities = {
		-- 1/1.2
		full_punch_interval = 0.25,
		max_drop_level=5,
		damage_groups = {fleshy=12},
		punch_attack_uses = 0,
		groupcaps={
			snappy = {times={[1]=0.95, [2]=0.45, [3]=0.15}, uses=0, maxlevel=4},
		},
	},
	on_secondary_use = exchangeclone.aoe_attack({max_damage = 10, knockback = 12, radius = 5, cooldown = 0.5}),
	on_place = exchangeclone.aoe_attack({max_damage = 10, knockback = 12, radius = 5, cooldown = 0.5}),
	sound = { breaks = "default_tool_breaks" },
	_mcl_toollike_wield = true,
	_mcl_diggroups = {
		swordy = { speed = 16, level = 7, uses = 0 }
	},
})

minetest.register_tool("exchangeclone:red_matter_sword", {
	description = "Red Matter Sword",
	wield_image = "exchangeclone_red_matter_sword.png",
	inventory_image = "exchangeclone_red_matter_sword.png",
	groups = { tool=1, sword=1, dig_speed_class=8, enchantability=0 },
	wield_scale = exchangeclone.wield_scale,
	tool_capabilities = {
		-- 1/1.2
		full_punch_interval = 0.17,
		max_drop_level=6,
		damage_groups = {fleshy=14},
		punch_attack_uses = 0,
		groupcaps={
			snappy = {times={[1]=0.6, [2]=0.25, [3]=0.1}, uses=0, maxlevel=5},
		},
	},
	on_secondary_use = red_matter_sword_action,
	on_place = red_matter_sword_action,
	sound = { breaks = "default_tool_breaks" },
	_mcl_toollike_wield = true,
	_mcl_diggroups = {
		swordy = { speed = 20, level = 7, uses = 0 }
	},
})

minetest.register_craft({
    output = "exchangeclone:dark_matter_sword",
    recipe = {
        {"exchangeclone:dark_matter"},
        {"exchangeclone:dark_matter"},
        {exchangeclone.diamond_itemstring}
    }
})

minetest.register_craft({
	output = "exchangeclone:red_matter_sword",
	recipe = {
		{"exchangeclone:red_matter"},
		{"exchangeclone:red_matter"},
		{"exchangeclone:dark_matter_sword"},
	}
})