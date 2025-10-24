# Muzzleloaders Mod

A Minetest mod bringing authentic blackpowder firearms to your world! Fire long-range muskets with heavy projectile drop or close-quarters blunderbusses with damaging spread. Features include ammo-based reloading, realistic knockback (recoil and target push), and immersive nighttime muzzle flashes.

## Features
- **Musket**: Single-shot rifle with fast velocity but high gravity (heavy arc/drop). Deals 15 HP fixed damage. Slight recoil.
- **Blunderbuss**: Fires 6 pellets in a cone for shotgun-style spread. Damage scales with proximity (100% at 2 nodes, 0% at 15+ nodes; max 20 HP total). Stronger recoil and target knockback.
- **Ammo System**: Craft ammo; reload via sneak + right-click. Weapons start unloaded.
- **Knockback**: Players feel recoil; targets get pushed away on hit.
- **Muzzle Flash**: Bright particle burst at night for added immersion.
- **Projectiles**: Custom sprite entities with collision detection for nodes/objects.
- **Crafting**: Simple recipes using default items.

## Installation
1. Download/extract the mod to your Minetest `mods/` folder (e.g., `~/.minetest/mods/muzzleloaders/`).
2. Enable the mod in your world config (under "Mods" tab).
3. Restart Minetest and join/create a world.
4. Test in creative: `/give [yourname] muzzleloaders:musket` or craft in survival.

Requires Minetest 5.0+ and the `default` game.

## Usage
- **Firing**: Right-click while holding the weapon (must be loaded).
- **Reloading**: Sneak (hold Shift) + right-click. Consumes 1 ammo from inventory.
- **Controls Tip**: In multiplayer, sneak is server-synced—works reliably.
- **Balance Notes**: 
  - Musket speed: 60 nodes/s, gravity: 50 (drops fast).
  - Blunderbuss speed: 25 nodes/s, gravity: 5 (short range).
  - Recoil: 2 (musket) / 5 (blunderbuss). Target KB: 3 / 6 per pellet.

## Crafting Recipes
### Ammo (x4)
Shapeless: Coal Lump + Iron Ingot + Gravel

### Musket
Shapeless: 2x Steel Ingot + Wood + Stick

### Blunderbuss
Shapeless: Steel Ingot + Wood + Stick + Coal Lump

## Screenshots
*(Add your own here—e.g., ![Musket in action](screenshots/musket_fire.png))*

- Firing the musket at dusk with muzzle flash.
- Blunderbuss spread hitting a mob up close.

## Customization
- **Textures**: Edit PNGs in `textures/` (e.g., `muzzleloaders_musket.png`).
- **Tweaks**: Adjust params in `init.lua` (e.g., damage, speed, spread angle).
- **Sounds**: Replace defaults with custom OGGs via `minetest.sound_play`.
- **Expansion Ideas**: Add animations, multi-load, or flintlock jams!

## Dependencies
- **Required**: `default` (for base items/crafting).
- **Optional**: None.

## License
This mod is licensed under the MIT License. See `LICENSE` file for details (create one if needed).

## Credits
- Original concept and code assistance: Grok (built by xAI).
- Textures: Custom art by [Your Name].
- Thanks to the Minetest community for the API!

## Issues / Contributing
Report bugs on [GitHub](https://github.com/yourusername/muzzleloaders) or the Minetest forums. Pull requests welcome!

*Version 1.0 - Released October 2025*
