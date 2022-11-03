//
//  SceneAppDelegate.m
//  whatever
//
//  Created by user on 11/2/22.
//

#import "SceneAppDelegate.h"

@implementation SceneAppDelegate : NSObject
- (id)init {
    if (self = [super init]) {
        // allocate and initialize window and stuff here ..
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [window makeKeyAndOrderFront:self];
}

@end
