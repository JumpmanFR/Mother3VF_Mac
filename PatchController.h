#import <Cocoa/Cocoa.h>

/*@protocol MyViewDelegate<NSObject>
- (void)doStuff:(NSEvent *)event;
@end*/

@interface PatchController : NSViewController {
    IBOutlet id chkMakeBackup;
    IBOutlet id txtRomPath;
    IBOutlet id wndPatcher;
	IBOutlet id pnlPatching;
    IBOutlet id barProgress;
    IBOutlet id patchBtn;
    IBOutlet id patchMenuItem;
}
- (IBAction)btnApply:(id)sender;
- (IBAction)btnBrowse:(id)sender;
- (IBAction)seekHelp:(id)sender;
- (IBAction)seekHelpContact:(id)sender;
- (IBAction)seekHelpOnDiscord:(id)sender;
- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo; //Called automatically
- (void)fileGotDropped:(id<NSDraggingInfo>)event;

@end
