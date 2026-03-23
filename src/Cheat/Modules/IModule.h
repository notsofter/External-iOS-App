#pragma once

class IModule {
public:
	virtual const char *getModuleName() = 0;
	virtual void OnInit(void *shared_data) = 0;
};