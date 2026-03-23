#include "Menu/ToggleSwitch.h"
#include "Menu/SegmentedControl.h"
#include "Menu/Slider.h"
//#include "UI/LogView.h"

#define timer(sec) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, sec * NSEC_PER_SEC), dispatch_get_main_queue(), ^

// Hikari Obfuscator defines
#define HIKARI_BOGUS_CONTROL_FLOW __attribute((__annotate__(("bcf"))))
#define HIKARI_CONTROL_FLOW __attribute((__annotate__(("fla"))))
#define HIKARI_STRING_ENCRYPTION __attribute((__annotate__(("strenc"))))
#define HIKARI_BRANCHING __attribute((__annotate__(("indibr"))))
#define HIKARI_FUNCTION_WRAPPER __attribute((__annotate__(("fw"))))
#define HIKARI_FUNCTION_CALL __attribute((__annotate__(("strenc")))) __attribute((__annotate__(("fco"))))
#define HIKARI_ALL_OBF __attribute((__annotate__(("strenc")))) __attribute((__annotate__(("fco")))) __attribute((__annotate__(("fw")))) __attribute((__annotate__(("fla")))) __attribute((__annotate__(("indibr"))))

namespace Vars {
    inline UITextField *qwerty;
    inline bool StateCheat = false;
    //inline LogView *logView;

    inline ToggleSwitch *overlay_switch;

    inline ToggleSwitch *aimbot;
        inline ToggleSwitch *aimbot_psilent;
        inline ToggleSwitch *aimbot_visibility_check;
        inline ToggleSwitch *aimbot_scoping_check;
        inline ToggleSwitch *aimbot_shooting_check;
        inline ToggleSwitch *aimbot_untouchable_check;
        inline ToggleSwitch *aimbot_recover_aimpunch;
        inline ToggleSwitch *aimbot_draw_line_to_target;
        inline ToggleSwitch *aimbot_draw_recoil_point;
        inline ToggleSwitch *aimbot_show_fov;
        inline SegmentedControl *aimbot_bone;
        inline Slider *aimbot_fov;
        inline Slider *aimbot_smooth;

    inline ToggleSwitch *visuals;
        inline ToggleSwitch *visuals_box;
        inline ToggleSwitch *visuals_line;
        inline ToggleSwitch *visuals_skeleton;
        inline ToggleSwitch *visuals_infobar;
        inline ToggleSwitch *visuals_weaponname;
        inline ToggleSwitch *visuals_footsteps;
        inline ToggleSwitch *visuals_hitinfo;
        inline ToggleSwitch *visuals_offscreen;
        inline Slider *visuals_offscreen_radius;
        inline Slider *visuals_offscreen_size;

    inline ToggleSwitch *misc_no_recoil;
    inline ToggleSwitch *misc_increased_firerate;
    inline ToggleSwitch *misc_infinity_ammo;
    inline ToggleSwitch *misc_shoot_throught_walls;
}
