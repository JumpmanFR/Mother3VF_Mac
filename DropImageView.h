//
//  DropImageView.h
//  Programme d’installation du patch MOTHER 3 VF
//
//
//

#import <Cocoa/Cocoa.h>
#import "PatchController.h"

@interface DropImageView : NSImageView <NSDraggingDestination, NSPasteboardItemDataProvider> {

    BOOL highlight;
    IBOutlet PatchController *patchController;

}




@end
