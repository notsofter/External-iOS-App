#pragma once

#include <vector>

#include "IUpdatable.h"
#include "EntityDataList.h"

class Visuals : public IUpdatable {
public:
	virtual const char *getModuleName();
	virtual void OnInit(void *shared_data);
	virtual void OnUpdate();

private:
	void DrawSkeleton(EntityDataList::EntityData &entity_data);
	void DrawDefaultBox(EntityDataList::EntityData &entity_data, float rounding = 0.f);
	void DrawRoundedBox(EntityDataList::EntityData &entity_data);
	void DrawWeaponName(EntityDataList::EntityData &entity_data);
	void DrawInfoBar(EntityDataList::EntityData &entity_data);
	void DrawLine(EntityDataList::EntityData &entity_data);
	void DrawOffscreen(EntityDataList::EntityData &entity_data);
	void DrawWatermark(EntityDataList::EntityData &entity_data);

	void DrawHitData(EntityDataList::EntityHitData &entity_hit_data);
	void DrawFootstep(EntityDataList::EntityFootstepData &entity_footstep_data);
};