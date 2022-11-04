//
//  SceneView.m
//  whatever
//
//  Created by user on 11/2/22.
//

#import "SceneView.h"

typedef bool _KeyBuffer[256];

@implementation SceneView
{
    _KeyBuffer _keys;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    if (self.delegate) {
        [self.delegate drawInMTKView:self];
    }
}

- (void)keyDown:(NSEvent *)theEvent
{
    [super keyDown:theEvent];
    
    for (size_t i = 0; i < theEvent.characters.length; ++i) {
        _keys[i] = true;
    }
    
    NSLog(@"onKeyDown Detected; %@", theEvent.characters);
}

- (void)keyUp:(NSEvent *)theEvent
{
    [super keyUp:theEvent];
    
    for (size_t i = 0; i < theEvent.characters.length; ++i) {
        _keys[i] = false;
    }
    
    NSLog(@"onKeyUp Detected; %@", theEvent.characters);
}

-(id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        memset(_keys, 0, sizeof(_keys));
    }
    return self;
}

- (bool)hasCharKeyDown:(char)character
{
    return _keys[(size_t)character];
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
