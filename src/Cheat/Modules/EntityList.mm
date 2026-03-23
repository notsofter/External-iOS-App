#include "EntityList.h"

#include <Foundation/Foundation.h>

#include "../ModulesSharedData.h"

static ModulesSharedData *modulesSharedData = nullptr;

static uint64_t playerManagerMethodInfo_ptr = 0;
static uint64_t playerManagerObject_ptr = 0;

const char *EntityList::getModuleName() {
	return "EntityList";
}

HIKARI_ALL_OBF
void EntityList::OnInit(void *shared_data) {
	modulesSharedData = (ModulesSharedData *)shared_data;

	#ifdef M_DEBUG
		NSLog(@"[GC Log] Shared baseAddress: %x", modulesSharedData->baseAddress);
		NSLog(@"[GC Log] Main binary bytes: %x", memory->read<uint64_t>(modulesSharedData->baseAddress));
	#endif

	playerManagerMethodInfo_ptr = Offsets::PlayerManager_LazySingleton_MethodInfo + modulesSharedData->baseAddress;
	playerManagerObject_ptr = 0;
}

HIKARI_BRANCHING
void EntityList::OnUpdate() {

	entity_list.clear();

		if (!playerManagerObject_ptr) {
			uint64_t playerManagerMethodInfo = memory->read<uint64_t>(playerManagerMethodInfo_ptr);
			if (!(playerManagerMethodInfo >> 32))
				return;

			uint64_t playerManagerMethodInfo_class = memory->read<uint64_t>(playerManagerMethodInfo + Offsets::MethodInfo_class);
			if (!playerManagerMethodInfo_class)
			return;

		playerManagerObject_ptr = memory->read<uint64_t>(playerManagerMethodInfo_class + Offsets::Il2CppClass_staticFields);
	}

	uint64_t playerManagerObject = memory->read<uint64_t>(playerManagerObject_ptr); //reading first static field(instance)
	if (!playerManagerObject) {
		//ImGui::GetForegroundDrawList()->AddText(ImVec2(15, 15), ImColor(255, 0, 0, 255), "no PM!");
		return;
	}

	local_entity = memory->read<uint64_t>(playerManagerObject + Offsets::PlayerManager_localPlayerController);

	monoDictionary<int, uint64_t> *entity_dictionary = memory->read<monoDictionary<int, uint64_t> *>(playerManagerObject + Offsets::PlayerManager_playerControllerDictionary);
	if (!entity_dictionary)
		return;

	int entries_length = entity_dictionary->getLength();
	monoDictionary<int, uint64_t>::Entry entity_entries[entries_length];
	entity_dictionary->getEntriesToBufferWithLength(entity_entries, entries_length);

	for(int i = 0; i < entries_length; i++) {
		uint64_t current_entity = entity_entries[i].value;
		if (!current_entity)
			continue;

		entity_list.push_back(current_entity);
	}
}

uint64_t EntityList::getLocalEntity() {
	return local_entity;
}

std::vector<uint64_t> &EntityList::getEntityList() {
	return entity_list;
}
