//
//  SPDYTests.m
//  SPDYTests
//
//  Created by Jim Morrison on 2/9/12.
//  Copyright (c) 2012 Twist Inc.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "SPDYTests.h"
#import "SPDY.h"

@interface CountError : RequestCallback
@property BOOL onErrorCalled;
@property (retain) NSError *error;
@end

@implementation CountError
@synthesize onErrorCalled;
@synthesize error = _error;

-(void)onError:(NSError *)error {
    self.error = error;
    self.onErrorCalled = YES;
}

- (void)dealloc {
    [_error release];
    [super dealloc];
}
@end

@interface TestSpdyLogger : NSObject<SpdyLogger>
@property (retain) NSString *lastLogLine;
@property (assign) const char *file;
@property (assign) int line;
@end

@implementation TestSpdyLogger
@synthesize lastLogLine;
@synthesize file = _file;
@synthesize line = _line;

- (void)writeSpdyLog:(NSString *)format file:(const char *)file line:(int)line, ... {
    va_list args;
    va_start(args, line);
    self.lastLogLine = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
    self.file = file;
    self.line = line;
    va_end(args);
    NSLog(@"[%s:%d] %@", self.file, self.line, self.lastLogLine);
}

@end

@implementation SPDYTests

- (void)testFetchNoHost {
    CountError *count = [[[CountError alloc] init] autorelease];
    SPDY *spdy = [[[SPDY alloc] init] autorelease];
    [spdy fetch:@"go" delegate:count];
    STAssertTrue(count.onErrorCalled, @"onError was called.");
    STAssertEquals((NSString *)kCFErrorDomainCFNetwork, count.error.domain, @"CFNetwork error domain");
    STAssertEquals((NSInteger)kCFHostErrorHostNotFound, count.error.code, @"Host not found error.");
}

- (void)testSPDY_LOG {
    SPDY *spdy = [SPDY sharedSPDY];
    TestSpdyLogger *logger = [[[TestSpdyLogger alloc] init] autorelease];
    spdy.logger = logger;
    SPDY_LOG(@"One two %s %d %@", "3", 4, @"five");
    STAssertEquals(logger.line, __LINE__ - 1, @"");
    STAssertTrue(strcmp(logger.file, __FILE__) == 0, @"%s != %s", logger.file, __FILE__);
    STAssertTrue([logger.lastLogLine isEqualToString:@"One two 3 4 five"], @"%@", logger.lastLogLine);
}

@end
