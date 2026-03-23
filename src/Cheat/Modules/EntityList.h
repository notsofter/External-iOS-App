#pragma once

#include <vector>

#include "IUpdatable.h"

class EntityList : public IUpdatable {
private:
	uint64_t local_entity;
	std::vector<uint64_t> entity_list;

public:
	virtual const char *getModuleName();
	virtual void OnInit(void *shared_data);
	virtual void OnUpdate();

	uint64_t getLocalEntity();
	std::vector<uint64_t> &getEntityList();
};