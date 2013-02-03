TPTimeoutURLConnection
====================

DESCRIPTION
--------------------

iOS 5以前のNSURLRequestは、HTTPBodyへ値が設定されると、タイム
アウトの最低値が240秒へ変更されてしまう仕様が存在します
(see:https://devforums.apple.com/message/108292/)。本件は特に
APIドキュメントへ明記されていません。

NSMutableURLConnectionインスタンスを用いた場合でも、タイムア
ウト値を240秒以下へ再設定することはできません。

解決策は自前でタイマを設定し、connection を明示的にcancelする
ことです。

この小さなライブラリは、同期通信に於いてこのタイマ稼働とキャ
ンセル処理を担当するカテゴリを追加するものです。また非同期通
信用のサンプル実装も提供します。

なお、iOS6では、この仕様が変更され、HTTPBodyへの値設定により
timeoutIntervalが変更されることはありません。


PLATFORM
--------------------

iOS 5以上。OSX でも動作可能だと思われますが未検証です。

ARC利用が必須です。

iOS6以上でも動作しますが、タイムアウトの仕様が改められている
ため、特に利用する必要はありません。


PREPARATION
--------------------

同期通信を行う場合、URLConnection+TPTimeoutSync.h と
URLConnection+TPTimeoutSync.m を利用したいプロジェクトへコピー
してください。

非同期通信を行う場合、TPURLConnection.h と TPURLConnection.m
をプロジェクトへコピーしてください。また、
TPURLConnectionDelegate.h とTPURLConnectionDelegate.m を元に
delegate 内メソッドを実装してください。

Cocoa Pod でインストールすることも可能です。

USAGE
--------------------

同期通信用途として、NSURLConnectionへTPTimeoutSyncカテゴリを
追加し
sendSynchronousRequest:timeoutInterval:returningResponse:error:
メソッドを提供しています。

使い方は、NSURLConnectionの
sendSynchronousRequest:returningResponse:error:と同じですが、
timeoutInterval引数により、NSURLRequest 同様にタイムアウト値
を設定することが可能です。

非同期通信用には、NSURLConnection を継承した TPURLConnection
クラスが提供され、initWithRequest:timeoutInterval:delegate:と、
initWithRequest:timeoutInterval:startImmediately:メソッドが追
加されています。どちらもtimeoutIntervalを指定できる以外は、
NSURLConnectionのメソッドと同様です。

このクラスを使う場合には、delegate内でタイムアウト監視用タイ
マをinvalidateする必要があります。実装の詳細は、同梱の
TPURLConnectionDelegateクラスを参照してください。

なお、NSURLRequestへ指定したTimeout値は、HTTPBodyを設定し
た時点でOSにより再設定されていることへご注意ください。


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
