#pragma once

#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <mach-o/dyld_images.h>
#include <mach-o/nlist.h>
#include <string>

class Memory {

public:
	task_t m_task;
	void initWithTask(task_t task);

	template<typename T>
	T read(uint64_t address) {
		T buffer;
		vm_size_t out_size;
		if (vm_read_overwrite(m_task, (vm_address_t)address, (vm_size_t)sizeof(T), (vm_address_t)&buffer, (vm_size_t *)&out_size) != KERN_SUCCESS)
			return {};
		return buffer;
	}
	void readBuffer(uint64_t address, size_t size, void *buffer);

	template<typename T>
	void write(uint64_t address, T data) {
		vm_write(m_task, (vm_address_t)address, (vm_address_t)&data, (vm_size_t)sizeof(T));
	}
	void writeBuffer(uint64_t address, void *buffer, size_t size);

	uint64_t getBaseAddressOf(const char *lib_name);
	uint64_t findSymbolImport(struct mach_header64 *header_ptr, const char *symbol_name);
};

extern Memory *memory;
