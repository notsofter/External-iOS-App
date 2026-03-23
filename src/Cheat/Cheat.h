#pragma once

#include "ModulesManager.h"
#include "ModulesSharedData.h"

class Cheat {
private:
    ModulesManager *modulesManager;

	ImFont *text_font;
	bool initialized = false;
	int screen_w, screen_h;
	uint64_t baseAddress;

public:
	ModulesSharedData *modulesSharedData = NULL;

	bool tryLaunch(bool isUserLaunch);
	void delaunch();
   	void initGUI(int _screen_w, int _screen_h, ImFont *_text_font);
   	void setScreenProperties(int _screen_w, int _screen_h);
	~Cheat();

   void OnUpdate();
};

extern Cheat *cheat;
