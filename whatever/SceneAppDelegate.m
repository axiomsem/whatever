//
//  SceneAppDelegate.m
//  whatever
//
//  Created by user on 11/2/22.
//

#import "SceneAppDelegate.h"
#import "GameViewController.h"

@implementation SceneAppDelegate
{

}

- (id)init {
    if (self = [super init]) {
        NSRect e = [[NSScreen mainScreen] frame];
        
        float szX = 640.0f;
        float szY = 480.0f;
        
        float halfW = e.size.width / 2.0f;
        float halfH = e.size.height / 2.0f;
        
        NSRect frame = NSMakeRect(halfW - szX / 2, halfH - szY / 2, szX, szY);
        
        window  = [[NSWindow alloc]
                            initWithContentRect:frame
                            styleMask:NSBorderlessWindowMask
                            backing:NSBackingStoreBuffered
                            defer:NO];
        
        [window setBackgroundColor:[NSColor blueColor]];
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [window makeKeyAndOrderFront:self];
}

@end
