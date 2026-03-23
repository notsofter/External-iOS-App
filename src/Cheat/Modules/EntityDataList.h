#pragma once

#include <vector>
#include <thread>
#include <cmath>
#include <ctime>

#include "IUpdatable.h"
#include "imgui/imgui.h"
#include "../Structs/Vector3.hpp"
#include "../Structs/Vector2.hpp"

class EntityDataList : public IUpdatable {
public:
	struct EntityData {
		uint64_t object;
		uint64_t photonPlayer;
		uint64_t photonView;
		uint64_t aimingData;
		uint64_t playerInputs;
		uint64_t currentGunWeapon;
		Vector2 rotation;
		char entityName[17];
		char weaponName[17];
		float speed;
		float distance;
		int team;
		int health;
		bool untouchable;
		bool on_screen;
		bool visible;

		struct {
			Vector3 Root;
			Vector3 Head;
			Vector3 Neck;
			Vector3 Spine1;
			Vector3 Spine2;
			Vector3 Spine3;
			Vector3 LeftShoulder;
			Vector3 LeftUpperarm;
			Vector3 LeftForearm;
			Vector3 LeftHand;
			Vector3 RightShoulder;
			Vector3 RightUpperarm;
			Vector3 RightForearm;
			Vector3 RightHand;
			Vector3 Hip;
			Vector3 LeftUpLeg;
			Vector3 LeftLeg;
			Vector3 LeftFoot;
			Vector3 LeftToeBase;
			Vector3 RightUpLeg;
			Vector3 RightLeg;
			Vector3 RightFoot;
			Vector3 RightToeBase;
		} positions;

		struct {
			ImVec2 Root;
			ImVec2 Head;
			ImVec2 Neck;
			ImVec2 Spine1;
			ImVec2 Spine2;
			ImVec2 Spine3;
			ImVec2 LeftShoulder;
			ImVec2 LeftUpperarm;
			ImVec2 LeftForearm;
			ImVec2 LeftHand;
			ImVec2 RightShoulder;
			ImVec2 RightUpperarm;
			ImVec2 RightForearm;
			ImVec2 RightHand;
			ImVec2 Hip;
			ImVec2 LeftUpLeg;
			ImVec2 LeftLeg;
			ImVec2 LeftFoot;
			ImVec2 LeftToeBase;
			ImVec2 RightUpLeg;
			ImVec2 RightLeg;
			ImVec2 RightFoot;
			ImVec2 RightToeBase;

			ImVec2 RootTop;
			ImVec2 HeadTop;
		} screen_positions;

	};

	struct EntityHitData {
		uint64_t object;
		uint64_t victim_entity;
		Vector3 position;
		ImVec2 screen;
		ImVec2 screen_offset;
		ImVec2 direction;
		float speed;
		float acceleration;
		int damage;
		int ticks_left;
		int ticks_to_clean;
		bool on_screen;
		static const int max_ticks = 45;
	};

	struct EntityHitDataHandled {
		uint64_t object;
		bool updated;
	};

	struct EntityFootstepData {
		uint64_t object;
		Vector3 position;
		int ticks_left;
		static const int max_ticks = 50;
		static constexpr float min_radius = 0.3f;
		static constexpr float max_radius = 0.9f;
	};

private:
	EntityData local_entity_data;
	std::vector<EntityData> entity_data_list;
	std::vector<EntityHitDataHandled> handled_entity_hit_data_list;
	std::vector<EntityHitData> entity_hit_data_list;
	std::vector<EntityFootstepData> entity_footstep_data_list;


public:
	virtual const char *getModuleName();
	virtual void OnInit(void *shared_data);
	virtual void OnUpdate();
	void InternalUpdate();

	void HandleGunObject(uint64_t gun_object);
	void HandleHitData(uint64_t victim_entity, uint64_t hit_data);

	void HandleFootstep(uint64_t entity, Vector3 footstep_position);

	EntityData &getLocalEntityData();
	std::vector<EntityData> &getEntityDataList();
	std::vector<EntityHitData> &getEntityHitDataList();
	std::vector<EntityFootstepData> &getEntityFootstepDataList();
};