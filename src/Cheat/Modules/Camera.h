#pragma once

#include <vector>

#include "IUpdatable.h"
#include <imgui/imgui.h>
#include "../Structs/Vector3.hpp"

class Camera : public IUpdatable {
public:
	virtual const char *getModuleName();
	virtual void OnInit(void *shared_data);
	virtual void OnUpdate();

	bool WorldToScreen(Vector3 position, ImVec2 *out);
};
