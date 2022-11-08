//
//  SceneAppDelegate.m
//  whatever
//
//  Created by user on 11/2/22.
//

#import "SceneAppDelegate.h"
#import "Renderer.h"
#import "SceneView.h"

static NSRect get_frame()
{
    NSRect e = [[NSScreen mainScreen] frame];
    
    float szX = 1366.0f;
    float szY = 768.0f;
    
    float halfW = e.size.width / 2.0f;
    float halfH = e.size.height / 2.0f;
    
    NSRect frame = NSMakeRect(halfW - szX / 2, halfH - szY / 2, szX, szY);
    
    return frame;
}

@implementation SceneWindow
{
}

- (id) initWithContentRect: (NSRect) contentRect
                 styleMask: (NSWindowStyleMask) aStyle
                   backing: (NSBackingStoreType) bufferingType
                     defer: (BOOL) flag
{
    if ((self = [super initWithContentRect: contentRect
                                 styleMask: aStyle
                                   backing: bufferingType
                                     defer: flag]) == nil) { return nil; }

    [super setMovableByWindowBackground:YES];
    [super setLevel:NSNormalWindowLevel];
    [super setHasShadow:YES];

    return self;
}
    
- (BOOL) canBecomeKeyWindow
{
    return YES;
}
@end

@implementation SceneViewController
{
    Renderer* _renderer;
    
    SceneView* _sceneView;
}

- (void)viewDidLoad {
    
    NSRect frame = get_frame();
    
    _sceneView = [[SceneView alloc] initWithFrame:frame];
    
    self.view = _sceneView;
    
    [super viewDidLoad];
    
    _sceneView.device = MTLCreateSystemDefaultDevice();

    if(!_sceneView.device)  {
        NSLog(@"Metal is not supported on this device");
        self.view = [[NSView alloc] initWithFrame:frame];
        return;
    }
    
    _renderer = [[Renderer alloc] initWithMetalKitView:_sceneView];

    [_renderer mtkView:_sceneView drawableSizeWillChange:_sceneView.bounds.size];

    _sceneView.delegate = _renderer;
    
    self.view = _sceneView;
    self.renderer = _renderer;
}

@end

@implementation SceneAppDelegate 
{
    NSWindow* _window;
    SceneViewController* _viewController;
}

- (id)init {
    if (self = [super init]) {
        // need window title for it to support key events
        _window  = [[NSWindow alloc]
                    initWithContentRect:get_frame()
                    styleMask:NSWindowStyleMaskTitled
                    backing:NSBackingStoreBuffered
                    defer:NO];
        
        [_window setTitle:@"Whatever Renderer"];
    
        _viewController = [[SceneViewController alloc] init];
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [_viewController viewDidLoad];
    [_window setContentViewController:_viewController];
    [_window makeKeyAndOrderFront:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
}

@end
