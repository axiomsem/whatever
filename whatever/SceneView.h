//
//  SceneView.h
//  whatever
//
//  Created by user on 11/2/22.
//

#import <MetalKit/MetalKit.h>
#import "Renderer.h"

NS_ASSUME_NONNULL_BEGIN

@interface SceneView : MTKView

- (void)keyDown:(NSEvent *)theEvent;
-(id)initWithFrame:(NSRect)frame;
- (BOOL)acceptsFirstResponder;

@end

NS_ASSUME_NONNULL_END
