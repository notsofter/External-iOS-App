#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <imgui/imgui.h>
#import <imgui/imgui_internal.h>
#import <imgui/imgui_impl_metal.h>
#import "../Cheat/Cheat.h"

@interface ImGuiDrawView : UIView <MTKViewDelegate>
@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@end