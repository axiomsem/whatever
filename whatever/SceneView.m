//
//  SceneView.m
//  whatever
//
//  Created by user on 11/2/22.
//

#import "SceneView.h"

@implementation SceneView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)keyDown:(NSEvent *)theEvent
{
    [super keyDown:theEvent];
    
    NSLog(@"onKeyDown Detected; Merry Christmas, by the way.");
}

-(id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (BOOL)becomeFirstResponder
{
    return YES;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

@end
