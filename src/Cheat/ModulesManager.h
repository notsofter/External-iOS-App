#pragma once

#include <vector>
#include <mutex>
#include <shared_mutex>

#include "Modules/Camera.h"
#include "Modules/EntityList.h"
#include "Modules/EntityDataList.h"
#include "Modules/Visuals.h"
#include "Modules/Aimbot.h"

class ModulesManager {
private:
	enum ModuleType { UN_UPDATABLE_MODULE, UPDATABLE_MODULE };

	std::vector< std::shared_ptr<IModule> > all_modules;
	std::vector< std::shared_ptr<IUpdatable> > updatable_modules;

public:
	~ModulesManager();
	void registerModules();
	void initModules();

	template<typename T>
	void registerModule(ModuleType module_type);

	template <typename T>
	T *getModule() {
		for (auto module : all_modules) {
			if (auto typed_module = dynamic_cast<typename std::remove_pointer<T>::type*>(module.get())){
				return typed_module;
			}
		}
		return nullptr;
	};

	void OnUpdate();
	void OnInit(void *shared_data);
};