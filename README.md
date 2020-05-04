# AppSales

AppSales allows iOS and Mac App Store developers to download and analyze their sales reports from iTunes Connect on the iPhone.

## Features

* Automatic download of daily and weekly sales reports from iTunes Connect.
* Stacked bar graphs to see all your sales at a glance.
* Show your sales on a world map.
* View actual payments by Apple on a calendar.
* Group daily reports by fiscal or calendar month to predict your next payment.
* Automatic conversion to your currency of choice.
* Download customer reviews of your apps.
* Import reports that you downloaded elsewhere via iTunes File Sharing.

Please see the screenshot below for a visual guide to AppSales' main interface and some tips and tricks.

## Requirements

AppSales requires the iOS 8.2 SDK or later.

Report downloads uses Apple's Reporter API, while Payments and Customer Reviews are fetched using their appropriate iTunes Connect JSON API. This means that the app should generally be unaffected by changes to the website.

## Getting Started

Run the following command in Terminal.app to download a copy of this repo (along with all submodules) to your machine:

```
git clone --recursive https://github.com/nicolasgomollon/AppSales-Mobile.git
```

NOTE: Make sure to run the following command after `git pull`ing any changes:

```
git submodule update --recursive
```

## About

Original _(now obsolete)_ project by [@olemoritz](https://twitter.com/olemoritz) at [omz/AppSales-Mobile](https://github.com/omz/AppSales-Mobile). Continued maintenance and development by [Nicolas Gomollon](https://nicolas.gomollon.me/).

![AppSales Screenshot](Screenshot.png?raw=true)

## License

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
