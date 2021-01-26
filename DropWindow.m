//
//  DropWindow.m
//  Programme d’installation du patch MOTHER 3 VF
//
//
//

#import "DropWindow.h"
#import "PatchController.h"

@implementation DropWindow


NSString *kPrivateDragUTI = @"com.CCoding.DragNDrop";


- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    
    if ([sender draggingSourceOperationMask] & NSDragOperationCopy) {
        highlight = YES;
        
        [self setNeedsDisplay: YES];
        [sender enumerateDraggingItemsWithOptions:NSDraggingItemEnumerationConcurrent forView:self classes:[NSArray arrayWithObject:[NSPasteboardItem class]] searchOptions:nil usingBlock:^(NSDraggingItem *draggingItem, NSInteger idx, BOOL *stop) {
            
            /*if (![[[draggingItem item] types] containsObject:kPrivateDragUTI]) {
                *stop = YES;
            } else {
                
                [draggingItem setDraggingFrame:self.bounds contents:[[[draggingItem imageComponents] objectAtIndex:0] contents]];
            }*/
            
        }];
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
    
}


- (void)draggingExited:(id<NSDraggingInfo>)sender {
    
    highlight = NO;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    
    [super drawRect:dirtyRect];
    
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
    
    [patchController doStuff:sender];
    
    return YES;
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
    
    if ([type compare:NSPasteboardTypeTIFF] == NSOrderedSame) {
        [pasteboard setData:[[self image] TIFFRepresentation] forType:NSPasteboardTypeTIFF];
    } else if ([type compare:NSPasteboardTypePDF] == NSOrderedSame) {
        
        [pasteboard setData:[self dataWithEPSInsideRect:[self bounds]] forType:NSPasteboardTypePDF];
    }
}

@end
