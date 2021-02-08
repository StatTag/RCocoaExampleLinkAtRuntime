//
//  ViewController.m
//  RCocoaExampleLinkAtRuntime
//
//  Created by Eric Whitley on 1/21/21.
//  Copyright © 2021 Eric Whitley. All rights reserved.
//

#import "ViewController.h"
#import <RCocoa/RCocoa.h>

@implementation ViewController

NSString* DefaultRLibraryDirectory = @"/Library/Frameworks/R.framework/Versions/";
NSString* RCurrentVersionDirecotryKey = @"Current";
NSURL* RCurrentVersionSymlink;

NSString* InitialRVersionPath = @"";
NSString* InitialRVersionNumber = @"";

NSString* CurrentRVersionNumber = @"";
NSString* CurrentRVersionPath = @"";
NSString* SampleRCommand = @"setNames(data.frame(\
matrix(c(1,2,3,4,5,6),nrow=3,ncol=2)),\
c(\"a\",\"b\"))";

NSString *RHome = @"";

NSString *RCocoaRHome = @"";
NSString *RCocoaRVersion = @"";

NSMutableDictionary* RSettingInfo;

 
- (void)viewDidLoad {
  [super viewDidLoad];
  
  RSettingInfo = [[NSMutableDictionary alloc] init];
  //get the initial R version so we can reset it when we leave (if possible)
  InitialRVersionPath = [self GetCurrentRVersionPath];
  InitialRVersionNumber = [self GetCurrentRVersionNumber];
  
  [RSettingInfo setObject:InitialRVersionPath forKey:@"Initial R Version Path"];
  [RSettingInfo setObject:InitialRVersionNumber forKey:@"Initial R Version Number"];

  [[self DateField] setStringValue:@""];
  
  //set r info
  [self PopulateRInformation];
  [[self RCommandInputText] setString:SampleRCommand];
}

-(void)viewDidAppear{
}

- (void)setRepresentedObject:(id)representedObject {
  [super setRepresentedObject:representedObject];
}

-(void)PopulateRInformation {
  RCurrentVersionSymlink = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", DefaultRLibraryDirectory, RCurrentVersionDirecotryKey]];

  CurrentRVersionPath = [self GetCurrentRVersionPath];
  CurrentRVersionNumber = [self GetCurrentRVersionNumber];

  [RSettingInfo setObject:[self GetRCocoaActiveRVersion] forKey:@"RCocoa R Version"];
  [RSettingInfo setObject:[self GetCurrentRVersionNumber] forKey:@"Current R Version Number"];
  [RSettingInfo setObject:[self GetCurrentRVersionPath] forKey:@"Current R Version Path"];


  [self PopulateRVersionPopUpButton];
  [[self RInfoTableView] reloadData];
}

-(NSString*)GetRCocoaActiveRVersion {
  NSString* rVersion = @"";
  RCEngine* Engine = [RCEngine GetInstance];
  if(Engine != nil){
    rVersion = [Engine ActiveRVersion];
  }
  return rVersion;
}

-(void)PopulateRVersionPopUpButton {
  NSDictionary<NSString*, NSString*>* RVersions = [self GetRVersions];
  [[self RVersionPopUpButton] removeAllItems];
  
  NSArray *sortedKeys = [[RVersions allKeys] sortedArrayUsingSelector: @selector(compare:)];
  int currentRVersionButtonIndex = 0;
  for (NSString *key in sortedKeys){
    [[self RVersionPopUpButton] addItemWithTitle:[RVersions objectForKey:key]];
    if([key isEqualToString:CurrentRVersionNumber]){
      [[self RVersionPopUpButton] selectItemAtIndex:currentRVersionButtonIndex];
    }
    currentRVersionButtonIndex++;
  }
}

- (IBAction)RVersionSelectionChanged:(id)sender {
  
  NSString* RequestedNewRVersion = [[[self RVersionPopUpButton] selectedItem] title];
  NSURL* NewRVersionURL = [NSURL fileURLWithPath:RequestedNewRVersion];
  NSError* error;
  if(NewRVersionURL != nil){
    
    //we're doing this the same way RSwitch does-ish. They use STPrivilegedTask, but we're going to just use the file manager
    //NOTE: this will NOT work if you sandbox. You can't manipulate paths like this.
    //https://github.com/hrbrmstr/RSwitch/blob/master/RSwitch/Swift/HandleRSwitch.swift
    //more discussion at https://rud.is/rswitch/guide/

    //we have to delete the "current" version symlink
    BOOL removedCurrentVersionSymLink = [[NSFileManager defaultManager] removeItemAtURL:RCurrentVersionSymlink error:&error];
    if(removedCurrentVersionSymLink){
      NSLog(@"Deleted R 'Current' symlink at %@", [RCurrentVersionSymlink path]);
    } else {
      NSLog(@"Error deleting R 'Current'. %@", [error localizedDescription]);
    }

    //then provide a new one
    BOOL UpdatedRSymlink = [[NSFileManager defaultManager] createSymbolicLinkAtURL:RCurrentVersionSymlink withDestinationURL:NewRVersionURL error:&error];
    if(UpdatedRSymlink){
      NSLog(@"Updated R path to %@", RequestedNewRVersion);
    } else {
      NSLog(@"Error updating R path. %@", [error localizedDescription]);
    }
    
  }
  [self PopulateRInformation];

}

- (IBAction)SubmitRCommand:(id)sender {
  NSString *RCommand = [_RCommandInputText string];
  [_RCommandResponseText setString:@""];
  NSString* response = [self RunRCommand:RCommand];
  [_RCommandResponseText setString:response];
  
  NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
  [[self DateField] setStringValue: [NSString stringWithFormat:@"Updated: %@", [dateFormatter stringFromDate:[NSDate date]]]];
}

-(NSString*)RunRCommand:(NSString*)command {
  NSString* resultString;
  NSMutableArray<NSString*>* resultArray = [[NSMutableArray alloc] init];

  //from: https://github.com/StatTag/RCocoaExample/blob/master/RCocoaExample/main.m#L12
  @autoreleasepool {
    RCEngine* Engine = [RCEngine GetInstance];
    if(Engine != nil){
        RCSymbolicExpression* result = [Engine Evaluate:command];
        if ([result IsFactor]) {
          NSLog(@"IsFactor");
        }
        else if ([result IsFunction]) {
          NSLog(@"IsFunction");
        }
        else if ([result IsDataFrame]) {
          RCDataFrame* data = [result AsDataFrame];
          int numCol = [data ColumnCount];
          for (int colIdx = 0; colIdx < numCol; colIdx++) {
            NSArray<NSString*>* column = [[data ElementAt:colIdx] AsCharacter];
            int numRow = [column count];
            for (int rowIdx = 0; rowIdx < numRow; rowIdx++) {
              [resultArray addObject:[NSString stringWithFormat:@"%@", [column objectAtIndex:rowIdx]]];
            }
          }
        }
        else if ([result IsMatrix]) {
          NSLog(@"Matrix");
        }
        else if ([result IsVector]) {
          NSLog(@"IsVector");
        }
        else if ([result IsList]) {
          NSLog(@"IsList");
        }
        else {
          //FIXME: this is bad - unknown type - alert our user
          [resultArray addObject:@"Unknown result type - unable to proceed"];
        }
        resultString = [[resultArray valueForKey:@"description"] componentsJoinedByString:@"\r"];
    }
    else {
      resultString = @"Unable to initialize R";
     }
  }
  return resultString;
}


//MARK: get R information

- (NSString*)GetCurrentRVersionPath {
  NSString* RCurrentVersionPath = [NSString stringWithFormat:@"%@%@", DefaultRLibraryDirectory, RCurrentVersionDirecotryKey];
  NSString* ActiveRPath = [[NSFileManager defaultManager] destinationOfSymbolicLinkAtPath:RCurrentVersionPath error:nil];
  return ActiveRPath;
}

- (NSString*)GetCurrentRVersionNumber {
  return [[self GetCurrentRVersionPath] lastPathComponent];
}

- (NSDictionary<NSString*, NSString*>*)GetRVersions {
  NSString *directoryPath = DefaultRLibraryDirectory;
  NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:nil];
  NSMutableDictionary<NSString*, NSString*> *RVersions = [[NSMutableDictionary<NSString*, NSString*> alloc] init];

  for(NSString *filePath in fileNames) {
    NSString* DirectoryName = [filePath lastPathComponent];
    if(![DirectoryName isEqualToString:RCurrentVersionDirecotryKey]){
      [RVersions setValue:[NSString stringWithFormat:@"%@%@", directoryPath, filePath] forKey:DirectoryName];
    }
  }
  
  return RVersions;
}

//MARK: TableView

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[RSettingInfo allKeys] count];
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *identifier = tableColumn.identifier;
    NSTableCellView *cell = [tableView makeViewWithIdentifier:identifier owner:self];

    if([[tableView identifier] isEqualToString:@"RInfoTableView"]){
      NSArray *keys = [[RSettingInfo allKeys] sortedArrayUsingSelector: @selector(compare:)];

      id key = [keys objectAtIndex:row];
      if ([[tableColumn identifier] isEqualToString:@"RSettingName"]) {
        [[cell textField] setStringValue: key];
      } else if ([[tableColumn identifier] isEqualToString:@"RSettingValue"]) {
        id anObject = [RSettingInfo objectForKey:key];
        [[cell textField] setStringValue: anObject];
      }
    }

    return cell;
}
@end
