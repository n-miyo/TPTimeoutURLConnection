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

#import "TPTimeoutSyncTests.h"
#import "URLConnection+TPTimeoutSync.h"
#import "TimeoutServer.h"

@implementation TPTimeoutSyncTests

- (void)setUp
{
  [super setUp];
}

- (void)tearDown
{
  [super tearDown];
}

// Added timeout error.
- (void)testSendPostRequestTimeoutError
{
  NSMutableURLRequest *urlRequest =
    [[NSMutableURLRequest alloc]
      initWithURL:[NSURL URLWithString:@"http://127.0.0.1:12345/"]];
  [urlRequest setHTTPMethod:@"POST"];
  [urlRequest setHTTPBody:[@"x" dataUsingEncoding:NSUTF8StringEncoding]];

  TimeoutServer *ts =
    [[TimeoutServer alloc] initWithPort:[NSNumber numberWithShort:12345]];
  dispatch_async(
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [ts runWithTimeout:10.0 connectionAccept:NO];
    });
  [NSThread sleepForTimeInterval:0.1]; // just wait for server invoke.

  NSURLResponse *response = nil;
  NSError *error = nil;
  NSData *d =
    [NSURLConnection
      sendSynchronousRequest:urlRequest
             timeoutInterval:5.0
           returningResponse:&response
                       error:&error];

  STAssertNotNil(error,
                 @"must be store correct error code.");
  STAssertEquals([error domain],
                 NSURLErrorDomain,
                 @"domain should be NSURLErrorDomain: %@", error);
  STAssertEquals([error code],
                 NSURLErrorTimedOut,
                 @"code should be NSURLErrorTimedOut: %@", error);
  STAssertNil(d,
              @"timeout should not have return data.");
  [ts closeSocket];
}

// Basic NSURLError.
- (void)testSendPostRequestBeforeTimeout
{
  NSMutableURLRequest *urlRequest =
    [[NSMutableURLRequest alloc]
      initWithURL:[NSURL URLWithString:@"http://127.0.0.1:11111/"]];
  [urlRequest setHTTPMethod:@"POST"];
  [urlRequest setHTTPBody:[@"x" dataUsingEncoding:NSUTF8StringEncoding]];

  NSURLResponse *response = nil;
  NSError *error = nil;
  NSData *d =
    [NSURLConnection
      sendSynchronousRequest:urlRequest
             timeoutInterval:5.0
           returningResponse:&response
                       error:&error];

  STAssertNotNil(error,
                 @"must be store correct error code.");
  STAssertEquals([error domain],
                 NSURLErrorDomain,
                 @"domain should be NSURLErrorDomain: %@", error);
  STAssertEquals([error code],
                 NSURLErrorCannotConnectToHost,
                 @"code should be NSURLErrorCannotConnectToHost: %@", error);
  STAssertNil(d,
              @"timeout should not have return data.");
}

// Connection success and no error.
- (void)testSendPostRequestSuccess
{
  NSMutableURLRequest *urlRequest =
    [[NSMutableURLRequest alloc]
      initWithURL:[NSURL URLWithString:@"http://127.0.0.1:54321/"]];
  [urlRequest setHTTPMethod:@"POST"];
  [urlRequest setHTTPBody:[@"x" dataUsingEncoding:NSUTF8StringEncoding]];

  TimeoutServer *ts =
    [[TimeoutServer alloc] initWithPort:[NSNumber numberWithShort:54321]];
  dispatch_async(
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [ts runWithTimeout:10.0 connectionAccept:YES];
    });
  [NSThread sleepForTimeInterval:0.1]; // just wait for server invoke.

  NSURLResponse *response = nil;
  NSError *error = nil;
  NSData *d =
    [NSURLConnection
      sendSynchronousRequest:urlRequest
             timeoutInterval:5.0
           returningResponse:&response
                       error:&error];

  STAssertNotNil(response,
                 @"must be correct response.");
  STAssertNil(error,
              @"must be no error.");
  STAssertNotNil(d,
                 @"should have return data.");
  NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
  STAssertTrue([s isEqualToString:@"foobar"],
               @"invalid received data");

  [ts closeSocket];
}

@end

// EOF
