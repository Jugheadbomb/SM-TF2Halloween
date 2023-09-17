# [TF2] Halloween
Description: Plugin makes some halloween atmosphere!

## Dependencies
- Sourcemod 1.11+
- [TF2 Attributes](https://github.com/FlaminSarge/tf2attributes)

## Recommended to use with
- [Halloween cosmetics enabler](https://github.com/Mikusch/HalloweenCosmeticEnabler) - Please use this instead of `tf_forced_holiday`

## Features list
- Health/Ammo pickup sounds
- Spray sound (boo!)
- Spooky sounds on connect
- Round start sounds
- Halloween soundscape replacement (don't work on halloween maps)
- Round end sounds replacement (like on Helltower)
- Halloween weapon/cosmetic spells
- <details>
  <summary>Zombie souls</summary>
  <img src="https://github.com/FlaminSarge/tf2attributes/assets/53791065/04dc4d78-c34f-4415-b531-adb2831a11e7">
  </details>
- <details>
  <summary>Zombie viewmodels</summary>
  <img src="https://github.com/FlaminSarge/tf2attributes/assets/53791065/4b01648f-ad16-4803-8a79-0f204405598b">
  </details>
- <details>
  <summary>Tombstone on death</summary>
  <img src="https://github.com/FlaminSarge/tf2attributes/assets/53791065/44862848-e1ae-4b0e-9bd2-05b01a068cea">
  </details>
- <details>
  <summary>Projectile model replacement (no collision changes)</summary>
  <img src="https://static.wikia.nocookie.net/villains/images/0/04/Monoculus_proj.png/revision/latest?cb=20120616030917">
  </details>
- <details>
  <summary>Skybox and color correction changes (don't work on halloween maps)</summary>
  <img src="https://github.com/FlaminSarge/tf2attributes/assets/53791065/bc60d8bc-b9a8-4484-9178-cfbf99fb55b2">
  </details>
- <details>
  <summary>Resupply locker and ammopack model changes</summary>
  <img src="https://github.com/FlaminSarge/tf2attributes/assets/53791065/f369e6d0-09bd-4807-8f2a-dc35ccdb784f">
  <img src="https://github.com/FlaminSarge/tf2attributes/assets/53791065/af63626d-13df-413e-8449-e73ace59758a">
  </details>
- <details>
  <summary>Objective capture and static effects</summary>
  <img src="https://github.com/FlaminSarge/tf2attributes/assets/53791065/29bbf6aa-cf9c-4799-9df4-5c110a0edd49">
  <img src="https://github.com/FlaminSarge/tf2attributes/assets/53791065/8533fc08-6aa2-4ee0-a1d8-e29dabc15b16">
  </details>

## ConVars list
- sm_halloween_voodoo_souls - Toggle zombie souls (1: only zombie cosmetic, 2: cosmetic + zombie viewmodel) [Default: 2]
- sm_halloween_death_tomb - Toggle tombstone on death [Default: 1]
- sm_halloween_welcome_sounds - Toggle halloween join sounds [Default: 1]
- sm_halloween_round_sounds - Toggle round start/end sounds replacement [Default: 1]
- sm_halloween_pickup_sounds - Toggle health/ammo pickup sounds [Default: 1]
- sm_halloween_weapon_spells - Toggle halloween weapon spells [Default: 1]
- sm_halloween_cosmetic_spells - Toggle halloween random cosmetic spells [Default: 0]
- sm_halloween_eye_projectiles - Toggle eye projectile replacements [Default: 1]
- sm_halloween_soundscapes - Toggle halloween soundscapes replacement [Default: 1]
- sm_halloween_skyboxes - Toggle halloween skyboxes replacement [Default: 1]
- sm_halloween_colorcorrection - Toggle night color correction [Default: 1]
- sm_halloween_modelreplaces - Toggle ammopack/resupply locker model replacements [Default: 1]

	**P.S**: Plugin will create `plugin.halloween.cfg` in `cfg/sourcemod` with these cvars on startup