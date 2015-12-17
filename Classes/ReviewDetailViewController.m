//
//  ReviewDetailViewController.m
//  AppSales
//
//  Created by Ole Zorn on 28.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "ReviewDetailViewController.h"
#import "LoginManager.h"
#import "Review.h"
#import "Version.h"
#import "Product.h"

@implementation ReviewDetailViewController

- (instancetype)initWithReviews:(NSArray<Review *> *)_reviews selectedIndex:(NSInteger)_index {
	reviews = _reviews;
	index = _index;
	self = [super init];
	if (self) {
		self.title = reviews[index].version.number;
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	}
	return self;
}

- (void)loadView {
	[super loadView];
	
	webView = [[UIWebView alloc] initWithFrame:CGRectZero];
	webView.backgroundColor = [UIColor whiteColor];
	webView.opaque = NO;
	webView.scalesPageToFit = YES;
	webView.dataDetectorTypes = UIDataDetectorTypeNone;
	self.view = webView;
	
	toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, self.view.bounds.size.height - 44.0f, self.view.bounds.size.width, 44.0f)];
	toolbar.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth);
	[self.view addSubview:toolbar];
	
	previousItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Back"] style:UIBarButtonItemStylePlain target:self action:@selector(previousReview)];
	nextItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Forward"] style:UIBarButtonItemStylePlain target:self action:@selector(nextReview)];
	UIBarButtonItem *flexSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	
	toolbar.items = @[previousItem, nextItem, flexSpaceItem];
	toolbar.translucent = YES;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	UIBarButtonItem *sendReviewButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(sendReviewViaEmail)];
	self.navigationItem.rightBarButtonItem = sendReviewButtonItem;
	
	[self updateCurrentReview];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)previousReview {
	if (0 < index) {
		index--;
		[self updateCurrentReview];
	}
}

- (void)nextReview {
	if (index < (reviews.count - 1)) {
		index++;
		[self updateCurrentReview];
	}
}

- (void)updateCurrentReview {
	[self updateToolbarButtons];
	
	Review *review = reviews[index];
	review.unread = @(NO);
	
	NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init];
	moc.persistentStoreCoordinator = review.managedObjectContext.persistentStoreCoordinator;
	moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	
	[moc.persistentStoreCoordinator performBlockAndWait:^{
		NSError *saveError = nil;
		[moc save:&saveError];
		if (saveError) {
			NSLog(@"Could not save context: %@", saveError);
		}
	}];
	
	[self updateReviewWithTitle:nil text:nil];
}

- (void)updateReviewWithTitle:(NSString *)title text:(NSString *)text {
	Review *review = reviews[index];
	
	NSString *template = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ReviewTemplate" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
	
	NSString *ratingString = [@"" stringByPaddingToLength:review.rating.integerValue withString:@"\u2605" startingAtIndex:0];
	ratingString = [ratingString stringByPaddingToLength:5 withString:@"\u2606" startingAtIndex:0];
	
	template = [template stringByReplacingOccurrencesOfString:@"[[[TITLE]]]" withString:title ?: review.title];
	template = [template stringByReplacingOccurrencesOfString:@"[[[RATING]]]" withString:ratingString];
	template = [template stringByReplacingOccurrencesOfString:@"[[[NICKNAME]]]" withString:review.nickname];
	template = [template stringByReplacingOccurrencesOfString:@"[[[DATE]]]" withString:[dateFormatter stringFromDate:review.created]];
	template = [template stringByReplacingOccurrencesOfString:@"[[[CONTENT]]]" withString:text ?: review.text];
	
	[webView loadHTMLString:template baseURL:nil];
}

- (void)updateToolbarButtons {
	previousItem.enabled = (0 < index);
	nextItem.enabled = (index < (reviews.count - 1));
}

- (void)sendReviewViaEmail {
	Review *review = reviews[index];
	if (![MFMailComposeViewController canSendMail]) {
		[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Email Account", nil) message:NSLocalizedString(@"You have not configured this device for sending email.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
		return;
	}
	MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
	mailComposeViewController.mailComposeDelegate = self;
	[mailComposeViewController setSubject:[NSString stringWithFormat:@"%@ %@ Review From %@", review.product.displayName, review.version.number, review.nickname]];
	[mailComposeViewController setMessageBody:review.text isHTML:NO];
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		mailComposeViewController.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	[self presentViewController:mailComposeViewController animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
