#pragma once

#include <vector>

#include "IUpdatable.h"
#include "EntityDataList.h"

class Aimbot : public IUpdatable {
public:
	virtual const char *getModuleName();
	virtual void OnInit(void *shared_data);
	virtual void OnUpdate();

private:
};