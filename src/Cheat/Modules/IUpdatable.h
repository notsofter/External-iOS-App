#pragma once

#include "IModule.h"

class IUpdatable : public virtual IModule {
public:
	virtual void OnUpdate() = 0;
};