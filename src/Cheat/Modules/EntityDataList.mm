#include "EntityDataList.h"

#include <Foundation/Foundation.h>

#include "../ModulesSharedData.h"

static ModulesSharedData *modulesSharedData = nullptr;
static EntityList *entity_list_module = nullptr;
static Camera *camera = nullptr;

static uint64_t PlayerControls_TypeInfo_ptr = 0;
static uint64_t PlayerControls_object_ptr = 0;

static uint64_t GunController_TypeInfo = 0;

const char *EntityDataList::getModuleName() {
	return "EntityDataList";
}

HIKARI_ALL_OBF
void EntityDataList::OnInit(void *shared_data) {
	modulesSharedData = (ModulesSharedData *)shared_data;
	entity_list_module = modulesSharedData->modulesManager->getModule<EntityList>();
	camera = modulesSharedData->modulesManager->getModule<Camera>();

	PlayerControls_TypeInfo_ptr = Offsets::PlayerControls_TypeInfo + modulesSharedData->baseAddress;
	PlayerControls_object_ptr = 0;
	GunController_TypeInfo = 0;

	srand(static_cast<unsigned int>(time(0)));
}

void EntityDataList::OnUpdate() {
	#ifdef M_DEBUG
		NSLog(@"[GC Log] [EntityDataList] have %d entities", entity_list_module->getEntityList().size());
	#endif

	int last_local_entity_team = local_entity_data.team;
	bzero(&local_entity_data, sizeof(struct EntityData));
	local_entity_data.team = last_local_entity_team;

	entity_data_list.clear();

	//std::thread updateThread(&EntityDataList::InternalUpdate, this);
	//updateThread.join();

	EntityDataList::InternalUpdate();
}

HIKARI_BRANCHING
HIKARI_STRING_ENCRYPTION
void EntityDataList::InternalUpdate() {
	uint64_t local_entity = entity_list_module->getLocalEntity();
	if (local_entity) {

		if (!PlayerControls_object_ptr) {
			uint64_t PlayerControls_TypeInfo = memory->read<uint64_t>(PlayerControls_TypeInfo_ptr);
			if (PlayerControls_TypeInfo >> 32) {
				PlayerControls_object_ptr = memory->read<uint64_t>(PlayerControls_TypeInfo + Offsets::Il2CppClass_staticFields);
			}
		} else {
			uint64_t player_controls = memory->read<uint64_t>(PlayerControls_object_ptr);
			if (player_controls) {
				uint64_t touch_controller = memory->read<uint64_t>(player_controls + Offsets::PlayerControls_touchController);
				local_entity_data.playerInputs = (touch_controller) ? memory->read<uint64_t>(touch_controller + Offsets::TouchController_playerInputs) : NULL;
			}
		}

		local_entity_data.object = local_entity;
		local_entity_data.team = memory->read<int8_t>(local_entity + Offsets::PlayerController_team);
		local_entity_data.photonPlayer = memory->read<uint64_t>(local_entity + Offsets::PlayerController_photonPlayer);

/*
		if (local_entity_data.photonPlayer) {
			Hashtable *local_customproperties = memory->read<Hashtable *>(local_entity_data.photonPlayer + Offsets::PhotonPlayer_customProperties);
			if (local_customproperties) {
				local_entity_data.team = local_customproperties->getUnboxedValueForKey<int>("team");
				local_entity_data.health = local_customproperties->getUnboxedValueForKey<int>("health");
			}
		}
*/


		uint64_t local_movement_controller = memory->read<uint64_t>(local_entity + Offsets::PlayerController_playerMovementController);
		if (local_movement_controller) {
			uint64_t sync_translation_data = memory->read<uint64_t>(local_movement_controller + Offsets::MovementController_syncTranslationData);
			if (sync_translation_data) {
				local_entity_data.positions.Root = memory->read<Vector3>(sync_translation_data + Offsets::MovementSnapshot_position);
			}
		}

		uint64_t local_aim_controller = memory->read<uint64_t>(local_entity + Offsets::PlayerController_playerAimController);
		if (local_aim_controller) {
			local_entity_data.aimingData = memory->read<uint64_t>(local_aim_controller + Offsets::AimController_aimingData);

			local_entity_data.rotation.x = memory->read<float>(local_entity_data.aimingData + Offsets::AimingData_aimXAngles);
			local_entity_data.rotation.y = memory->read<float>(local_entity_data.aimingData + Offsets::AimingData_aimYAngles + 0x4);

			Transform *camTransform = memory->read<Transform *>(local_aim_controller + Offsets::AimController_camTransform);
			if (camTransform)
				local_entity_data.positions.Head = camTransform->getPosition();
		}

		uint64_t local_weaponry_controller = memory->read<uint64_t>(local_entity + Offsets::PlayerController_weaponryController);
		if (local_weaponry_controller) {
			uint64_t current_weapon = memory->read<uint64_t>(local_weaponry_controller + Offsets::WeaponryController_currentWeapon);
			if (current_weapon) {
				uint64_t current_weapon_klass = memory->read<uint64_t>(current_weapon);

				if (!GunController_TypeInfo) {
					uint64_t klass_name_ptr = memory->read<uint64_t>(current_weapon_klass + 0x10);
					char klass_name[16];
					memory->readBuffer(klass_name_ptr, sizeof(klass_name), klass_name);

					if (!strcmp(klass_name, "GunController"))
						GunController_TypeInfo = current_weapon_klass;
				}

				local_entity_data.currentGunWeapon = (GunController_TypeInfo == current_weapon_klass) ? current_weapon : NULL;

				if (Vars::visuals_hitinfo.isOn) {
					if (local_entity_data.currentGunWeapon)
						this->HandleGunObject(local_entity_data.currentGunWeapon);
				}

			}
		}

	}

    std::vector<uint64_t> &entity_list = entity_list_module->getEntityList();
	for (auto entity : entity_list) {

		uint64_t entity_photon_player = memory->read<uint64_t>(entity + Offsets::PlayerController_photonPlayer);
		if (!entity_photon_player)
			continue;

		Hashtable *entity_customproperties = memory->read<Hashtable *>(entity_photon_player + Offsets::PhotonPlayer_customProperties);

		int8_t entity_team = memory->read<int8_t>(entity + Offsets::PlayerController_team);
		if (entity_team == local_entity_data.team)
			continue;

		EntityData entity_data = {
			.object = entity,
			.photonPlayer = entity_photon_player,
			.team = entity_team,
			.health = entity_customproperties->getUnboxedValueForKey<int>("health"),
			.untouchable = entity_customproperties->getUnboxedValueForKey<bool>("untouchable")
		};

		if (entity_data.health <= 0)
			continue;

		monoString *entity_name_string = memory->read<monoString *>(entity_photon_player + Offsets::PhotonPlayer_nameField);
		if (entity_name_string) {
			entity_name_string->getStringToBufferWithLength((char *)&entity_data.entityName, 16);
		}

		uint64_t movement_controller = memory->read<uint64_t>(entity + Offsets::PlayerController_playerMovementController);
		if (movement_controller) {
			uint64_t sync_translation_data = memory->read<uint64_t>(movement_controller + Offsets::MovementController_syncTranslationData);
			if (sync_translation_data) {
				entity_data.positions.Root = memory->read<Vector3>(sync_translation_data + Offsets::MovementSnapshot_position);
				entity_data.speed = memory->read<Vector3>(sync_translation_data + Offsets::MovementSnapshot_velocity).magnitude();
			}
		}

			uint64_t entity_view = memory->read<uint64_t>(entity + Offsets::PlayerController_playerCharacterView);
			if (entity_view) {
				memory->write<bool>(entity_view + Offsets::PlayerCharacterView_isVisible, true);
				uint64_t entity_bipedmap = memory->read<uint64_t>(entity_view + Offsets::PlayerCharacterView_bipedMap);
				if (entity_bipedmap) {
					// WorldToScreen использовал матрицу камеры, но этот код вырезан из проекта, написать его можно самостоятельно.
					camera->WorldToScreen(entity_data.positions.Root, &entity_data.screen_positions.Root);
					for (int i = 0; i < 22; i++) {
						Transform *bone_transform = memory->read<Transform *>(entity_bipedmap + Offsets::BipedMap_firstBone + (i * 8));
						if (bone_transform) {
						*(&entity_data.positions.Head + i) = bone_transform->getPosition();
						camera->WorldToScreen(*(&entity_data.positions.Head + i), (&entity_data.screen_positions.Head + i));
					}
				}

				Vector3 root_top_position = entity_data.positions.Root;
					root_top_position.y = entity_data.positions.Head.y;

				camera->WorldToScreen(root_top_position + Vector3(0, 0.25f, 0), &entity_data.screen_positions.RootTop);
				entity_data.on_screen = camera->WorldToScreen(entity_data.positions.Head + Vector3(0, 0.25f, 0), &entity_data.screen_positions.HeadTop);
			}
		}

		uint64_t occlusion_controller = memory->read<uint64_t>(entity + Offsets::PlayerController_playerOcclusionController);
		if (occlusion_controller) {
			int observation_state = memory->read<int>(occlusion_controller + Offsets::ObjectOcclude_state);
			entity_data.visible = (observation_state == 2) ? true : false; 
		}

		if (Vars::visuals_footsteps.isOn) {
			uint64_t arms_animation_controller = memory->read<uint64_t>(entity + Offsets::PlayerController_playerArmsAnimationController);
			if (arms_animation_controller) {

				if (entity_data.distance <= 30.f) { //footstep range
					if (entity_data.speed > 3.f) { //walk speed (3-4 and higher)
						float cur_footstep_cycle_progress = memory->read<float>(arms_animation_controller + Offsets::ArmsAnimationController_curFootstepCycleProgress);
						float half_offset_footstep_cycle_progress = memory->read<float>(arms_animation_controller + Offsets::ArmsAnimationController_halfOffsetFootstepCycleProgress);

						if (entity_data.visible) {
							int footstep_trace_state = memory->read<int>(arms_animation_controller + Offsets::ArmsAnimationController_footstepTraceState);
							if (footstep_trace_state == 0 || footstep_trace_state == 1) { //InProgress || InDeadzone
								if (cur_footstep_cycle_progress > 0.95f || half_offset_footstep_cycle_progress > 0.95f)
									this->HandleFootstep(entity, entity_data.positions.Root);
							}
						} else {
							int footstep_trace_state_fps = memory->read<int>(arms_animation_controller + Offsets::ArmsAnimationController_footstepTraceStateFPS);
							if (footstep_trace_state_fps == 2) { //Tracing
								if (cur_footstep_cycle_progress > 0.95f || half_offset_footstep_cycle_progress > 0.95f)
									this->HandleFootstep(entity, entity_data.positions.Root);
							}
						}	
					}
				}
			}
		}

		if (Vars::visuals_weaponname.isOn) {
			uint64_t weaponry_controller = memory->read<uint64_t>(entity + Offsets::PlayerController_weaponryController);
			if (weaponry_controller) {
				
				uint64_t current_weapon = memory->read<uint64_t>(weaponry_controller + Offsets::WeaponryController_currentWeapon);
				if (current_weapon) {
					uint64_t weapon_parameters = memory->read<uint64_t>(current_weapon + Offsets::WeaponController_weaponParameters);
					if (weapon_parameters) {
						monoString *weapon_name_string = memory->read<monoString *>(weapon_parameters + Offsets::InventoryParameters_displayName);
						if (weapon_name_string)
							weapon_name_string->getStringToBufferWithLength((char *)&entity_data.weaponName, 16);

					}

				}
			}	
		}

		entity_data_list.push_back(entity_data);
	}



	for (auto it = handled_entity_hit_data_list.begin(); it != handled_entity_hit_data_list.end(); ) {
	    if (!it->updated) {
	        it = handled_entity_hit_data_list.erase(it);
	        continue;
	    }
	    it->updated = false;
	    ++it;
	}

	for (auto it = entity_hit_data_list.begin(); it != entity_hit_data_list.end(); ) {
	    if (!it->ticks_left) {
	            it = entity_hit_data_list.erase(it);
	        continue;
	    }

		// WorldToScreen использовал матрицу камеры, но этот код вырезан из проекта, написать его можно самостоятельно.
		it->on_screen = camera->WorldToScreen(it->position, &it->screen);

	    if (it->on_screen) {
	        it->screen_offset.x += it->direction.x * it->speed;
	        it->screen_offset.y += it->direction.y * it->speed;

	        it->speed += it->acceleration;
		    if (it->speed < 3.75f) it->speed = 0.25f;

	        it->screen.x += it->screen_offset.x;
	        it->screen.y -= it->screen_offset.y;
	    }

	    it->ticks_left--;
	    ++it;
	}

	for (auto it = entity_footstep_data_list.begin(); it != entity_footstep_data_list.end(); ) {
		if (!it->ticks_left) {
			it = entity_footstep_data_list.erase(it);
			continue;
		}
		it->ticks_left--;
		++it;
	}
}

void EntityDataList::HandleGunObject(uint64_t gun_object) {
	monoDictionary<uint64_t, monoList<uint64_t> *> *character_hits = memory->read<monoDictionary<uint64_t, monoList<uint64_t> *> *>(gun_object + Offsets::GunController_characterHits);
	if (character_hits) {
		int entries_length = character_hits->getLength();
		monoDictionary<uint64_t, monoList<uint64_t> *>::Entry hits_entries[entries_length];
		character_hits->getEntriesToBufferWithLength(hits_entries, entries_length);

		for(int i = 0; i < entries_length; i++) {
			monoList<uint64_t> *current_hits_list = hits_entries[i].value;
			if (!current_hits_list)
				continue;

			int8_t victim_team = memory->read<int8_t>(hits_entries[i].key + Offsets::Controller_team);
			if (victim_team == local_entity_data.team)
				continue;

			int hits_list_length = current_hits_list->getLength();
			uint64_t hits_items_buffer[hits_list_length];
			current_hits_list->getItemsToBufferWithLength(hits_items_buffer, hits_list_length);

			for (int k = 0; k < hits_list_length; k++) {
				uint64_t current_hit = hits_items_buffer[k];
				if (!current_hit)
					continue;

				this->HandleHitData(hits_entries[i].key, current_hit);
			}
		}
	}
}

float RandomFloat(float min, float max) {
    float random = ((float) rand()) / (float) RAND_MAX;
    return min + random * (max - min);
}

void EntityDataList::HandleHitData(uint64_t victim_entity, uint64_t hit_data) {

	for (auto it = handled_entity_hit_data_list.begin(); it != handled_entity_hit_data_list.end(); ) {
	    if (it->object == hit_data) {
	    	it->updated = true;
	        return;
	    }
	    ++it;
	}
    handled_entity_hit_data_list.push_back({
    	.object = hit_data, 
    	.updated = true
    });

    int previous_damage = 0;
	for (auto it = entity_hit_data_list.begin(); it != entity_hit_data_list.end(); ) {
	    if (it->victim_entity == victim_entity) {

	    	previous_damage += it->damage;

	        it = entity_hit_data_list.erase(it);
	        continue;
	    }
	    ++it;
	}

		float armor_penetration = memory->read<float>(hit_data + Offsets::BulletHitData_armorPenetration);
		int total_damage = memory->read<int>(hit_data + Offsets::BulletHitData_damage);
			total_damage = (total_damage - (int)((float)total_damage * (100.f - armor_penetration) / 100.f)) + previous_damage;

	    // WorldToScreen использовал матрицу камеры, но этот код вырезан из проекта, написать его можно самостоятельно.
	    EntityHitData entity_hit_data = {
	        .object = hit_data,
	        .victim_entity = victim_entity,
        .position = memory->read<Vector3>(hit_data + Offsets::BulletHitData_point),
        .damage = total_damage,
        .ticks_left = EntityHitData::max_ticks,
        .on_screen = camera->WorldToScreen(entity_hit_data.position, &entity_hit_data.screen),
        .screen_offset = ImVec2(0.0f, 0.0f),
        .direction = ImVec2(RandomFloat(-1.0f, 1.0f), RandomFloat(0.8f, 1.0f)),
        .speed = RandomFloat(5.f, 5.25f),
        .acceleration = -0.20f
    };

    entity_hit_data_list.push_back(entity_hit_data);
}

void EntityDataList::HandleFootstep(uint64_t entity, Vector3 footstep_position) {
	for (auto current_footstep_data : entity_footstep_data_list) {
		if (current_footstep_data.object != entity)
			continue;
		if (current_footstep_data.ticks_left > (EntityFootstepData::max_ticks - 10))
			return;
	}

	EntityFootstepData entity_footstep_data = {
		.object = entity,
		.position = footstep_position,
		.ticks_left = EntityFootstepData::max_ticks //60p/s * 2sec
	};

	entity_footstep_data_list.push_back(entity_footstep_data);
}

std::vector<EntityDataList::EntityData> &EntityDataList::getEntityDataList() {
	return entity_data_list;
}

std::vector<EntityDataList::EntityHitData> &EntityDataList::getEntityHitDataList() {
	return entity_hit_data_list;
}

std::vector<EntityDataList::EntityFootstepData> &EntityDataList::getEntityFootstepDataList() {
	return entity_footstep_data_list;
}

EntityDataList::EntityData &EntityDataList::getLocalEntityData() {
	return local_entity_data;
}
