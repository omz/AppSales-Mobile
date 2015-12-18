//
//  ReviewDetailViewController.m
//  AppSales
//
//  Created by Ole Zorn on 28.07.11.
//  Copyright 2011 omz:software. All rights reserved.
//

#import "ReviewDetailViewController.h"
#import "LoginManager.h"
#import "CountryDictionary.h"
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
	
	UIEdgeInsets contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 44.0f, 0.0f);
	
	webView = [[UIWebView alloc] initWithFrame:CGRectZero];
	webView.backgroundColor = [UIColor whiteColor];
	webView.opaque = NO;
	webView.scalesPageToFit = YES;
	webView.dataDetectorTypes = UIDataDetectorTypeNone;
	webView.scrollView.contentInset = contentInset;
	webView.scrollView.scrollIndicatorInsets = contentInset;
	self.view = webView;
	
	toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, self.view.bounds.size.height - contentInset.bottom, self.view.bounds.size.width, contentInset.bottom)];
	toolbar.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth);
	[self.view addSubview:toolbar];
	
	previousItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Back"] style:UIBarButtonItemStylePlain target:self action:@selector(previousReview)];
	nextItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Forward"] style:UIBarButtonItemStylePlain target:self action:@selector(nextReview)];
	UIBarButtonItem *flexSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	markItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Mark Unread", nil) style:UIBarButtonItemStylePlain target:self action:@selector(markReview)];
	
	toolbar.items = @[previousItem, nextItem, flexSpaceItem, markItem];
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

- (void)updateToolbarButtons {
	previousItem.enabled = (0 < index);
	nextItem.enabled = (index < (reviews.count - 1));
	markItem.title = reviews[index].unread.boolValue ? NSLocalizedString(@"Mark Read", nil) : NSLocalizedString(@"Mark Unread", nil);
	markItem.style = reviews[index].unread.boolValue ? UIBarButtonItemStyleDone : UIBarButtonItemStylePlain;
}

- (void)markUnread:(BOOL)unread {
	Review *review = reviews[index];
	review.unread = @(unread);
	
	markItem.title = review.unread.boolValue ? NSLocalizedString(@"Mark Read", nil) : NSLocalizedString(@"Mark Unread", nil);
	markItem.style = reviews[index].unread.boolValue ? UIBarButtonItemStyleDone : UIBarButtonItemStylePlain;
	
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
}

- (void)markReview {
	[self markUnread:!reviews[index].unread.boolValue];
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
	[self markUnread:NO];
	[self updateReviewWithTitle:nil text:nil];
}

- (void)updateReviewWithTitle:(NSString *)title text:(NSString *)text {
	Review *review = reviews[index];
	
	NSString *reviewTitle = title ?: review.title;
	
	NSString *reviewText = text ?: review.text;
	reviewText = [reviewText stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
	
	NSString *ratingString = [@"" stringByPaddingToLength:review.rating.integerValue withString:@"\u2605" startingAtIndex:0];
	ratingString = [ratingString stringByPaddingToLength:5 withString:@"\u2606" startingAtIndex:0];
	
	UIImage *flagImage = [UIImage imageNamed:review.countryCode.uppercaseString];
	if (flagImage == nil) {
		flagImage = [UIImage imageNamed:@"WW"];
	}
	NSData *flagData = UIImagePNGRepresentation(flagImage);
	NSString *flagBase64 = [flagData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
	NSString *countryName = [[CountryDictionary sharedDictionary] nameForCountryCode:review.countryCode.uppercaseString];
	
	NSString *template = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ReviewTemplate" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
	template = [template stringByReplacingOccurrencesOfString:@"[[[TITLE]]]" withString:reviewTitle];
	template = [template stringByReplacingOccurrencesOfString:@"[[[RATING]]]" withString:ratingString];
	template = [template stringByReplacingOccurrencesOfString:@"[[[NICKNAME]]]" withString:review.nickname];
	template = [template stringByReplacingOccurrencesOfString:@"[[[DATE]]]" withString:[dateFormatter stringFromDate:review.created]];
	template = [template stringByReplacingOccurrencesOfString:@"[[[COUNTRY_FLAG]]]" withString:flagBase64];
	template = [template stringByReplacingOccurrencesOfString:@"[[[COUNTRY_NAME]]]" withString:countryName];
	template = [template stringByReplacingOccurrencesOfString:@"[[[CONTENT]]]" withString:reviewText];
	
	[webView loadHTMLString:template baseURL:nil];
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
