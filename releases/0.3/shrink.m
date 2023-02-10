//
//  shrink.m
//  SmallShrink
//
//  Created by Richard Hughes on 19/10/2009.
//  Copyright 2009 Small Software. All rights reserved.
//

#import "shrink.h"


@implementation shrink
- (IBAction) setDvdSource:(id)sender
{
	
	NSOpenPanel *finder	= [NSOpenPanel openPanel];
    [finder setCanChooseDirectories: YES];
    [finder setCanChooseFiles: NO];
	NSInteger r	= [finder runModalForTypes:nil];
	if(r == NSCancelButton)  return;
	
	NSString * tvarFilename = [finder filename];
	
	[source setStringValue:tvarFilename];
	
	
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
		
	NSString * tvarFilename = [finder filename];
	
	
	[outputFolder setStringValue:tvarFilename];
	
	
}

- (void) progress:(NSString *)message {
	[progressMessage setObjectValue:message];
	[progressMessage display];
}
	
- (IBAction) doShrink:(id)sender {
	
	
	NSArray *titles = [[dvdTitleNumber stringValue] componentsSeparatedByString:@" "];
	NSMutableArray *args;
	NSString *logfile = [NSString stringWithFormat:@"%@/smallshrink.log",[outputFolder stringValue]];
	

	
	if ([[target stringValue] isEqualToString:@"DVD Image"]) {
		
	[progressIndicator startAnimation:self];
	[self progress:@"Initialising"];

	
	
      args = [NSArray arrayWithObjects: @"-i", [source stringValue], @"-l", logfile, nil ];

   	
	NSString *command = [[NSBundle mainBundle] pathForResource: @"ss_init" ofType:@"sh"];
	
	[self doTask:command : args];
	
	long long maxSize = [dvdSize intValue];
	maxSize*= 1000000;
	maxSize/= [titles count];
	maxSize/= 1.04;

	NSString *maxSizeStr = [NSString stringWithFormat: @"%qi" , maxSize];		

	
	
	for (NSString *t in titles) {
	args=[NSMutableArray arrayWithObjects: @"-a", [audioStreamId stringValue], @"-s", maxSizeStr, 
			@"-m", [method stringValue], @"-r", [requantize stringValue], @"-d", [demux stringValue],
		    @"-x", [remux stringValue], @"-k", [tempFiles stringValue], nil];
		if(![t isEqualToString: @""]) {
			[args addObject: @"-t"];
			[args addObject: t];
		}
		
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
		
		for (NSString *t in titles) {
			args=[NSMutableArray arrayWithObjects: @"-a", [audioStreamId stringValue],
				  @"-m", [method stringValue], @"-r", [requantize stringValue], @"-d", [demux stringValue],
				  @"-x", [remux stringValue], @"-i", [source stringValue],
				  @"-o", [outputFolder stringValue], @"-f", [outputFilename stringValue],				  
				  @"-l", logfile, nil];
			if(![t isEqualToString: @""]) {
				[args addObject: @"-t"];
				[args addObject: t];
			}
			
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
		}
		
	}
	
}



- (void)awakeFromNib
{ 
	[NSApp setDelegate:self];
	
}


- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}


- (int)doTask: (NSString *) command: (NSArray *) arguments
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
	NSLog(@"task return code %d", r);

	
	[task release];
	return r;
	
}
@end
