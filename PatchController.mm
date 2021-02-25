#import "PatchController.h"
#include "libups.hpp"
#include <dlfcn.h>

@implementation PatchController


- (void)awakeFromNib {
    [super viewDidLoad];
    [chkMakeBackup setKeyEquivalent:@"g"];
}

- (IBAction)btnApply:(id)sender {
  
    NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *romPath = [txtRomPath stringValue]; //Path for the ROM, specified in the textfield
	NSString *backupPath = [romPath stringByAppendingString:@".original"]; //A file that will be created
    
    if ([romPath length] == 0) { //User hasn’t specified the ROM path
        NSRunAlertPanel(@"Échec de l’installation",@"Vous n’avez pas spécifié l’emplacement de votre ROM japonaise !",@"OK",nil,nil);
        return;
    }

    NSString *appPath = NSBundle.mainBundle.bundlePath;
    appPath = [self resolveTranslocatedPath: appPath];
    appPath = [appPath stringByDeletingLastPathComponent];
    
    NSString *patchPath = [appPath stringByAppendingString:@"/mother3vf.ups"]; //Looking for the patch file at the same location as the app
        
    if(![fileManager fileExistsAtPath:patchPath]) { //If the patch file is not find at this location...
        NSRange lastSlash = [romPath rangeOfString:@"/" options:NSBackwardsSearch];
        NSString *romFolder = [romPath substringToIndex:lastSlash.location];
        patchPath = [romFolder stringByAppendingString:@"/mother3vf.ups"]; //Alternate location is at the same location as the ROM
    }

    while(![fileManager fileExistsAtPath:patchPath]) { //If it still can’t find the patch file...
        NSInteger answer = NSRunAlertPanel(@"Programme d’installation du patch",@"Le fichier de patch (mother3vf.ups) est introuvable. Il devrait faire partie de l’archive Mother3VF que vous avez téléchargée.\nVoulez-vous spécifier l’emplacement de votre fichier de patch ?",@"Oui",@"Non",nil);

        if (answer == NSAlertDefaultReturn) { //Ask for its location
            NSOpenPanel *panel = [NSOpenPanel openPanel];
            NSInteger clicked = [panel runModal];
            if (clicked == NSFileHandlingPanelOKButton) { //User has selected a location
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]]; //Wait for the file selection panel to close (workaround)
                NSURL*  theFile = [[panel URLs] objectAtIndex:0];
                patchPath = theFile.path;
                continue;
            }
        }
        NSRunAlertPanel(@"Échec de l’installation",@"Le fichier de patch (mother3vf.ups) n’a pas été trouvé.",@"OK",nil,nil);
        return;
    }

    if([fileManager fileExistsAtPath:romPath]) { //If the ROM file is available...
         UPS ups; //UPS Patcher
         int alreadyPatched = ups.isAlreadyPatched([romPath UTF8String], [patchPath UTF8String]);
         if (alreadyPatched) { //If the ROM has already been patched, offers to revert it (the UPS class will do it by default)
             int answer = NSRunAlertPanel(@"Programme d’installation du patch",@"Votre rom est déjà en français. Voulez-vous la remettre dans sa langue d’origine ?",@"Oui",@"Non",nil);
             if (answer != NSAlertDefaultReturn) { //If not, return; otherwise, just continue
                 NSRunAlertPanel(@"Échec de l’installation",@"L’opération a été annulée.",@"OK",nil,nil);
                 return;
             }
         }
        
        NSString *backupPathBase = backupPath;
        int counter = 1;
        while(![fileManager movePath:romPath toPath:backupPath handler:nil]) {
            counter++; //If a file named like the backup file already exists: let’s add digits
            backupPath = [backupPathBase stringByAppendingFormat:@"%d", counter];
        }
        [NSApp beginSheet:pnlPatching modalForWindow:wndPatcher modalDelegate:nil didEndSelector:nil contextInfo:nil]; //Make a sheet
        [barProgress setUsesThreadedAnimation:YES]; //Make sure it animates.
        [barProgress startAnimation:self];
        
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]]; //Wait before starting the operation (workaround because the animation wasn’t showing)

        bool result = ups.apply([backupPath UTF8String], [romPath UTF8String], [patchPath UTF8String]); //PATCHING THE ROM!
        
        [barProgress stopAnimation:self]; //Stop the animation
        [NSApp endSheet:pnlPatching]; //Tell the sheet we’re done.
        [pnlPatching orderOut:self]; //Hide the sheet.
        
        if(result == true) { //If success...
            if([chkMakeBackup state]==NSOffState){ //If user doesn’t want a backup, let’s just delete it
                [fileManager removeFileAtPath:backupPath handler:nil];
            }
            NSRunAlertPanel(@"Installation terminée !",@"La ROM a été patchée avec succès. Bon jeu !",@"Merci !",nil,nil);
            [self changeRomPath:@""];

        } else { //If failure...
            [fileManager removeFileAtPath:romPath handler:nil]; //Delete the aborted new rom file
            [fileManager movePath:backupPath toPath:romPath handler:nil]; //Move the backup file back as rom file
            NSRunAlertPanel(@"Échec de l’installation",[NSString stringWithCString:ups.error encoding:NSUTF8StringEncoding],@"OK",nil,nil); //Show the error returned by the UPS class
        }
    } else { //If the ROM file is not found...
        NSRunAlertPanel(@"Échec de l’installation",@"La ROM japonaise est introuvable au chemin d’accès indiqué.",@"OK",nil,nil);
    }
}

- (IBAction)btnBrowse:(id)sender {
    NSOpenPanel *fbox = [NSOpenPanel openPanel];
    [fbox beginSheetForDirectory:nil file:nil modalForWindow:wndPatcher modalDelegate:self didEndSelector:@selector(openPanelDidEnd: returnCode: contextInfo:) contextInfo:nil];
    //Delegate is who handles the window code.
}

- (IBAction)seekHelp:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://mother3vf.free.fr/index.php/comment-utiliser-le-patch-de-traduction/"]];
}

- (IBAction)seekHelpContact:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://mother3vf.free.fr/index.php/contact/"]];
}

- (IBAction)seekHelpOnDiscord:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://mother3vf.free.fr/discord"]];
}

- (void)changeRomPath:(NSString *)path {
    [txtRomPath setStringValue:path];
    [patchBtn setEnabled:[path length] != 0];
    [patchMenuItem setEnabled:[path length] != 0];
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo{
	if(returnCode == NSOKButton){
		NSString* selfile = [[panel filenames] objectAtIndex:0];
        [self changeRomPath:selfile];
	}
}

- (void)fileGotDropped:(id<NSDraggingInfo>) draggingInfo {
    NSURL *fileURL;
    fileURL = [NSURL URLFromPasteboard:[draggingInfo draggingPasteboard]];
    
    NSString *filePath = [fileURL path];
    
    [self changeRomPath:filePath];
}

- (NSString *)resolveTranslocatedPath: (NSString *)path
{
    // macOS < 10.12
    if (floor(NSAppKitVersionNumber) <= 1404) {
        return path;
    }

    void *handle = dlopen("/System/Library/Frameworks/Security.framework/Security", RTLD_LAZY);

    if (handle == NULL) {
        return path;
    }

    typedef Boolean (isTranslocatedFn)(CFURLRef, bool *, CFErrorRef * __nullable) ;
    Boolean (*mySecTranslocateIsTranslocatedURL)(CFURLRef path, bool *isTranslocated, CFErrorRef * __nullable error);
    mySecTranslocateIsTranslocatedURL = (isTranslocatedFn *) dlsym(handle, "SecTranslocateIsTranslocatedURL");

    typedef CFURLRef __nullable (originalPathFn)(CFURLRef, CFErrorRef * __nullable) ;
    CFURLRef __nullable (*mySecTranslocateCreateOriginalPathForURL)(CFURLRef translocatedPath, CFErrorRef * __nullable error);
    mySecTranslocateCreateOriginalPathForURL = (originalPathFn *) dlsym(handle, "SecTranslocateCreateOriginalPathForURL");

    if (mySecTranslocateIsTranslocatedURL == NULL || mySecTranslocateCreateOriginalPathForURL == NULL) {
        return path;
    }

    bool isTranslocated = false;
    CFURLRef pathURLRef = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)path, kCFURLPOSIXPathStyle, false);

    if (mySecTranslocateIsTranslocatedURL(pathURLRef, &isTranslocated, NULL))
    {
        if (isTranslocated)
        {
            CFURLRef resolvedURL = mySecTranslocateCreateOriginalPathForURL(pathURLRef, NULL);
            path = [(NSURL *)(resolvedURL) path];
        }
    }

    CFRelease(pathURLRef);

    return path;
}


@end
