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

#import "TimeoutServer.h"
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>

@interface TimeoutServer ()

@property (assign) int lsocket;
@property (assign) int asocket;
@property (assign) u_short port;

@end

@implementation TimeoutServer

- (id)initWithPort:(NSNumber *)port
{
  self = [super init];
  if (self) {
    self.lsocket = 0;
    self.asocket = 0;
    self.port = [port unsignedShortValue];
  }

  return self;
}

- (void)runWithTimeout:(NSTimeInterval)timeout
      connectionAccept:(BOOL)connectionAccept
{
  self.lsocket = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
  NSAssert(self.lsocket, @"invalid socket");

  struct sockaddr_in sin;
  memset(&sin, 0, sizeof(sin));
  sin.sin_len = sizeof(sin);
  sin.sin_family = AF_INET;
  sin.sin_port = htons(self.port);
  sin.sin_addr.s_addr = INADDR_ANY;

  NSLog(@"server: bind");
  NSAssert(bind(self.lsocket, (struct sockaddr *)&sin, sizeof(sin)) == 0,
           @"bind failed: %@", @(strerror(errno)));
  NSLog(@"server: listen");
  NSAssert(listen(self.lsocket, 5) == 0,
           @"listen failed: %@", @(strerror(errno)));

  [self performSelector:@selector(closeSocket)
             withObject:nil
             afterDelay:timeout];
  if (connectionAccept) {
    NSLog(@"server: waiting");
    self.asocket = accept(self.lsocket, NULL, NULL);
    NSLog(@"server: accept");
    NSAssert(self.asocket != -1,
             @"accept failed: %@", @(strerror(errno)));
    char *mes = "HTTP/1.0 200 OK\nContent-Type: text/xml;charset=utf-8\n"
                "Content-Length: 6\n\nfoobar";
    write(self.asocket, mes, strlen(mes)); // XXX
  }
}

- (void)closeSocket
{
  NSLog(@"server: closeSocket");
  if (self.lsocket) {
    close(self.lsocket);
    self.lsocket = 0;
  }
  if (self.asocket) {
    close(self.asocket);
    self.asocket = 0;
  }
}

@end

// EOF
