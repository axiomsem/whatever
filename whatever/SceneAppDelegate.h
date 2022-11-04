//
//  SceneAppDelegate..h
//  whatever
//
//  Created by user on 11/2/22.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "Renderer.h"

@interface SceneViewController : NSViewController {
}

@property (atomic, retain) Renderer* renderer;
@end

@interface SceneWindow : NSWindow {
    
}
@end

@interface SceneAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate> {

}
@end
