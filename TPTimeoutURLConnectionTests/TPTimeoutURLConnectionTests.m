// -*- mode:objc -*-
//
// Copyright (c) 2013 MIYOKAWA, Nobuyoshi (http://www.tempus.org/)
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

#import "TPTimeoutURLConnectionTests.h"

@implementation TPTimeoutURLConnectionExampleTests

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

- (void)setUp
{
  [super setUp];
}

- (void)tearDown
{
  [super tearDown];
}

- (void)testTimeoutSetting
{
  NSTimeInterval ios5Timeout = 240.0;
  NSTimeInterval timeout = 20.0;
  NSTimeInterval newTimeout = 40.0;

  NSMutableURLRequest *request =
    [NSMutableURLRequest
      requestWithURL:[NSURL URLWithString:@"http://www.example.com/"]
         cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
      timeoutInterval:timeout];
  STAssertEquals([request timeoutInterval],
                 timeout,
                 @"have to be same timeout value with being set.");

  [request setHTTPBody:[@"x" dataUsingEncoding:NSUTF8StringEncoding]];
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
    STAssertEquals([request timeoutInterval],
                   timeout,
                   @"iOS6 should hold correct timeout.");
  } else {
    STAssertEquals([request timeoutInterval],
                   ios5Timeout,
                   @"iOS5 may hold invalid value for POST.");
  }

  [request setTimeoutInterval:newTimeout];
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
    STAssertEquals([request timeoutInterval],
                   newTimeout,
                   @"iOS6 should hold correct timeout.");
  } else {
    STAssertEquals([request timeoutInterval],
                   ios5Timeout,
                   @"iOS5 may hold invalid value for POST.");
  }
}

- (void)testOverTimeoutSetting
{
  NSTimeInterval timeout = 360.0;
  NSTimeInterval newTimeout = 480.0;

  NSMutableURLRequest *request =
    [NSMutableURLRequest
      requestWithURL:[NSURL URLWithString:@"http://www.example.com/"]
         cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
      timeoutInterval:timeout];
  STAssertEquals([request timeoutInterval],
                 timeout,
                 @"have to be same timeout value with being set.");

  [request setHTTPBody:[@"x" dataUsingEncoding:NSUTF8StringEncoding]];
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
    STAssertEquals([request timeoutInterval],
                   timeout,
                   @"iOS6 should hold correct timeout.");
  } else {
    STAssertEquals([request timeoutInterval],
                   timeout,
                   @"iOS5 should hold correct timeout.");
  }

  [request setTimeoutInterval:newTimeout];
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
    STAssertEquals([request timeoutInterval],
                   newTimeout,
                   @"iOS6 should hold correct timeout.");
  } else {
    STAssertEquals([request timeoutInterval],
                   newTimeout,
                   @"iOS5 should hold correct timeout.");
  }
}

@end

// EOF
