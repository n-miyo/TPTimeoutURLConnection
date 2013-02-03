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

#import "TPTimeoutAsyncTests.h"
#import "TPURLConnection.h"
#import "TPURLConnectionDelegate.h"
#import "TimeoutServer.h"

typedef NS_ENUM(NSInteger, ConnectionResult) {
  ConnectionResultRunning = 0,
  ConnectionResultFinished,
  ConnectionResultFailed,
  ConnectionResultTimeout,
};

static NSInteger testCaseNum;
static dispatch_semaphore_t sem;
static ConnectionResult result;

@interface TestDelegate : SenTestCase

@property NSMutableData *data;
@property TPURLConnectionDelegate *delegate;

@end

@implementation TestDelegate

- (id)init
{
  self = [super init];
  if (self) {
    self.delegate = [TPURLConnectionDelegate new];
    self.data = [NSMutableData data];
  }
  return self;
}

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
  [self.data setLength:0];
}

- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)data
{
  [self.data appendData:data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
  [self.delegate connection:connection didFailWithError:error];
  switch(testCaseNum) {
  case 0:
    STAssertNotNil(error,
                   @"must be store correct error code.");
    STAssertEquals([error domain],
                   NSURLErrorDomain,
                   @"domain should be NSURLErrorDomain: %@", error);
    STAssertEquals([error code],
                   NSURLErrorTimedOut,
                   @"code should be NSURLErrorTimedOut: %@", error);
    result = ConnectionResultTimeout;
    break;
  case 1:
    STAssertNotNil(error,
                   @"must be store correct error code.");
    STAssertEquals([error domain],
                   NSURLErrorDomain,
                   @"domain should be NSURLErrorDomain: %@", error);
    STAssertEquals([error code],
                   NSURLErrorCannotConnectToHost,
                   @"code should be NSURLErrorTimedOut: %@", error);
    result = ConnectionResultFailed;
    break;
  case 2:
    STFail(@"Connection should not be fail.");
    result = ConnectionResultFinished;
    break;
  case 3:
    STAssertNotNil(error,
                   @"must be store correct error code.");
    STAssertEquals([error domain],
                   NSURLErrorDomain,
                   @"domain should be NSURLErrorDomain: %@", error);
    STAssertEquals([error code],
                   NSURLErrorTimedOut,
                   @"code should be NSURLErrorTimedOut: %@", error);
    NSOperationQueue *q = [NSOperationQueue currentQueue];
    STAssertEquals(q.name,
                   @"testManualStartTimeoutError",
                   @"should run on my delegate");
    result = ConnectionResultTimeout;
    break;
  }

  dispatch_semaphore_signal(sem);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  [self.delegate connectionDidFinishLoading:connection];
  switch(testCaseNum) {
  case 0:
    STFail(@"Connection should be fail.");
    break;
  case 1:
    STFail(@"Connection should be fail.");
    break;
  case 2:
    // no test.
    break;
  case 3:
    STFail(@"Connection should be fail.");
    break;
  }
  result = ConnectionResultFinished;
  dispatch_semaphore_signal(sem);
}

@end

@implementation TPTimeoutAsyncTests

- (void)setUp
{
  [super setUp];
  sem = dispatch_semaphore_create(0);
  result = ConnectionResultRunning;
}

- (void)tearDown
{
  [super tearDown];
  dispatch_release(sem);
}

- (void)testAutoStartTimeoutError
{
  NSMutableURLRequest *urlRequest =
    [[NSMutableURLRequest alloc]
      initWithURL:[NSURL URLWithString:@"http://127.0.0.1:12345/"]];
  [urlRequest setHTTPMethod:@"POST"];
  [urlRequest setHTTPBody:[@"x" dataUsingEncoding:NSUTF8StringEncoding]];
  [urlRequest setTimeoutInterval:5.0];

  TimeoutServer *ts =
    [[TimeoutServer alloc] initWithPort:[NSNumber numberWithShort:12345]];
  dispatch_async(
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [ts runWithTimeout:10.0 connectionAccept:NO];
    });
  [NSThread sleepForTimeInterval:0.1]; // just wait for server invoke.

  testCaseNum = 0;
  TestDelegate *d = [TestDelegate new];
  dispatch_async(
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    ^{
      TPURLConnection *con =
        [[TPURLConnection alloc]
          initWithRequest:urlRequest
          timeoutInterval:5.0
                 delegate:d];
      [[NSRunLoop currentRunLoop] run];
      con = nil;                // XXX
    });
  dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
  [ts closeSocket];

  STAssertEquals(result,
                 ConnectionResultTimeout,
                 @"result should be timeout: %d", result);
  STAssertEquals([d.data length],
                 0U,
                 @"should not have return data.");
}

// Basic NSURLError.
- (void)testSendPostRequestBeforeTimeout
{
  NSMutableURLRequest *urlRequest =
    [[NSMutableURLRequest alloc]
      initWithURL:[NSURL URLWithString:@"http://127.0.0.1:11111/"]];
  [urlRequest setHTTPMethod:@"POST"];
  [urlRequest setHTTPBody:[@"x" dataUsingEncoding:NSUTF8StringEncoding]];

  testCaseNum = 1;
  TestDelegate *d = [TestDelegate new];
  dispatch_async(
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    ^{
      TPURLConnection *con =
        [[TPURLConnection alloc]
          initWithRequest:urlRequest
          timeoutInterval:5.0
                 delegate:d];
      [[NSRunLoop currentRunLoop] run];
      con = nil; // XXX
    });
  dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

  STAssertEquals(result,
                 ConnectionResultFailed,
                 @"result should be fail: %d", result);
  STAssertEquals([d.data length],
                 0U,
                 @"should not have return data.");
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

  testCaseNum = 2;
  TestDelegate *d = [TestDelegate new];
  dispatch_async(
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    ^{
      TPURLConnection *con =
        [[TPURLConnection alloc]
          initWithRequest:urlRequest
          timeoutInterval:5.0
                 delegate:d];
      [[NSRunLoop currentRunLoop] run];
      con = nil; // XXX
    });
  dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
  [ts closeSocket];

  STAssertEquals(result,
                 ConnectionResultFinished,
                 @"result should not be fail: %d", result);
  STAssertTrue([d.data length] != 0U,
               @"should have return data.");

  NSString *s =
    [[NSString alloc] initWithData:d.data encoding:NSUTF8StringEncoding];
  STAssertTrue([s isEqualToString:@"foobar"],
               @"invalid received data");
}

- (void)testManualStartTimeoutError
{
  NSMutableURLRequest *urlRequest =
    [[NSMutableURLRequest alloc]
      initWithURL:[NSURL URLWithString:@"http://127.0.0.1:55555/"]];
  [urlRequest setHTTPMethod:@"POST"];
  [urlRequest setHTTPBody:[@"x" dataUsingEncoding:NSUTF8StringEncoding]];

  TimeoutServer *ts =
    [[TimeoutServer alloc] initWithPort:[NSNumber numberWithShort:55555]];
  dispatch_async(
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [ts runWithTimeout:10.0 connectionAccept:NO];
    });
  [NSThread sleepForTimeInterval:0.1]; // just wait for server invoke.

  testCaseNum = 3;
  TestDelegate *d = [TestDelegate new];
  NSOperationQueue *q = [[NSOperationQueue alloc] init];
  q.name = @"testManualStartTimeoutError";
  dispatch_async(
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    ^{
      TPURLConnection *con =
        [[TPURLConnection alloc]
          initWithRequest:urlRequest
          timeoutInterval:5.0
                 delegate:d
          startImmediately:NO];
      [con setDelegateQueue:q];
      [con start];
      [[NSRunLoop currentRunLoop] run];
    });
  dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
  [ts closeSocket];

  STAssertEquals(result,
                 ConnectionResultTimeout,
                 @"result should be timeout: %d", result);
  STAssertEquals([d.data length],
                 0U,
                 @"should not have return data.");
}

@end

// EOF
