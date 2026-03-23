#pragma once

#include "Cheat.h"
#include <libjailbreak/info.h>
#include <libjailbreak/util.h>
#include <libjailbreak/primitives.h>

extern "C" {
    int get_proc_pid(const char *executableName);
}

HIKARI_ALL_OBF
task_t get_task_by_pid(pid_t pid)
{
    task_port_t psDefault;
    task_port_t psDefault_control;

    task_array_t tasks;
    mach_msg_type_number_t numTasks;
    kern_return_t kr;

   
    host_t self_host = mach_host_self();
    kr = processor_set_default(self_host, &psDefault);
    if (kr != KERN_SUCCESS)
    {
        fprintf(stderr, "Error in processor_set_default: %x\n", kr);
        return MACH_PORT_NULL;
    }

   
    kr = host_processor_set_priv(self_host, psDefault, &psDefault_control);
    if (kr != KERN_SUCCESS)
    {
        fprintf(stderr, "Error in host_processor_set_priv: %x\n", kr);
        return MACH_PORT_NULL;
    }

  
    kr = processor_set_tasks(psDefault_control, &tasks, &numTasks);
    if (kr != KERN_SUCCESS) {
        fprintf(stderr, "Error in processor_set_tasks: %x\n", kr);
        return MACH_PORT_NULL;
    }

  
    for (int i = 0; i < numTasks; i++)
    {
        int task_pid;
        kr = pid_for_task(tasks[i], &task_pid);
        if (kr != KERN_SUCCESS) {
            continue;
        }

        if (task_pid == pid) return tasks[i];
    }

    return MACH_PORT_NULL;
}

HIKARI_ALL_OBF
void get_extmod_struct_for_pid(int pid, struct vm_extmod_statistics *out) {
    
    mach_port_t task;
    task_for_pid(mach_task_self(), pid, &task);
    
    struct task_extmod_info info = {};
    mach_msg_type_number_t count = TASK_EXTMOD_INFO_COUNT;
    task_info(task, TASK_EXTMOD_INFO, (task_info_t)&info, &count);
    
    memcpy(out, &info.extmod_statistics, sizeof(struct vm_extmod_statistics));
}

HIKARI_ALL_OBF
uint32_t find_and_clear_extmod_struct_offset(int target_pid) {
    
    if (!gSystemInfo.kernelConstant.kernelProc)
        return 0;
    
    uint64_t proc = gSystemInfo.kernelConstant.kernelProc;
    while (proc) {
        uint32_t pid = kread32(proc + koffsetof(proc, pid));
        if (pid == target_pid)
            break;

        proc = kread_ptr(proc + koffsetof(proc, list_prev));
    }

    if (!proc)
        return 0;
    
    vm_extmod_statistics extmod_struct;
    get_extmod_struct_for_pid(target_pid, &extmod_struct);
    
    uint64_t target_proc = proc;
    uint64_t PAC_mask = get_pac_mask(target_proc);
    uint64_t target_task = (koffsetof(proc, task)) ? (kread64(target_proc + koffsetof(proc, task)) | PAC_mask) : (target_proc + ksizeof(proc));
    
    uint64_t *task_struct_buffer = (uint64_t *)malloc(0x300);
    kreadbuf(target_task + 0x400, task_struct_buffer, 0x300);
    
    uint32_t extmod_struct_offset = 0;
    void *pattern_substring = memmem(task_struct_buffer, 0x300, &extmod_struct, sizeof(extmod_struct));
    if (pattern_substring) {
        extmod_struct_offset = (uint32_t)((uint64_t)pattern_substring - (uint64_t)task_struct_buffer) + 0x400;

        vm_extmod_statistics empty_extmod_struct = {};
        kwritebuf(target_task + extmod_struct_offset, &empty_extmod_struct, sizeof(empty_extmod_struct));
    }
    free(task_struct_buffer);
    
    return extmod_struct_offset;
}

Cheat *cheat = new Cheat();

HIKARI_ALL_OBF
bool Cheat::tryLaunch(bool isUserLaunch) {
    if (initialized)
		delaunch();

    int s_pid = get_proc_pid("s");

    if (s_pid == -1) 
	   return false;
    
    mach_port_t s_task = MACH_PORT_NULL;
    if (isUserLaunch) {
        s_task = get_task_by_pid(s_pid);
        if (s_task == MACH_PORT_NULL) {
            kill(s_pid, SIGKILL);
            return false;
        }
    } else {
        if (task_for_pid(mach_task_self_, s_pid, &s_task) != KERN_SUCCESS) {
            kill(s_pid, SIGKILL);
            return false;
        }
    }

    memory->initWithTask(s_task);

    baseAddress = memory->getBaseAddressOf("UnityFramework");
    if (!baseAddress) {
		kill(s_pid, SIGKILL);
		return false;
    }

    if (!isUserLaunch) {
        //Kernel bypass
        uint32_t extmod = find_and_clear_extmod_struct_offset(s_pid);
        if (extmod == 0) {
		      kill(s_pid, SIGKILL);
		      return false;
        }
    }

    return true;
}

void Cheat::delaunch() {
   //NSLog(@"delaunch();");
   if (modulesSharedData) {
		delete modulesSharedData;
		modulesSharedData = NULL;
	}

	if (modulesManager) {
		delete modulesManager;
		modulesManager = NULL;
	}

	initialized = false;
}

void Cheat::initGUI(int _screen_w, int _screen_h, ImFont *_text_font) {
	if (initialized)
		delaunch();

	screen_w = _screen_w;
	screen_h = _screen_h;
	text_font = _text_font;

	modulesManager = new ModulesManager();
		modulesManager->initModules();

	modulesSharedData = new ModulesSharedData();
		modulesSharedData->modulesManager = modulesManager;
		modulesSharedData->baseAddress = baseAddress;
		modulesSharedData->screen_w = screen_w;
		modulesSharedData->screen_h = screen_h;
		modulesSharedData->text_font = text_font;

	modulesManager->OnInit((void *)modulesSharedData);

	initialized = true;
}

void Cheat::setScreenProperties(int _screen_w, int _screen_h) {
	screen_w = _screen_w;
	screen_h = _screen_h;

	if (modulesSharedData) {
		modulesSharedData->screen_w = screen_w;
		modulesSharedData->screen_h = screen_h;
	}
}

Cheat::~Cheat() {
	if (!initialized)
		return;

	delete modulesManager;
}

void Cheat::OnUpdate() {
    if (!initialized)
		return;

    if (memory->read<int>(baseAddress) != 0xFEEDFACF) {
		delaunch();
		return;
    }

    modulesManager->OnUpdate();   
}
