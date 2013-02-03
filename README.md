TPTimeoutURLConnection
====================

DESCRIPTION
--------------------

In iOS 5 or below, there are a special specification that
when HTTPBody is set to a NSURLRequest instance, the
timeoutInterval is reset to 240 sec(
see:https://devforums.apple.com/message/108292/).  This
specification is not written in API document definitely.

You cannot reset the timeoutInterval under 240 sec if you
create NSMutableURLConnection instance.

To avoid this specification, you should invoke a timer, and
cancel the connection by yourself.

This tiny library add a category which treats timer and
cancel tasks in synchronous connection.  This library also
adds sample implementation for asynchronous connection.

In iOS 6 environment, this specification was changed and the
timoutInterval will not be changed if you set HTTPBody
value.


PLATFORM
--------------------

iOS 5 and above.  This library may be run in OS X
environment, but I've not tested.

You have to enable ARC.

This library my be run under iOS6 environment, but the OS
changed timeoutInterval specification, so you don't need to
use it anyway.


PREPARATION
--------------------

If you'd like to use synchronous connection, please copy
URLConnection+TPTimeoutSync.h and
URLConnection+TPTimeoutSync.m to your project.

If you'd like to use asynchronous connection, please copy
TPURLConnection.h and TPURLConnection.m files.  Then you
should implement some methods for your delegate with seeing
TPURLConnectionDelegate.h and TPURLConnectionDelegate.m.

You can install them via Cocoa Pod.


USAGE
--------------------

For synchronous connection, this library adds TPTimeoutSync
category to NSURLConnection and provides
sendSynchronousRequest:timeoutInterval:returningResponse:error:
method.

The specification is same as
sendSynchronousRequest:returningResponse:error: of
NSURLConnection, but you can provide timeout value with
timeoutInterval argument as NSURLRequest in a similar way.

For asynchronous connection, this library provides
TPURLConnection class, which inherits NSURLConnection.  This
class adds initWithRequest:timeoutInterval:delegate: and
initWithRequest:timeoutInterval:startImmediately: methods.
Both method are as same as NSURLConnection's one, but you
can set timeoutInterval.

If you use this class, you have to invalidate a timer, which is
for checking timeout, in your delegate.  You should check
TPURLConnectionDelegate class for implementation details.

You should take care that the timeout value which is
originally set to NSURLRequest might be changed by iOS
when you set HTTPBody to NSURLRequest.


AUTHOR
--------------------

MIYOKAWA, Nobuyoshi

* E-Mail: n-miyo@tempus.org
* Twitter: nmiyo
* Blog: http://blogger.tempus.org/


COPYRIGHT
--------------------

MIT LICENSE

Copyright (c) 2013 MIYOKAWA, Nobuyoshi (http://www.tempus.org/)

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
