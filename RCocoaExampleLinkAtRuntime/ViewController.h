//
//  ViewController.h
//  RCocoaExampleLinkAtRuntime
//
//  Created by Eric Whitley on 1/21/21.
//  Copyright © 2021 Eric Whitley. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTextField *DateField;
@property (weak) IBOutlet NSTextView *RCommandInputText;
@property (weak) IBOutlet NSTextView *RCommandResponseText;
@property (weak) IBOutlet NSPopUpButton *RVersionPopUpButton;
@property (weak) IBOutlet NSTableView *RInfoTableView;


@end

