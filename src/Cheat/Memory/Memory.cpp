#include "Memory.h"

Memory *memory = new Memory();

void Memory::initWithTask(task_t task) {
	m_task = task;
}

void Memory::readBuffer(uint64_t address, size_t size, void *buffer) {
	vm_size_t out_size;
	vm_read_overwrite(m_task, (vm_address_t)address, (vm_size_t)size, (vm_address_t)buffer, (vm_size_t *)&out_size);
}

void Memory::writeBuffer(uint64_t address, void *buffer, size_t size) {
	vm_write(m_task, (vm_address_t)address, (vm_address_t)buffer, (vm_size_t)size);
}

uint64_t Memory::getBaseAddressOf(const char *lib_name) {
	kern_return_t kr;

	struct task_dyld_info dyld_info;
	mach_msg_type_number_t dyld_count = TASK_DYLD_INFO_COUNT;

	if (task_info(m_task, TASK_DYLD_INFO, (task_info_t)&dyld_info, &dyld_count) == KERN_SUCCESS) {
		uint64_t all_image_info_addr = dyld_info.all_image_info_addr;
		struct dyld_all_image_infos all_image_infos = read<struct dyld_all_image_infos>(all_image_info_addr);

		dyld_image_info *all_image_infos_array = (dyld_image_info *)all_image_infos.infoArray;

		for (uint32_t j = 0; j < all_image_infos.infoArrayCount; j++) {
			struct dyld_image_info image_info = read<struct dyld_image_info>((uint64_t)all_image_infos_array);
			char image_name[1024];
			readBuffer((uint64_t)image_info.imageFilePath, 1024, &image_name);

			if (strstr(image_name, lib_name)) {
				return (uint64_t)image_info.imageLoadAddress;
			}

			all_image_infos_array++;
		}
	}

	return 0;
}

__attribute((__annotate__(("indibr"))))
__attribute((__annotate__(("strenc"))))
uint64_t Memory::findSymbolImport(struct mach_header64 *header_ptr, const char *symbol_name) {
	struct mach_header_64 header = this->read<struct mach_header_64>((uint64_t)header_ptr);

    struct segment_command_64 linkedit = {};
    struct symtab_command symtab = {};
    struct dysymtab_command dysymtab = {};

    uint64_t current_load_command_address = (uint64_t)header_ptr + sizeof(struct mach_header_64);
    for (int i = 0; i < header.ncmds; i++) {

    	struct load_command current_load_command = this->read<struct load_command>(current_load_command_address);

		if (current_load_command.cmd == LC_SEGMENT_64) {
			struct segment_command_64 segment = this->read<struct segment_command_64>(current_load_command_address);
			if (!strcmp(segment.segname, "__LINKEDIT"))
				linkedit = segment;

		} else if (current_load_command.cmd == LC_SYMTAB) {
			symtab = this->read<struct symtab_command>(current_load_command_address);
		} else if (current_load_command.cmd == LC_DYSYMTAB) {
			dysymtab = this->read<struct dysymtab_command>(current_load_command_address);
		}

		current_load_command_address += current_load_command.cmdsize;
    }

    uint64_t linkedit_base = (uint64_t)header_ptr + linkedit.vmaddr - linkedit.fileoff;
    uint64_t symbol_tab_ptr = (uint64_t)(linkedit_base + symtab.symoff);
    uint64_t strtab_ptr = (uint64_t)(linkedit_base + symtab.stroff);
    uint64_t indirect_symtab_ptr = (uint64_t)(linkedit_base + dysymtab.indirectsymoff);

    current_load_command_address = (uint64_t)header_ptr + sizeof(struct mach_header_64);
    for (int i = 0; i < header.ncmds; i++) {

    	struct load_command current_load_command = this->read<struct load_command>(current_load_command_address);

		if (current_load_command.cmd == LC_SEGMENT_64) {
			struct segment_command_64 segment = this->read<struct segment_command_64>(current_load_command_address);
			if (!strcmp(segment.segname, "__DATA")) {

				uint64_t first_section_address = current_load_command_address + sizeof(struct segment_command_64);
				for (int k = 0; k < segment.nsects; k++) {
					struct section_64 current_section = this->read<struct section_64>(first_section_address + (sizeof(struct section_64) * k));
					if (strcmp(current_section.sectname, "__la_symbol_ptr"))
						continue;

                    uint64_t indirect_symbol_indices_ptr = indirect_symtab_ptr + (sizeof(uint32_t) * current_section.reserved1);
                    uint64_t indirect_symbol_bindings_ptr = (uint64_t)header_ptr + current_section.addr;

                    for (int j = 0; j < current_section.size / sizeof(uint64_t); j++) {
                    	uint32_t symtab_index = this->read<uint32_t>(indirect_symbol_indices_ptr + (sizeof(uint32_t) * j));
                    	if (symtab_index == INDIRECT_SYMBOL_ABS || symtab_index == INDIRECT_SYMBOL_LOCAL || symtab_index == (INDIRECT_SYMBOL_LOCAL | INDIRECT_SYMBOL_ABS))
                    		continue;

                    	uint32_t strtab_offset = this->read<struct nlist_64>(symbol_tab_ptr + (sizeof(struct nlist_64) * symtab_index)).n_un.n_strx;
                    	uint64_t symbol_name_ptr = strtab_ptr + strtab_offset;

                    	char symbol_name_buffer[24];
                    	this->readBuffer(symbol_name_ptr, 24, &symbol_name_buffer);
                    	symbol_name_buffer[23] = 0;

                    	if (!symbol_name_buffer[0] || !symbol_name_buffer[1])
                    		continue;

                    	if (strcmp(&symbol_name_buffer[1], symbol_name))
                    		continue;

                    	return indirect_symbol_bindings_ptr + (sizeof(uint64_t) * j);
                    }
				}
			}
		}

		current_load_command_address += current_load_command.cmdsize;
    }

    return 0;
}
