#include "ModulesManager.h"

#include "ModulesSharedData.h"
#include "Offsets.hpp"

ModulesManager::~ModulesManager() {

/*
    [Vars::logView log:[NSString stringWithFormat:@"getModule %p", getModule<EntityList>()]];
	delete getModule<Camera>();
	delete getModule<EntityList>();
	delete getModule<EntityDataList>();
	delete getModule<Visuals>();
*/

	for (auto module : all_modules) {
		module.reset();
	}
}

void ModulesManager::initModules() {
	this->registerModule<Camera>(UPDATABLE_MODULE); //main modules
	this->registerModule<EntityList>(UPDATABLE_MODULE);
	this->registerModule<EntityDataList>(UPDATABLE_MODULE);

	this->registerModule<Visuals>(UPDATABLE_MODULE); //user modules
	this->registerModule<Aimbot>(UPDATABLE_MODULE);
}

template<typename T>
void ModulesManager::registerModule(ModuleType module_type) {
	std::shared_ptr<T> new_module = std::shared_ptr<T>(new T());
	switch(module_type) {
		case UPDATABLE_MODULE:
			updatable_modules.push_back(new_module);
			break;
	}

	all_modules.push_back(new_module);
}

void ModulesManager::OnUpdate() {
	for (auto &module : updatable_modules) {
		module->OnUpdate();
	}
}

void ModulesManager::OnInit(void *shared_data) {
	for (auto &module : all_modules) {
		module->OnInit(shared_data);
	}
}