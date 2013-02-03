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

#import "URLConnection+TPTimeoutSync.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) \
  ([[[UIDevice currentDevice] systemVersion] \
    compare:v options:NSNumericSearch] != NSOrderedAscending)

typedef NS_ENUM(NSInteger, TPSURLConnectionResult) {
  TPSURLConnectionResultRunning = 0,
  TPSURLConnectionResultFinished,
  TPSURLConnectionResultFailed
};

@interface TPTimeoutSyncHelper : NSObject
  <NSURLConnectionDataDelegate>

@property (strong, nonatomic) NSURLResponse *response;
@property (strong, nonatomic) NSError *error;
@property (strong, nonatomic) NSMutableData *data;
@property (assign, nonatomic) TPSURLConnectionResult result;
@property (strong, nonatomic) NSTimer *timer;
@property (weak, nonatomic) NSURLConnection *connection;

- (NSData *)startSynchronousRequest:(NSURLRequest *)request
                    timeoutInterval:(NSTimeInterval)timeoutInterval;

@end

@implementation NSURLConnection (TPTimeoutSync)

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request
                   timeoutInterval:(NSTimeInterval)timeoutInterval
                 returningResponse:(NSURLResponse **)response
                             error:(NSError **)error
{
  if (![request.HTTPBody length]
      || SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
    // If HTTPBody is empty, or iOS version is 6.0 or above, iOS can
    // treat timeout correctly.
    NSURLRequest *r = request;
    if ([request timeoutInterval] != timeoutInterval) {
      NSMutableURLRequest *mr = [request mutableCopy];
      [mr setTimeoutInterval:timeoutInterval]; // for safety
      r = mr;
    }
    return [NSURLConnection
             sendSynchronousRequest:r
                  returningResponse:response
                              error:error];
  }
  TPTimeoutSyncHelper *helper = [[TPTimeoutSyncHelper alloc] init];
  if (!helper) {
    if (response) {
      *response = nil;
    }
    // TODO: should set right NSError.
    if (error) {
      *error = nil;
    }
    return nil;
  }
  NSData *d =
    [helper
      startSynchronousRequest:request
              timeoutInterval:timeoutInterval];

  if (response) {
    *response = helper.response ? helper.response : nil;
  }
  if (error) {
    *error = helper.error ? helper.error : nil;
  }
  return d;
}

@end

@implementation TPTimeoutSyncHelper

- (NSData *)startSynchronousRequest:(NSURLRequest *)request
                    timeoutInterval:(NSTimeInterval)timeoutInterval
{
  NSMutableURLRequest *mr = [request mutableCopy];
  [mr setTimeoutInterval:timeoutInterval];

  NSURLConnection *connection =
    [[NSURLConnection alloc]
      initWithRequest:mr
      delegate:self
      startImmediately:NO];
  if (!connection) {
    self.error = nil;     // TODO: should set right NSError.
    self.result = TPSURLConnectionResultFailed;
    return nil;
  }
  self.connection = connection;

  dispatch_semaphore_t sem = dispatch_semaphore_create(0);
  dispatch_async(
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    ^{
      if (self.timer) {
        [self.timer invalidate];
      }
      self.timer =
        [NSTimer
          scheduledTimerWithTimeInterval:timeoutInterval
                                  target:self
                                selector:@selector(connectionTimeout:)
                                userInfo:nil
                                 repeats:NO];
      self.data = [NSMutableData data];
      self.error = nil;
      self.result = TPSURLConnectionResultRunning;

      [self.connection start];
      do {
        [[NSRunLoop currentRunLoop]
          runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
      } while (self.result == TPSURLConnectionResultRunning);
      dispatch_semaphore_signal(sem);
    });
  dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
  dispatch_release(sem);

  if (self.result != TPSURLConnectionResultFinished) {
    return nil;
  }

  return self.data;
}

#pragma mark -
#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
  [self.timer invalidate];
  self.timer = nil;
  // If result is not Running, timeout may be fired, so
  // ignore.
  if (self.result == TPSURLConnectionResultRunning) {
    self.error = error;
    self.result = TPSURLConnectionResultFailed;
  }
}

#pragma mark -
#pragma mark NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
  self.response = response;
  [self.data setLength:0];
}

- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)data
{
  [self.data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  [self.timer invalidate];
  self.timer = nil;
  self.result = TPSURLConnectionResultFinished;
}

#pragma mark -
#pragma mark private

- (void)connectionTimeout:(NSTimer *)timer
{
  [self.connection cancel];
  self.result = TPSURLConnectionResultFailed;
  self.error =
    [[NSError alloc]
      initWithDomain:NSURLErrorDomain
      code:NSURLErrorTimedOut
      userInfo:@{NSLocalizedDescriptionKey:@"timed out"}];
}

@end

// EOF
