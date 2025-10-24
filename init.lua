-- Muzzleloaders Mod for Minetest
-- Adds a musket (heavy drop, fixed damage) and blunderbuss (short-range, distance-scaling damage with spread)
-- With ammo reload mechanics, knockback, target knockback, nighttime muzzle flash, and custom sounds!

local modname = "muzzleloaders"

-- Ammo item
minetest.register_craftitem(modname .. ":ammo", {
    description = "Ammo\nFor muskets and blunderbusses",
    inventory_image = "muzzleloaders_ammo.png",  -- Your custom ammo icon
    stacks_max = 99,
})

-- Ammo crafting (4 per craft)
minetest.register_craft({
    type = "shapeless",
    output = modname .. ":ammo 4",
    recipe = {"default:coal_lump", "default:iron_ingot", "default:gravel"},
})

-- Shared projectile entity
minetest.register_entity(modname .. ":projectile", {
    physical = false,
    visual = "sprite",
    textures = {"muzzleloaders_projectile.png"},  -- Your custom bullet visual
    visual_size = {x = 0.1, y = 0.1},
    collisionbox = {{0, 0, 0}, {0, 0, 0}},
    timer = 0,
    lifetime = 3,  -- Max travel time (seconds)
    velocity = vector.new(),
    grav = 0,
    damage = 0,
    target_kb = 0,  -- Target knockback strength
    start_pos = nil,
    radius = 1,

    on_activate = function(self, staticdata, dtime_s)
        self.timer = 0
        -- Default vel/grav if not set by spawner
        if not self.velocity then self.velocity = vector.new() end
        if not self.grav then self.grav = 0 end
        if not self.target_kb then self.target_kb = 0 end
    end,

    on_step = function(self, dtime)
        self.timer = self.timer + dtime
        if self.timer > self.lifetime then
            self.object:remove()
            return
        end

        local pos = self.object:get_pos()
        -- Apply custom gravity to Y velocity
        self.velocity.y = self.velocity.y - (self.grav * dtime)
        self.object:set_velocity(self.velocity)

        -- Node collision (hit wall/floor)
        local node_pos = vector.round(pos)
        local node = minetest.get_node(node_pos)
        if node.name ~= "air" and node.name ~= "ignore" then
            self:impact(pos)
            return
        end

        -- Object collision (hit player/mob)
        for _, obj in pairs(minetest.get_objects_inside_radius(pos, self.radius)) do
            if obj ~= self.object then
                local obj_ent = obj:get_luaentity()
                if obj_ent and obj_ent.name ~= modname .. ":projectile" then
                    -- Calculate damage
                    local calc_damage = self.damage
                    if self.start_pos then
                        local dist = vector.distance(self.start_pos, pos)
                        local factor = math.max(0, (15 - dist) / 13)
                        calc_damage = self.damage * factor
                    end
                    calc_damage = math.floor(calc_damage + 0.5)  -- Round to int

                    if calc_damage > 0 then
                        obj:punch(self.object, 1.0, {
                            full_punch_interval = 1.0,
                            damage_groups = {fleshy = calc_damage},
                        })

                        -- Apply target knockback
                        if self.target_kb > 0 then
                            local kb_dir = vector.normalize(self.velocity)
                            local kb_vec = vector.multiply(kb_dir, self.target_kb)
                            obj:add_velocity(kb_vec)
                        end
                    end
                    self:impact(pos)
                    return
                end
            end
        end
    end,

    impact = function(self, pos)
        -- Simple impact sound/effect (keeping default punch as requested)
        minetest.sound_play("default_punch_stone", {pos = pos, gain = 0.3, max_hear_distance = 10})
        self.object:remove()
    end,
})

-- Shoot function (shared, with blunderbuss spread and knockback)
local function shoot(user, speed, grav, base_damage, is_blunder, recoil_strength, target_kb_strength)
    local dir = user:get_look_dir()
    local pos = user:get_pos()
    pos.y = pos.y + 1.625  -- Eye height

    local num_pellets = is_blunder and 6 or 1
    local pellet_damage = base_damage / num_pellets
    local pellet_speed = speed * (is_blunder and 0.8 or 1.0)  -- Slightly slower for spread

    for i = 1, num_pellets do
        local spread_dir = vector.new(dir)
        if is_blunder then
            -- Add random spread for shotgun effect (small cone)
            spread_dir.x = spread_dir.x + (math.random(-20, 20) / 100)
            spread_dir.y = spread_dir.y + (math.random(-10, 10) / 100)
            spread_dir.z = spread_dir.z + (math.random(-20, 20) / 100)
            -- Normalize
            local len = vector.length(spread_dir)
            spread_dir = vector.divide(spread_dir, len)
        end

        local obj = minetest.add_entity(pos, modname .. ":projectile")
        if obj then
            local ent = obj:get_luaentity()
            if ent then
                ent.velocity = vector.multiply(spread_dir, pellet_speed)
                ent.grav = grav
                ent.damage = pellet_damage
                ent.target_kb = target_kb_strength  -- Set target knockback
                if is_blunder then
                    ent.start_pos = vector.new(pos)
                    ent.radius = 1.5  -- Wider hit detection for spread
                    ent.lifetime = 1  -- Short lifetime for close range
                end
            end
        end
    end

    -- Custom firing sound (without .ogg extension)
    local fire_sound = is_blunder and "blunderbuss" or "rifle"
    minetest.sound_play(fire_sound, {pos = pos, gain = 1.0, max_hear_distance = 20})

    -- Apply knockback to user (recoil)
    if recoil_strength > 0 then
        local recoil_dir = vector.new(dir)
        recoil_dir.y = recoil_dir.y + 0.2  -- Slight upward kick
        local recoil = vector.multiply(recoil_dir, -recoil_strength)
        user:add_velocity(recoil)
    end

    -- Nighttime muzzle flash
    local time = minetest.get_timeofday()
    if time > 0.75 or time < 0.25 then  -- Night/dark (adjust thresholds as needed)
        -- Muzzle position: slightly forward
        local muzzle_pos = vector.add(pos, vector.multiply(dir, 0.5))
        -- Particle spawner for flash (bright, short-lived glow)
        minetest.add_particlespawner({
            amount = 20,  -- Number of particles
            time = 0.1,   -- Lifetime (s)
            minpos = {x = muzzle_pos.x - 0.1, y = muzzle_pos.y - 0.1, z = muzzle_pos.z - 0.1},
            maxpos = {x = muzzle_pos.x + 0.1, y = muzzle_pos.y + 0.1, z = muzzle_pos.z + 0.1},
            minvel = {x = -1, y = -1, z = -1},  -- Slight random spread
            maxvel = {x = 1, y = 1, z = 1},
            minacc = vector.new(0, -10, 0),  -- Drop quickly
            maxacc = vector.new(0, -10, 0),
            minexptime = 0.05,
            maxexptime = 0.1,
            minsize = 0.5,
            maxsize = 1.0,
            texture = "default_flame.png",  -- Bright fire-like texture (placeholder)
            glow = 14,  -- Max glow for visibility in dark
        })
    end
end

-- Shared on_use logic (fire or reload)
local function weapon_on_use(itemstack, user, pointed_thing, shoot_params)
    local meta = itemstack:get_meta()
    local loaded = meta:get_int("loaded") or 0
    local pname = user:get_player_name()
    local controls = user:get_player_control()

    if controls.sneak then
        -- Reload
        if loaded == 1 then
            minetest.chat_send_player(pname, "Already loaded!")
            return itemstack
        end
        local inv = user:get_inventory()
        if not inv:contains_item("main", modname .. ":ammo 1") then
            minetest.chat_send_player(pname, "No ammo!")
            return itemstack
        end
        inv:remove_item("main", modname .. ":ammo 1")
        meta:set_int("loaded", 1)
        minetest.sound_play("reload", {to_player = pname, gain = 0.5})  -- Custom reload sound (without .ogg)
        minetest.chat_send_player(pname, "Reloaded!")
        return itemstack
    else
        -- Fire
        if loaded == 0 then
            minetest.chat_send_player(pname, "Reload first!")
            return itemstack
        end
        meta:set_int("loaded", 0)
        shoot(user, unpack(shoot_params))
        return itemstack
    end
end

-- Musket tool
minetest.register_tool(modname .. ":musket", {
    description = "Musket\nHeavy-dropping rifle (reload with sneak + right-click)",
    inventory_image = "muzzleloaders_musket.png",  -- Your custom musket icon
    groups = {flammable = 2},
    on_use = function(itemstack, user, pointed_thing)
        return weapon_on_use(itemstack, user, pointed_thing, {80, 30, 30, false, 2, 3})  -- speed, grav, dmg, is_blunder, recoil, target_kb
    end,
})

-- Blunderbuss tool
minetest.register_tool(modname .. ":blunderbuss", {
    description = "Blunderbuss\nClose-range spread weapon (reload with sneak + right-click)",
    inventory_image = "muzzleloaders_blunderbuss.png",  -- Your custom blunderbuss icon
    groups = {flammable = 2},
    on_use = function(itemstack, user, pointed_thing)
        return weapon_on_use(itemstack, user, pointed_thing, {25, 5, 20, true, 5, 6})  -- speed, grav, dmg, is_blunder, recoil, target_kb
    end,
})

-- Weapon crafting recipes
minetest.register_craft({
    type = "shapeless",
    output = modname .. ":musket",
    recipe = {"default:steel_ingot", "default:steel_ingot", "group:wood", "default:stick"},
})

minetest.register_craft({
    type = "shapeless",
    output = modname .. ":blunderbuss",
    recipe = {"default:steel_ingot", "group:wood", "default:stick", "default:coal_lump"},
})

print("[" .. modname .. "] Loaded with fixed sound references!")
