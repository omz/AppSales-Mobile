//
//  ReviewDetailViewController.m
//  AppSales
//
//  Created by Ole Zorn on 28.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "ReviewDetailViewController.h"
#import "Review.h"
#import "Product.h"

@interface ReviewDetailViewController ()

- (void)sendReviewViaEmail;

@end


@implementation ReviewDetailViewController

@synthesize prevItem, nextItem, toolbar;
@synthesize managedObjectContext;
@synthesize webView;

- (id)initWithAccount:(ASAccount *)acc product:(Product *)reviewProduct rating:(NSUInteger)ratingFilter index:(NSUInteger)aIndex
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
      account = [acc retain];
      managedObjectContext = [[account managedObjectContext] retain];
      rating = ratingFilter;
      product = [reviewProduct retain];
      index = aIndex;
    }
    return self;
}

- (void)loadView
{
  CGFloat toolbarHeight = UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? 32.0 : 44.0;

  self.webView = [[[UIWebView alloc] initWithFrame:CGRectZero] autorelease];
	webView.scalesPageToFit = YES;
	webView.dataDetectorTypes = UIDataDetectorTypeNone;
	self.view = webView;
  
  webView.frame = UIEdgeInsetsInsetRect(webView.frame, UIEdgeInsetsMake(0, 0, toolbarHeight, 0));

  
  self.toolbar = [[[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - toolbarHeight, self.view.bounds.size.width, toolbarHeight)] autorelease];
	toolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:toolbar];	
	
	UIBarButtonItem *sendReviewButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(sendReviewViaEmail)] autorelease];
  
	self.prevItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Back.png"] style:UIBarButtonItemStylePlain target:self action:@selector(selectPreviousReview:)] autorelease];
	self.nextItem  = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Forward.png"] style:UIBarButtonItemStylePlain target:self action:@selector(selectNextReview:)] autorelease];
	UIBarButtonItem *flexSpaceItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
	UIBarButtonItem *spaceItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil] autorelease];
	spaceItem.width = 21.0;

  toolbar.items = [NSArray arrayWithObjects:prevItem, nextItem, flexSpaceItem, flexSpaceItem, spaceItem, sendReviewButtonItem, nil];

  review = [[self fetchedReviewAtIndex:index] retain];
}

- (void)viewDidLoad
{
  [self reloadData];
}

- (void)reloadData
{
  NSString *template = [[[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ReviewTemplate" ofType:@"html"] encoding:NSUTF8StringEncoding error:NULL] autorelease];
	template = [template stringByReplacingOccurrencesOfString:@"[[[TITLE]]]" withString:review.title];
	NSString *ratingString = [@"" stringByPaddingToLength:[review.rating integerValue] withString:@"\u2605" startingAtIndex:0];
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	NSString *reviewDateString = [dateFormatter stringFromDate:review.reviewDate];
	NSString *reviewSubtitle = [NSString stringWithFormat:@"%@<br/>%@ – %@<br/>%@ %@", ratingString, review.user, reviewDateString, [review.product displayName], review.productVersion];
	
	template = [template stringByReplacingOccurrencesOfString:@"[[[SUBTITLE]]]" withString:reviewSubtitle];
	template = [template stringByReplacingOccurrencesOfString:@"[[[CONTENT]]]" withString:review.text];
	
	
	[self.webView loadHTMLString:template baseURL:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	review.unread = [NSNumber numberWithBool:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc
{
  [account release];
  [product release];
	[review release];
  [toolbar release];
	[managedObjectContext release];
	[webView release];
	[super dealloc];
}

- (void)sendReviewViaEmail
{
	if (![MFMailComposeViewController canSendMail]) {
		[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Email Account", nil) message:NSLocalizedString(@"You have not configured this device for sending email.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] autorelease] show];
		return;
	}
	MFMailComposeViewController *mailComposeViewController = [[[MFMailComposeViewController alloc] init] autorelease];
	mailComposeViewController.mailComposeDelegate = self;
	NSString *body = [self.webView stringByEvaluatingJavaScriptFromString: @"document.body.innerHTML"];
	NSString *subject = [NSString stringWithFormat:@"Review from %@", review.user];
	[mailComposeViewController setMessageBody:body isHTML:YES];
	[mailComposeViewController setSubject:subject];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		mailComposeViewController.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	[self presentModalViewController:mailComposeViewController animated:YES];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
	[self dismissModalViewControllerAnimated:YES];
}


- (void)selectPreviousReview:(id)sender
{
  [review release];
  index--;
  review = [[self fetchedReviewAtIndex:index] retain];
  [self reloadData];
}

- (void)selectNextReview:(id)sender
{
  [review release];
  index++;
  review = [[self fetchedReviewAtIndex:index] retain];
  [self reloadData];
}

- (Review *)fetchedReviewAtIndex:(NSUInteger)selectedIndex
{
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Review" inManagedObjectContext:self.managedObjectContext];
	if (product) {
		if (rating == 0) {
			[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"product == %@", product]];
		} else {
			[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"product == %@ AND rating == %@", product, [NSNumber numberWithInteger:rating]]];
		}
	} else {
		if (rating == 0) {
			[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"product.account == %@", account]];
		} else {
			[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"product.account == %@ AND rating == %@", account, [NSNumber numberWithInteger:rating]]];
		}
	}
	[fetchRequest setEntity:entity];
	[fetchRequest setFetchBatchSize:20];
  
	//Show latest unread reviews first:
	NSSortDescriptor *sortDescriptorUnread = [[[NSSortDescriptor alloc] initWithKey:@"unread" ascending:NO] autorelease];
	NSSortDescriptor *sortDescriptorDownloadDate = [[[NSSortDescriptor alloc] initWithKey:@"downloadDate" ascending:NO] autorelease];
	NSSortDescriptor *sortDescriptorReviewDate = [[[NSSortDescriptor alloc] initWithKey:@"reviewDate" ascending:NO] autorelease];
	
  NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptorUnread, sortDescriptorReviewDate, sortDescriptorDownloadDate, nil];
  [fetchRequest setSortDescriptors:sortDescriptors];
  
	// Create and initialize the fetch results controller.
	NSError *error = nil;
	NSArray *array = [managedObjectContext executeFetchRequest:fetchRequest error:&error];

  Review *aReview = (Review*)[array objectAtIndex:selectedIndex];
  
  if (selectedIndex==[array count]-1) {
    [nextItem setEnabled:NO];
  } else {
    [nextItem setEnabled:YES];
  }
  
  if (selectedIndex==0) {
    [prevItem setEnabled:NO];
  } else {
    [prevItem setEnabled:YES];
  }
  
  return aReview;
}


@end
