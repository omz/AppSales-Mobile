#AppSales

---

***Announcement***

*AppSales used to support downloading reviews, promo codes and payments. Because these features relied on scraping either iTunes Connect or the App Store, they have often not worked reliably or stopped working entirely when the iTunes Connect website changed. I haven't used these features a lot myself and I don't have the time anymore to patch them constantly, so I've reduced AppSales to its core functionality: downloading sales reports.*

*You can of course still use (or fork) one of the older versions if you rely on these features and can live with (or fix) the bugginess.*

---

AppSales allows iOS and Mac App Store developers to download and analyze their sales reports from iTunes Connect on the iPhone.

##Features
* Automatic download of daily and weekly sales reports from iTunes Connect
* Stacked bar graphs to see all your sales at a glance
* Show your sales on a world map
* Group daily reports by fiscal or calendar month to predict your next payment
* Automatic conversion to your currency of choice
* Import reports that you downloaded elsewhere (for example with [AppViz](http://www.ideaswarm.com) on your Mac) via iTunes File Sharing
* Optional push notifications when new reports are available via Boxcar

##Requirements
AppSales requires the iOS 7.0 SDK or later.

##Push Notifications
Because sales reports are not always available at the same time, I run a web service to send out push notifications when the daily reports have been generated.

You can get a notification when new reports are available with the free [Boxcar](http://itunes.apple.com/us/app/boxcar/id321493542) app. Boxcar can also be installed directly from the settings in AppSales.

If AppSales is installed, opening the push notification will automatically trigger the download of new reports but you can also use the push service without AppSales being installed. To do so, install [Boxcar](http://itunes.apple.com/us/app/boxcar/id321493542) and just add AppSales from the list of services in Boxcar.

Except for the total number of subscribers, I don't collect any data with the push service. You can stop receiving notifications at any time by simply removing AppSales from Boxcar.

##About
You can follow me on Twitter for updates on the development: [@olemoritz](http://twitter.com/olemoritz)

If you'd like to support this effort, please consider a donation via PayPal or Flattr:

<a href="https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=YDQN4S3WVRCBU&lc=US&item_name=AppSales&no_note=1&currency_code=USD"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif"/></a> <a href="http://flattr.com/thing/366574/AppSales" target="_blank">
<img src="http://api.flattr.com/button/flattr-badge-large.png" alt="Flattr this" title="Flattr this" border="0" /></a>

##License
In addition to the BSD-2 license below, I ask that you do not publicly distribute the app as a whole in binary form (e.g. on the App Store).

    Copyright (c) 2011, Ole Zorn
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this
      list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
    OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
