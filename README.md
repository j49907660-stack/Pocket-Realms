# Pocket Realms 0.0.2 — Dawnshore Island

An early playable browser prototype, built with Godot 4.3.

## New in 0.0.2
- Original compact island layout with one safe town, roads, port and dungeon landmark.
- Seven hunting areas, monsters levels 1–20, and a level-20 mini-boss.
- 3D mini-map with the player, monsters, roads, town, port and dungeon.
- Procedural low-poly trees, houses, player character, monster silhouettes, simple attack animation.
- Experience, character levels 1–20, monster respawn and XP loss on death.

**Prototype limitations:** The dungeon is an open-air ruin and boss encounter, not yet an instanced interior. NPC shops, quests, inventory, boat travel and multiplayer are not yet implemented. Monsters have simplified AI and generated placeholder meshes, not imported artist-created models. The ground is a tiled island rather than a sculpted terrain.

## Controls
- WASD or arrow keys: move
- Space: attack
- Touch: drag on left side to move; ATTACK button on right

## GitHub Pages
The included `.github/workflows/deploy.yml` builds Godot 4.3 Web and deploys to GitHub Pages. In repository Settings → Pages select **GitHub Actions**.
