Push DMs through APNS
=====================

This is a fairly simple rack app that takes emails from twitter (for DMs) and turns them in to push notifications.

Not included:

1. the smtpd. I use a modified version of the smtp2web smtpd - modified to actually parse the e-mail (so this app gets the 
headers posted and text pre-decoded). This will find its way to github sooner or later.
2. the iPhone app. It's so stupidly simple - all it does is turns on notifications and prints (to NSLog) the device ID. The 
smtpd posts the device ID through along with an auth key. (see the code)
3. the push-cert.pem. You'll need to register with the iPhone developer program and get a Push Notification Service SSL 
cert/key. Google will tell you how to get this.
4. thin/other webserver config. I use it with thin & nginx. You should do too, because they're awesome. Be especially mindful 
that Apple will get mad at you if you just send one push notification per connection to their servers. Well, if you do this 
several times a minute. Or whatever time frame they use. Just keep it in mind.

Licence
-------

Copyright (c) 2010 Patrick Quinn-Graham

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
