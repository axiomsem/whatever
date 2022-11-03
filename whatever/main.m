//
//  main.m
//  whatever
//
//  Created by user on 10/5/22.
//

#import <Cocoa/Cocoa.h>
#import "SceneAppDelegate.h"

#define NONIB 1

int main(int argc, const char * argv[]) {
#if NONIB
    NSApplication * application = [NSApplication sharedApplication];

    SceneAppDelegate * appDelegate = [[SceneAppDelegate alloc] init];
    
    
    
    [application setDelegate:appDelegate];
    [application run];

    return EXIT_SUCCESS;
#else
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
    }
    return NSApplicationMain(argc, argv);
#endif
}
