//
//  shrink.h
//  SmallShrink
//
//  Created by Richard Hughes on 19/10/2009.
//  Copyright 2009 Small Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface shrink : NSResponder {
	IBOutlet id source;
	IBOutlet id outputFolder;
	IBOutlet id outputFilename;
	IBOutlet id audioStreamId;
	IBOutlet id dvdTitleNumber;
	IBOutlet NSTextField *progressMessage;
	IBOutlet id progressIndicator;
	IBOutlet id dvdSize;
	IBOutlet id method;
	IBOutlet id requantize;
	IBOutlet id remux;
	IBOutlet id demux;
	IBOutlet id target;
	IBOutlet id tempFiles;
	IBOutlet NSTableView *tableView;
 	
}
- (IBAction) setDvdSource:(id)sender;
- (IBAction) setIso:(id)sender;
- (IBAction) doShrink:(id)sender;

- (int) doTask:(NSString *)command :(NSArray *)arguments;
- (NSString *) lsdvd:(NSString *)dvdpath;

NSMutableArray *dvdContents;

@end
