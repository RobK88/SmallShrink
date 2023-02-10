//
//  shrink.m
//  SmallShrink
//
//  Created by Richard Hughes on 19/10/2009.
//  Copyright 2009 Small Software. All rights reserved.
//
//  Modifications created by Robert Kennedy
//  Copyright 2023 Robert Kennedy
//

#import "shrink.h"
#import "JSON.h"

#define NSMOVIEDIRECTORY 17

@implementation shrink

- (IBAction) setDvdSource:(id)sender
{
	
	NSOpenPanel *finder	= [NSOpenPanel openPanel];
    [finder setCanChooseDirectories: YES];
    [finder setCanChooseFiles: NO];
	//NSInteger r	= [finder runModalForTypes:nil];
    NSInteger r	= [finder runModal];
	if(r == NSCancelButton)  return;
	
	//NSString * tvarFilename = [finder filename];
    NSArray *urls = [finder URLs];
    NSString *tvarFullFilename = [[[(NSArray*)urls mutableCopy] firstObject] absoluteString];
    NSString *tvarFilename = [tvarFullFilename stringByReplacingOccurrencesOfString:@"file://localhost"
                                                          withString:@""];
	[source setStringValue:tvarFilename];
	
	[self lsdvd:tvarFilename];
	
	NSArray *path = [tvarFilename componentsSeparatedByString:@"/"];
	
	[outputFilename setStringValue:[path objectAtIndex:([path count]-1)]];
	

	
	
}


- (IBAction) setIso:(id)sender
{
	
	//	NSSavePanel *finder	= [NSSavePanel savePanel];
	//	[finder setAllowedFileTypes: [NSArray arrayWithObject:@"iso"]];
	//	[finder setExtensionHidden:NO];
	//	NSInteger r	= [finder runModalForDirectory:@"~" file:@"dvd"];
	
	NSOpenPanel *finder = [NSOpenPanel openPanel];
	[finder setCanChooseFiles:false];
	[finder setCanChooseDirectories:true];
	NSInteger r = [finder runModal];
	
	
	if(r == NSCancelButton) return;
	
	//NSString * tvarFilename = [finder filename];
	NSArray *urls = [finder URLs];
    NSString *tvarFullFilename = [[[(NSArray*)urls mutableCopy] firstObject] absoluteString];
    NSString *tvarFilename = [tvarFullFilename stringByReplacingOccurrencesOfString:@"file://localhost"
                                                                         withString:@""];
	
	[outputFolder setStringValue:tvarFilename];
	
	
}

- (void) progress:(NSString *)message {
	[progressMessage setObjectValue:message];
	[progressMessage display];
}

- (IBAction) doShrink:(id)sender {
	
	
	NSMutableArray *args;
	NSString *logfile = [NSString stringWithFormat:@"%@/smallshrink.log",[outputFolder stringValue]];
	
	

	NSIndexSet *rows;
	rows = [tableView selectedRowIndexes];
	
	int current_index = [rows firstIndex];
	
	if ([[target stringValue] isEqualToString:@"DVD Image"]) {
		
		[progressIndicator startAnimation:self];
		[self progress:@"Initialising"];
		
		
		
		args = [NSArray arrayWithObjects: @"-i", [source stringValue], @"-l", logfile, nil ];
		
		
		NSString *command = [[NSBundle mainBundle] pathForResource: @"ss_init" ofType:@"sh"];
		
		[self doTask:command : args];
		
		long long maxSize = [dvdSize intValue];
		maxSize*= 1000000;
		maxSize/= [rows count];
		maxSize/= 1.04;
		NSString *maxSizeStr = [NSString stringWithFormat: @"%qi" , maxSize];		
		
		while (current_index >=0 && current_index < 100)
		{
			
			NSDictionary *track = [dvdContents objectAtIndex:current_index];
			NSString *t = [NSString stringWithFormat: @"%@", [track objectForKey:@"ix"]];
			
			args=[NSMutableArray arrayWithObjects: @"-a", [audioStreamId stringValue], @"-s", maxSizeStr, 
				  @"-m", [method stringValue], @"-r", [requantize stringValue], @"-d", [demux stringValue],
				  @"-x", [remux stringValue], @"-k", [tempFiles stringValue], @"-t", t, nil];
			
			
			command = [[NSBundle mainBundle] pathForResource: @"ss_title" ofType:@"sh"];
			NSString *statusString = [NSString  stringWithFormat: @"Extracting title %@" , t];		
			
			[self progress: statusString];
			
			int r= [self doTask:command : args];
			if (r > 0) {
				NSString *errorMsg;
				switch(r) {
					case 1:
						errorMsg = [NSString  stringWithFormat: @"Error reading title %@ from DVD" , t];	
						break;
						
					case 2:
						errorMsg = [NSString  stringWithFormat: @"Error extracting audio from title %@" , t];	
						break;
						
					case 3:
						errorMsg = [NSString  stringWithFormat: @"Error extracting video from title %@" , t];	
						break;
						
					case 4:
						errorMsg = [NSString  stringWithFormat: @"Error remultiplexing title %@" , t];	
						break;
				}
				
				[self progress: errorMsg];
				[progressIndicator stopAnimation:self];
				return;
			}
			current_index = [rows indexGreaterThanIndex: current_index];
		}
		
		command = [[NSBundle mainBundle] pathForResource: @"ss_create" ofType:@"sh"];
		
		NSString *outputIso = [NSString stringWithFormat:@"%@/%@.iso",[outputFolder stringValue], [outputFilename stringValue]];
		args=[NSArray arrayWithObjects: @"-o", outputIso, @"-k", [tempFiles stringValue],  nil];
		[self progress: @"Creating DVD image"];
		
		int r=[self doTask:command : args];
		if (r > 0) {
			[self progress: @"Failed to create DVD image"];
		}
		else {
			[self progress: @"Finished"];
		}
		[progressIndicator stopAnimation:self];
	}
	
	
	if ([[target stringValue] isEqualToString:@"File"]) {
		
		while (current_index >=0 && current_index < 100)
		{
			
			NSDictionary *track = [dvdContents objectAtIndex:current_index];
			NSString *t = [NSString stringWithFormat: @"%@", [track objectForKey:@"ix"]];
			
			args=[NSMutableArray arrayWithObjects: @"-a", [audioStreamId stringValue],
				  @"-m", [method stringValue], @"-r", [requantize stringValue], @"-d", [demux stringValue],
				  @"-x", [remux stringValue], @"-i", [source stringValue],
				  @"-o", [outputFolder stringValue], @"-f", [outputFilename stringValue],				  
				  @"-l", logfile, @"-t", t,nil];

			
			NSString *command = [[NSBundle mainBundle] pathForResource: @"ss_file" ofType:@"sh"];
			NSString *statusString = [NSString  stringWithFormat: @"Extracting title %@" , t];		
			
			[self progress: statusString];
			
			int r= [self doTask:command : args];
			if (r > 0) {
				NSString *errorMsg;
				switch(r) {
					case 1:
						errorMsg = [NSString  stringWithFormat: @"Error reading title %@ from DVD" , t];	
						break;
						
					case 2:
						errorMsg = [NSString  stringWithFormat: @"Error extracting audio from title %@" , t];	
						break;
						
					case 3:
						errorMsg = [NSString  stringWithFormat: @"Error extracting video from title %@" , t];	
						break;
						
					case 4:
						errorMsg = [NSString  stringWithFormat: @"Error remultiplexing title %@" , t];	
						break;
				}
				
				[self progress: errorMsg];
				[progressIndicator stopAnimation:self];
				return;
			}
			current_index = [rows indexGreaterThanIndex: current_index];
		}
		
	[self progress: @"Finished"];
	[progressIndicator stopAnimation:self];
	
		
	}
	
}



- (void)awakeFromNib
{ 
	[NSApp setDelegate:self];
	dvdContents = [[NSMutableArray alloc] init];
	NSString *desktop = [NSSearchPathForDirectoriesInDomains(NSMOVIEDIRECTORY, NSUserDomainMask, YES) objectAtIndex:0];
	[outputFolder setStringValue:desktop];
}


- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}


//- (int)doTask: (NSString *) command: (NSArray *) arguments
- (int)doTask: (NSString *) command : (NSArray *) arguments
{
	NSTask *task;
	task = [[NSTask alloc] init];
	
	[task setLaunchPath: command];
	[task setArguments: arguments];
	
	
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
	[task setStandardError: pipe];
	[task setStandardInput:[NSPipe pipe]];
	
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
	
	
    [task launch];
	
    NSData *data;
    data = [file readDataToEndOfFile];
	
	//  NSString *string;
	//  string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	//  NSLog (@"%@", string);
	
	while ([task isRunning]) { }
	
	int r= [task terminationStatus];
	
	[task release];
	return r;
	
}

- (NSString *)lsdvd: (NSString *) dvdpath
{
	NSTask *task;
	task = [[NSTask alloc] init];
	
	NSMutableArray *arguments;
	arguments=[NSArray arrayWithObjects: @"-Oy", dvdpath,  nil];
	
	NSString *command = [[NSBundle mainBundle] pathForResource: @"lsdvd" ofType:@"sh"];
	[task setLaunchPath: command];
	[task setArguments: arguments];
	
    NSPipe *pipe;
	NSPipe *errpipe;
    pipe = [NSPipe pipe];
	errpipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
	[task setStandardError: errpipe];
	[task setStandardInput:[NSPipe pipe]];
	
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
	
    [task launch];
	
    NSData *data;
    data = [file readDataToEndOfFile];
	
	NSString *string;
	string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
		
	while ([task isRunning]) { }
	
	//int r= [task terminationStatus];
	
	SBJsonParser *parser = [[SBJsonParser alloc] init];
	NSDictionary *object = [parser objectWithString:string error:nil];
	
	dvdContents = [object objectForKey:@"track"];
	[dvdContents retain];
	
	[tableView reloadData];
	NSNumber *l= [object valueForKey:@"longest_track"];
	int longest = [l intValue] -1;
	
	NSIndexSet *i = [NSIndexSet indexSetWithIndex:longest];
	[tableView selectRowIndexes:i byExtendingSelection:NO];
	
	[task release];
	return string;
	
}


- (NSInteger)numberOfRowsInTableView:(NSTableView*)aTableView
{
	return [dvdContents count];
}

- (id)tableView:(NSTableView *)aTableView 
objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSDictionary *track = [dvdContents objectAtIndex:rowIndex];
	return  [track objectForKey:[aTableColumn identifier]]; 
}

- (void) tableViewSelectionDidChange: (NSNotification *) notification
{
	[dvdTitleNumber setStringValue:@""];
	NSIndexSet *rows;
	rows = [tableView selectedRowIndexes];
	
	int current_index = [rows firstIndex];
    while (current_index >=0 && current_index < 100)
    {
		NSDictionary *track = [dvdContents objectAtIndex:current_index];
		NSString *ix = [track objectForKey:@"ix"];
		[dvdTitleNumber setStringValue:[NSString stringWithFormat:@"%@ %@",[dvdTitleNumber stringValue], ix]];
        current_index = [rows indexGreaterThanIndex: current_index];
    }
	
} 

@end
