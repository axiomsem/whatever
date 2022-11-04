//
//  SceneView.h
//  whatever
//
//  Created by user on 11/2/22.
//

#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum _SceneKeyFlags {
    SceneKeyFlagNone = 0,
    SceneKeyForward = 1 << 0,
    SceneKeyBackward = 1 << 1
} SceneKeyFlags;

@interface SceneView : MTKView

@property SceneKeyFlags keyFlags;

- (void)keyDown:(NSEvent *)theEvent;
-(id)initWithFrame:(NSRect)frame;
- (BOOL)acceptsFirstResponder;

@end

NS_ASSUME_NONNULL_END
