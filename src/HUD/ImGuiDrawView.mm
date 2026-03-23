#import "ImGuiDrawView.h"
#import <sys/utsname.h>

@implementation ImGuiDrawView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _device = MTLCreateSystemDefaultDevice();
        _commandQueue = [_device newCommandQueue];

        if (!_device) abort();

        IMGUI_CHECKVERSION();
        ImGui::CreateContext();
        ImGuiIO& io = ImGui::GetIO(); (void)io;
        
        ImGui::StyleColorsDark();

        ImFontConfig font_config;
        font_config.OversampleH = 1;
        font_config.OversampleV = 1;
        font_config.PixelSnapH = 1;

        static const ImWchar ranges[] =
        {
            0x0020, 0x00FF,
            0x0400, 0x044F,
            0
        };
        
        ImFont *text_font = io.Fonts->AddFontFromFileTTF("/System/Library/Fonts/CoreUI/TrebuchetMSBold.ttf", 16.f, &font_config, ranges);

        ImGui_ImplMetal_Init(_device);

        MTKView *mtkView = [[MTKView alloc] initWithFrame:self.bounds];
        mtkView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        mtkView.device = _device;
        mtkView.delegate = self;
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
        mtkView.backgroundColor = [UIColor clearColor];
        mtkView.clipsToBounds = YES;
        [mtkView setUserInteractionEnabled:NO];
        [self addSubview:mtkView];

        cheat->initGUI(mtkView.frame.size.width, mtkView.frame.size.height, text_font);
    }
    return self;
}

- (void)drawInMTKView:(MTKView *)view
{
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;

    static float framebufferScale = 0;
    static bool io_initialized = false;
    if (!io_initialized) {
        utsname systemInfo;
        uname(&systemInfo);
        if (!strcmp(systemInfo.machine, "iPhone9,2") || !strcmp(systemInfo.machine, "iPhone9,4") || !strcmp(systemInfo.machine, "iPhone10,2") || !strcmp(systemInfo.machine, "iPhone10,5")) {
            // iPhone mini series
            framebufferScale = 2.61f;
        } else if (!strcmp(systemInfo.machine, "iPhone14,4") || !strcmp(systemInfo.machine, "iPhone13,1")) {
            // iPhone XR
            framebufferScale = 2.88f;
        } else {
            // Use default scale (from UIScreen)
            framebufferScale = view.window.screen.nativeScale ?: UIScreen.mainScreen.nativeScale;
        }

        io_initialized = true;
    }

    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = 1 / float(view.preferredFramesPerSecond ?: 60);

    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor != nil)
    {
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder pushDebugGroup:@"ImGui Jane"];

        ImGui_ImplMetal_NewFrame(renderPassDescriptor);
        ImGui::NewFrame();

        [Vars::qwerty setSecureTextEntry:Vars::overlay_switch.isOn];

        cheat->OnUpdate();

        ImGui::Render();
        ImDrawData *draw_data = ImGui::GetDrawData();
        ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderEncoder);

        [renderEncoder popDebugGroup];
        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];
        [commandBuffer commit];
    }
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}

@end
