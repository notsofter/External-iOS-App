#pragma once

#include "ModulesManager.h"
#include "Memory/Memory.h"
#include "Offsets.hpp"
#include "Structs/UnityStructs.hpp"
#import <imgui/imgui.h>

class ModulesSharedData {
public:
	ModulesManager *modulesManager;
	uint64_t baseAddress;
	ImFont *text_font;
	int screen_w, screen_h;
};
