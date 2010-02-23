h1. AppSales Mobile

AppSales Mobile allows iPhone developers to download and analyze their daily and weekly sales reports from iTunes Connect.

The current version is meant to be built for iPhone OS 3.0.

Features:
* Automatic download of daily and weekly sales reports from iTunes Connect
* Convenient graphs for viewing trends and sales by region with selectable date range
* Automatic conversion to your currency of choice
* Download reviews of your apps

Because there is no real API to access iTunes Connect trend reports, AppSales Mobile scrapes itts.apple.com. This means that even small changes on this website can break AppSales ability to download reports automatically. In most cases, this is easy to fix and I'll try to make a new version available asap.

You can follow me on Twitter: "@olemoritz":http://twitter.com/olemoritz
If you like, check out my commercial iPhone apps at "omz-software.com":http://omz-software.com


h2. Modified version by Edward Patel

* Changed version -> 1.2
* Added compile time versioning which gives a bundle version like 1.1.yymmddhhmmss
* Added backup of reportfiles to computer. Compiling will give an error at a line where a http access is hardcoded. We are developers so I think most should be able to figure it out.
* Added a php script to receive and store reportfiles on the computer. Please read in upload_appsales.php for more information.
* Merged ktakayama Totals additions


Jon Kean additions:
* automatic translation of foreign reviews (using Google translate).
* app review fetching is done in parallel (and is now an order of magnitude faster than before)
* importing of CSV files:
  Copy any old CSV report files into the 'Prefetched' folder, and they'll be automatically imported the first time launching the app.
  CSV files can have either .csv or .txt extension.
  First time starting the app may take slightly longer as the CSV files are parsed.
* better startup/shutdown performance, and better support for handling large amounts of data 
