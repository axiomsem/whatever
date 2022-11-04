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
    
    float szX = 640.0f;
    float szY = 480.0f;
    
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
    // etc.

    return self;
}
    
- (BOOL) canBecomeKeyWindow
{
    return YES;
}
@end

@implementation SceneAppDelegate 
{
    NSView* _view;
    
    SceneView* _sceneView;
    
    NSWindow* _window;
    
    Renderer* _renderer;
}

- (void)loadView {
    NSRect frame = get_frame();
    
    _sceneView = [[SceneView alloc] initWithFrame:frame];
    
    
#if 0
    _sceneView.device = MTLCreateSystemDefaultDevice();

    if(!_sceneView.device)
    {
        NSLog(@"Metal is not supported on this device");
        _view = [[NSView alloc] initWithFrame:frame];
        return;
    }

    _renderer = [[Renderer alloc] initWithMetalKitView:_sceneView];

    [_renderer mtkView:_sceneView drawableSizeWillChange:_sceneView.bounds.size];

    _sceneView.delegate = _renderer;
#endif
    
    _view = _sceneView;
}

- (id)init {
    if (self = [super init]) {
        [self loadView];
        
        _window  = [[NSWindow alloc]
                    initWithContentRect:get_frame()
                    styleMask:NSWindowStyleMaskTitled
                    backing:NSBackingStoreBuffered
                    defer:NO];
        
        [_window setTitle:@"this is a title"];
        //window.contentView = ;
        
        //[window setBackgroundColor:[NSColor blueColor]];
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [_window setContentView:_view];
    [_window makeKeyAndOrderFront:self];
}

@end
