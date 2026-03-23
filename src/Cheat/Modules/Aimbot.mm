#include "Aimbot.h"

#include <Foundation/Foundation.h>

#include "../ModulesSharedData.h"

static ModulesSharedData *modulesSharedData = nullptr;
static EntityDataList *entity_data_list_module = nullptr;
static Camera *camera = nullptr;

static uint64_t SurfaceTypeUtility_TypeInfo_ptr = NULL;
static uint64_t SurfaceTypeUtility_EnumByTag_ptr = NULL;

static int screen_w, screen_h = 0;
static Vector2 screen_center;

const char *Aimbot::getModuleName() {
	return "Aimbot";
}

inline bool IsOnScreen(ImVec2 *coords) {
    if (coords->x < 0.f || coords->x > screen_w)
        return false;
    if (coords->y < 0.f || coords->y > screen_h)
        return false;

    return true;
}

namespace Angles { 
    float ClampAngle(float angle) {
        float newAngle = fmodf(angle, 360.0f);
        if (newAngle < 0.f) {
            newAngle += 360.0f;
        }
        return newAngle;
    }
    float NormalizeAngle(float angle) {
        float newAngle = ClampAngle(angle);
        if (newAngle > 180.0f) {
            newAngle -= 360.0f;
        }
        return newAngle;
    }
    float LerpAngle(float from, float to, float speed) {
        float movingSpeed = speed;
        if (movingSpeed > 1) {
            movingSpeed = 1; //clamp
        }
        if (movingSpeed == 0) return from;
        if (movingSpeed == 1) return to;

        float delta = NormalizeAngle(to - from);
        float deltaMove = delta * movingSpeed;
        return NormalizeAngle(from + deltaMove);
    }
}

void Aimbot::OnInit(void *shared_data) {
	modulesSharedData = (ModulesSharedData *)shared_data;
	entity_data_list_module = modulesSharedData->modulesManager->getModule<EntityDataList>();
	camera = modulesSharedData->modulesManager->getModule<Camera>();

	screen_w = modulesSharedData->screen_w;
	screen_h = modulesSharedData->screen_h;
	screen_center = Vector2(screen_w / 2, screen_h / 2);

	SurfaceTypeUtility_TypeInfo_ptr = Offsets::SurfaceTypeUtility_TypeInfo + modulesSharedData->baseAddress;
	SurfaceTypeUtility_EnumByTag_ptr = NULL;
}

HIKARI_BRANCHING
void Aimbot::OnUpdate() {

screen_w = modulesSharedData->screen_w;
	screen_h = modulesSharedData->screen_h;
	screen_center = Vector2(screen_w / 2, screen_h / 2);

	#define _ current_entity_data.screen_positions.
	#define v current_entity_data.visible_data.

	EntityDataList::EntityData local_entity_data = entity_data_list_module->getLocalEntityData();
	if (local_entity_data.currentGunWeapon) {	
		if (Vars::aimbot_draw_recoil_point.isOn) {
			uint64_t recoil_control = memory->read<uint64_t>(local_entity_data.currentGunWeapon + Offsets::GunController_recoilControl);
			if (recoil_control) {

			    float local_time = memory->read<float>(recoil_control + Offsets::RecoilControl_localTime);
			    float last_shot_time = memory->read<float>(recoil_control + Offsets::RecoilControl_lastShotTime);
			    float delta_time = local_time - last_shot_time;

			    float recoil_accel_duration = 0.f;
			    uint64_t recoil_parameters = memory->read<uint64_t>(recoil_control + Offsets::RecoilControl_recoilParameters);
			    if (recoil_parameters)
			    	recoil_accel_duration = memory->read<float>(recoil_parameters + Offsets::RecoilParameters_recoilAccelDuration);

			    Vector2 recoilDeviation = memory->read<Vector2>(recoil_control + Offsets::RecoilControl_previousActualPoint);

			    if (delta_time > recoil_accel_duration) {
				    const float decay_value = 0.5f;
					float interpolation_coeff = std::min(delta_time / decay_value, 1.0f);
						recoilDeviation.x *= (1.0f - interpolation_coeff);
						recoilDeviation.y *= (1.0f - interpolation_coeff);
				}

				float currentPitch = local_entity_data.rotation.x;
				float currentYaw = local_entity_data.rotation.y;

				Vector3 cameraPosition = local_entity_data.positions.Head;

			    Quaternion rotation = Quaternion::FromEuler(currentPitch - recoilDeviation.x, currentYaw + recoilDeviation.y, 0);

			    Vector3 forward = rotation * Vector3(0, 0, 1.f);
			    Vector3 targetPoint = cameraPosition + forward.normalized() * 300;

			    ImVec2 screen_point;
			    // WorldToScreen использовал матрицу камеры, но этот код вырезан из проекта, написать его можно самостоятельно.
			    if (camera->WorldToScreen(targetPoint, &screen_point))
			        ImGui::GetForegroundDrawList()->AddCircleFilled(screen_point, 2.5f, ImColor(255, 0, 0, 255));
			}
		}

		if (Vars::misc_no_recoil.isOn) {
			memory->write<float>(local_entity_data.currentGunWeapon + Offsets::GunController_recoilMult, -0.00000001f); 
			memory->write<float>(local_entity_data.currentGunWeapon + Offsets::GunController_accuracyMult, 0.f);
			memory->write<float>(local_entity_data.currentGunWeapon + Offsets::GunController_accuracyAdditive, 0.f);
		}

		if (Vars::misc_increased_firerate.isOn) {
			int32_t salt = memory->read<int32_t>(local_entity_data.currentGunWeapon + Offsets::GunController_fireInterval);
			int32_t new_value = -1;
			int32_t new_encrypted_value = 0;
			if ((salt & 1) != 0)
				new_encrypted_value = new_value & 0xFF00FF00 | ((new_value & 0xFF) << 16) | ((new_value >> 16) & 0xFF);
			else
				new_encrypted_value = new_value ^ salt;

			memory->write<int>(local_entity_data.currentGunWeapon + Offsets::GunController_fireInterval + 0x4, new_encrypted_value);
		}

		if (Vars::misc_infinity_ammo.isOn) {
			int32_t salt = memory->read<int32_t>(local_entity_data.currentGunWeapon + Offsets::GunController_magazineCapacity);
			int32_t new_value = 30;
			int32_t new_encrypted_value = 0;
			if ((salt & 1) != 0)
				new_encrypted_value = new_value & 0xFF00FF00 | ((new_value & 0xFF) << 16) | ((new_value >> 16) & 0xFF);
			else
				new_encrypted_value = new_value ^ salt;

			memory->write<int>(local_entity_data.currentGunWeapon + Offsets::GunController_magazineCapacity + 0x4, new_encrypted_value);
		}


		static std::vector<monoString *> original_material_types;
		static monoString *smoke_material_string = NULL;
		static bool material_types_was_edited = false;

		if (!SurfaceTypeUtility_EnumByTag_ptr) {
			uint64_t SurfaceTypeUtility_TypeInfo = memory->read<uint64_t>(SurfaceTypeUtility_TypeInfo_ptr);
			if ((SurfaceTypeUtility_TypeInfo >> 32))
				SurfaceTypeUtility_EnumByTag_ptr = memory->read<uint64_t>(SurfaceTypeUtility_TypeInfo + Offsets::Il2CppClass_staticFields) + 0x8; 

			original_material_types.clear();
			smoke_material_string = NULL;
			material_types_was_edited = false;
		}

		if (SurfaceTypeUtility_EnumByTag_ptr) {

			monoArray<monoString *> *enumByTag = memory->read<monoArray<monoString *> *>(SurfaceTypeUtility_EnumByTag_ptr);
			int enumByTag_length = enumByTag->getLength();
			monoString *enumByTag_array[enumByTag_length];
    		enumByTag->getItemsToBufferWithLength(enumByTag_array, enumByTag_length);

			if (enumByTag_length > 0 && !original_material_types.size()) {
				for (int i = 0; i < enumByTag_length; i++)
					original_material_types.push_back(enumByTag_array[i]);
			}		

			if (Vars::misc_shoot_throught_walls.isOn) {
				if (!material_types_was_edited) {

			enumByTag->setItemAtIndex(1, enumByTag_array[6]);
			enumByTag->setItemAtIndex(2, enumByTag_array[8]);

			enumByTag->setItemAtIndex(11, enumByTag_array[9]);
			enumByTag->setItemAtIndex(12, enumByTag_array[10]);

			enumByTag->setItemAtIndex(9, enumByTag_array[0]);
			enumByTag->setItemAtIndex(10, enumByTag_array[0]);

/*
					bool resolve_loop = false;
					for (int i = 0; i < enumByTag_length; i++) {
						monoString *current_material_type_string = enumByTag_array[i];
						if (!current_material_type_string)
							continue;

						char material_name[32];
						bzero(material_name, sizeof(material_name));

						current_material_type_string->getStringToBufferWithLength(material_name, 31);

						if (strstr(material_name, "/Unknown"))
							continue;

						if (strstr(material_name, "/Character"))
							continue;

						if (!smoke_material_string) {
							if (strstr(material_name, "/Glass"))
								smoke_material_string = current_material_type_string;
							resolve_loop = true;
						}

						if (!resolve_loop)
							enumByTag->setItemAtIndex(i, smoke_material_string);
					}

					if (!resolve_loop)
						material_types_was_edited = true;
						*/
					material_types_was_edited = true;
				}
			} else {
				if (material_types_was_edited) {
					for (int i = 0; i < enumByTag_length; i++) {
						enumByTag->setItemAtIndex(i, original_material_types[i]);
					}

					material_types_was_edited = false;
				}
			}
		}

	}


	if (!Vars::aimbot.isOn)
		return;

	if (Vars::aimbot_show_fov.isOn)
		ImGui::GetBackgroundDrawList()->AddCircle(ImVec2(screen_center.x, screen_center.y), Vars::aimbot_fov.value, ImColor(255, 255, 255, 255), 100, 1);

	if (!local_entity_data.aimingData || !local_entity_data.playerInputs)
		return;

	bool aim_flag = !(Vars::aimbot_scoping_check.isOn || Vars::aimbot_shooting_check.isOn);
	if (Vars::aimbot_scoping_check.isOn) {
		if (local_entity_data.currentGunWeapon) {
			uint64_t weapon_aiming_mode = memory->read<uint64_t>(local_entity_data.currentGunWeapon + Offsets::GunController_aimingMode);

			int aiming_mode = memory->read<int>(weapon_aiming_mode + 0x10);
			if (aiming_mode != 2) //NotAiming
				aim_flag = true;
		}
	}

	if (Vars::aimbot_shooting_check.isOn && !aim_flag) {
		aim_flag = memory->read<bool>(local_entity_data.playerInputs + Offsets::PlayerInputs_isToFire);
	}

	if (!aim_flag)
		return;

	EntityDataList::EntityData closest_aim_target = {};
	float closest_aim_target_distance = 999999.f;
	std::vector<EntityDataList::EntityData> &entity_data_list = entity_data_list_module->getEntityDataList();
	for (auto current_entity_data : entity_data_list) {

		if (Vars::aimbot_untouchable_check.isOn) {
			if (current_entity_data.untouchable)
				continue;
		}

		if (Vars::aimbot_visibility_check.isOn) {
			if (!current_entity_data.visible)
				continue;
		}

		if (!current_entity_data.on_screen)
			continue;

		ImVec2 aimbot_bone_screen = *(&_ Head + Vars::aimbot_bone.selectedIndex);
		if (!IsOnScreen((&_ Head + Vars::aimbot_bone.selectedIndex)))
			continue;

		float distanceFromCenter = Vector2::Distance(screen_center, Vector2(aimbot_bone_screen.x, aimbot_bone_screen.y));
		if (distanceFromCenter < closest_aim_target_distance && distanceFromCenter <= Vars::aimbot_fov.value) {
			closest_aim_target_distance = distanceFromCenter;
			memcpy((void *)&closest_aim_target, (void *)&current_entity_data, sizeof(EntityDataList::EntityData));
		}
	}

	if (closest_aim_target.object) {

		ImVec2 aimbot_bone_screen = *(&closest_aim_target.screen_positions.Head + Vars::aimbot_bone.selectedIndex);

		if (Vars::aimbot_draw_line_to_target.isOn)
			ImGui::GetForegroundDrawList()->AddLine(ImVec2(screen_center.x, screen_center.y), aimbot_bone_screen, ImColor(255, 255, 255), 0.75f);

		Vector3 aim_bone_position = *(&closest_aim_target.positions.Head + Vars::aimbot_bone.selectedIndex);
		Vector3 aimbot_rotation = Quaternion::ToEuler(Quaternion::LookRotation(aim_bone_position - local_entity_data.positions.Head));

		float currentPitch = local_entity_data.rotation.x;
		float currentYaw = local_entity_data.rotation.y;

		float smooth = Vars::aimbot_smooth.value;

		if (Vars::aimbot_psilent.isOn) {
			if (local_entity_data.currentGunWeapon) {			
				uint64_t recoil_control = memory->read<uint64_t>(local_entity_data.currentGunWeapon + Offsets::GunController_recoilControl);
				if (recoil_control) {
					
					/*
					uint64_t recoil_parameters = memory->read<uint64_t>(recoil_control + Offsets::RecoilControl_recoilParameters);
					if (recoil_parameters) {
						//memory->write<float>(recoil_parameters + 0x4C, 99999999.f);
						memory->write<float>(recoil_parameters + 0x10, 0.f);
						memory->write<float>(recoil_parameters + 0x14, 0.f);
					}
					*/
					

					//Vector2 oldDeviation = memory->read<Vector2>(recoil_control + Offsets::RecoilControl_previousActualPoint);
					Vector2 newRecoilDeviation;
					newRecoilDeviation.x = (currentPitch - Angles::LerpAngle(currentPitch, aimbot_rotation.x, 1.f)) * 3.f; 
					newRecoilDeviation.y = (Angles::LerpAngle(currentYaw, aimbot_rotation.y, 1.f) - currentYaw) * 3.f;
					
					/*
					Vector3 silent_direction = aimbot_rotation - local_entity_data.positions.Head;
					silent_direction.normalized();

					float desiredYaw   = std::atan2(silent_direction.x, silent_direction.z) * Rad2Deg;
					float desiredPitch = -std::atan2(
						silent_direction.y, 
						std::sqrt(silent_direction.x * silent_direction.x + silent_direction.z * silent_direction.z)
					) * Rad2Deg;

					float currentPitch = local_entity_data.rotation.x;
					float currentYaw   = local_entity_data.rotation.y;

					Vector2 newRecoilDeviation;
					newRecoilDeviation.x = currentPitch - desiredPitch; 
					newRecoilDeviation.y = desiredYaw   - currentYaw;
					*/

					memory->write<Vector2>(
						recoil_control + Offsets::RecoilControl_previousActualPoint, 
						newRecoilDeviation
					);

					Vector2 currentRelativeDispersion = memory->read<Vector2>(recoil_control + 0x30);
					currentRelativeDispersion.x += newRecoilDeviation.x;
					currentRelativeDispersion.y += newRecoilDeviation.y;

					memory->write<Vector2>(
						recoil_control + 0x30, 
						currentRelativeDispersion
					);

					//float approach_delta_dist = memory->read<float>(recoil_control + 0x2C);
					//memory->write<float>(recoil_control + 0x2C, 0.f); //approach
				}
				memory->write<int32_t>(local_entity_data.currentGunWeapon + 0x44, 2); //TPS

				memory->write<float>(local_entity_data.currentGunWeapon + Offsets::GunController_recoilMult, -0.00000001f); 
				memory->write<float>(local_entity_data.currentGunWeapon + Offsets::GunController_accuracyMult, 0.f);
				memory->write<float>(local_entity_data.currentGunWeapon + Offsets::GunController_accuracyAdditive, 0.f);
			}
		} else {
			if (local_entity_data.currentGunWeapon) {
				uint64_t recoil_control = memory->read<uint64_t>(local_entity_data.currentGunWeapon + Offsets::GunController_recoilControl);
				if (recoil_control && Vars::aimbot_recover_aimpunch.isOn) {
					Vector2 recoil_deviation = memory->read<Vector2>(recoil_control + Offsets::RecoilControl_previousActualPoint);
					aimbot_rotation.x += recoil_deviation.x;
					aimbot_rotation.y -= recoil_deviation.y;
				}


			}
			
			/*
			uint64_t recoil_data = memory->read<uint64_t>(local_entity_data.currentGunWeapon + Offsets::GunController_recoilData);
			if (recoil_data && Vars::aimbot_recover_aimpunch.isOn) {
				aimbot_rotation.x += memory->read<float>(recoil_data + Offsets::RecoilData_XDeviation);
				aimbot_rotation.y -= memory->read<float>(recoil_data + Offsets::RecoilData_YDeviation);
			}
			*/
			memory->write<float>(local_entity_data.aimingData + Offsets::AimingData_aimXAngles, Angles::LerpAngle(currentPitch, aimbot_rotation.x, smooth)); 
			memory->write<float>(local_entity_data.aimingData + Offsets::AimingData_aimYAngles + 0x4, Angles::LerpAngle(currentYaw, aimbot_rotation.y, smooth));
			memory->write<int32_t>(local_entity_data.currentGunWeapon + 0x44, 1); //FPS
		}
	}
}
