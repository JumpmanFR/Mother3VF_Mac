//
//  DropImageView.m
//  Programme d’installation du patch MOTHER 3 VF
//
//
//

#import "DropImageView.h"
#import "PatchController.h"


@implementation DropImageView


- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    
    if ([sender draggingSourceOperationMask] & NSDragOperationCopy) {
        highlight = YES;
        
        [self setNeedsDisplay: YES];
        return NSDragOperationGeneric;
    }
    return NSDragOperationNone;
    
}

- (void)draggingExited:(id<NSDraggingInfo>)sender {
    
    highlight = NO;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    
    if (highlight) {
        [[NSColor grayColor]set];
        [NSBezierPath setDefaultLineWidth:5];
        [NSBezierPath strokeRect:dirtyRect];
    }
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
    
    highlight = NO;
    
    [self setNeedsDisplay:YES];
    
    return true;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    
    [patchController fileGotDropped:sender];
    
    return [super performDragOperation:sender];
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame; {
    
    NSRect ContentRect = self.window.frame;
    
    ContentRect.size = [[self image]size];
    
    return [NSWindow frameRectForContentRect:ContentRect styleMask:[window styleMask]];
};


- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    
    switch (context) {
        case NSDraggingContextOutsideApplication:
            return NSDragOperationCopy;
            
        case NSDraggingContextWithinApplication:
            
        default:
            return NSDragOperationCopy;
            break;
    }
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
    
    return YES;
}

- (void)pasteboard:(NSPasteboard *)pasteboard item:(NSPasteboardItem *)item provideDataForType:(NSString *)type {
    
}

@end
