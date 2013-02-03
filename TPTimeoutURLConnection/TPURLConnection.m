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

#import "TPURLConnection.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) \
  ([[[UIDevice currentDevice] systemVersion] \
    compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface TPURLConnection ()

@property (readwrite, strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) NSTimeInterval timeoutInterval;
@property (strong, nonatomic) id delegate;
@property (strong, nonatomic) NSOperationQueue *queue;

@end

@implementation TPURLConnection

- (id)initWithRequest:(NSURLRequest *)request
      timeoutInterval:(NSTimeInterval)timeoutInterval
             delegate:(id)delegate
{
  return
    [self initWithRequest:request
          timeoutInterval:timeoutInterval
                 delegate:delegate
         startImmediately:YES];
}

- (id)initWithRequest:(NSURLRequest *)request
      timeoutInterval:(NSTimeInterval)timeoutInterval
             delegate:(id)delegate
     startImmediately:(BOOL)startImmediately
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
    return [super initWithRequest:r
                         delegate:delegate
                 startImmediately:startImmediately];
  }

  self = [self initWithRequest:request
                      delegate:delegate
              startImmediately:NO];
  if (!self) {
    return nil;
  }

  self.timeoutInterval = timeoutInterval;
  self.delegate = delegate;

  if (startImmediately) {
    [self start];
  }

  return self;
}

- (void)start
{
  if (![self.currentRequest.HTTPBody length]
      || SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
    [super start];
    return;
  }

  void (^b)(void) = ^{
    self.timer =
    [NSTimer
        scheduledTimerWithTimeInterval:self.timeoutInterval
                                target:self
                              selector:@selector(connectionTimeout:)
                              userInfo:nil
                               repeats:NO];
  };
  if (self.queue) {
    [self.queue addOperationWithBlock:b];
  } else {
      b();
  }
  [super start];
}

- (void)cancel
{
  if ([self.timer isValid]) {
    [self.timer invalidate];
  }
  [super cancel];
}

- (void)setDelegateQueue:(NSOperationQueue *)queue
{
  self.queue = queue;
  [super setDelegateQueue:queue];
}

#pragma mark -
#pragma mark private

- (void)connectionTimeout:(NSTimer *)timer
{
  [self cancel];

  NSError *error =
    [[NSError alloc]
      initWithDomain:NSURLErrorDomain
      code:NSURLErrorTimedOut
      userInfo:@{
        NSLocalizedDescriptionKey:
          @"The request timed out.",
        NSURLErrorFailingURLErrorKey:
          [[self originalRequest] URL],
        NSURLErrorFailingURLStringErrorKey:
          [[[self originalRequest] URL] absoluteString]}];

  void (^b)(void) = ^{
    [self.delegate connection:self didFailWithError:error];
  };
  if (self.queue) {
    [self.queue addOperationWithBlock:b];
  } else {
    b();
  }
}

@end

// EOF
