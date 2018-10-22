#import "FCLFormListViewController.h"
#import "FCLFormsBusinessFile.h"
#import "FCLForm.h"
#import "FCLFormViewController.h"
#import "FCLUploader.h"
#import "FCLUpload.h"
#import "UIViewController+Alert.h"

@interface FCLFormListViewController () <UploaderDelegate, FCLFormViewControllerDelegate>

@property(nonatomic, strong) FCLFormViewController* formController;
@property(nonatomic,strong) IBOutlet UIView* loadingView;
@property(nonatomic,strong) IBOutlet UILabel* helpFooterView;

@end

@implementation FCLFormListViewController

@synthesize businessFile = _businessFile;
-(void)setBusinessFile:(FCLFormsBusinessFile *)businessFile {
    @synchronized (self) {
        if(businessFile != _businessFile) {
            _businessFile = businessFile;
        }
    }
    
    __typeof(self) __weak weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.refreshControl endRefreshing];
        weakSelf.title = businessFile.name;
        [weakSelf.tableView reloadData];
    });
}

-(FCLFormsBusinessFile *)businessFile {
    @synchronized (self) {
        return _businessFile;
    }
}

#pragma mark Lifecycle

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    NSParameterAssert(self.delegate);
    NSParameterAssert(self.username);
    NSParameterAssert(self.password);
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Tirer pour rafraichir"];
    
    self.helpFooterView.text = NSLocalizedString(@"Insérez des photos et signatures sur votre application", @"");
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [FCLUploader sharedUploader].delegate = self;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [FCLUploader sharedUploader].delegate = nil;
}

// MARK: Actions

-(void)refresh:(id)sender {
    [self.delegate formListViewControllerRefresh:self];
}

// MARK: Rotation

- (UIInterfaceOrientationMask) supportedInterfaceOrientations
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAllButUpsideDown;
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (BOOL) shouldAutorotate
{
    return YES;
}



#pragma mark UploaderDelegate


- (void) uploaderDidUpdateStatus:(FCLUploader *)anUploader
{
    NSLog(@"uploaderDidUpdateStatus: isUploading: %d", (int)[anUploader isUploading]);
    [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.0];
}

- (void)uploader:(FCLUploader *)uploader didFailWithError:(NSError *)error {
    [self FCL_presentAlertForError:error];
}

#pragma mark UITableViewDataSource



- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
    return 1; // ([[Uploader sharedUploader] isUploading] ? 2 : 1);
}


- (NSInteger)tableView:(UITableView*)aTableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return self.businessFile ? [self.businessFile.forms count] : 0;
    if (section == 1) return 1;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:@"FormName"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FormName"];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        cell.textLabel.text = [[self.businessFile.forms objectAtIndex:indexPath.row] name];
        
        return cell;
    } else {
        UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:@"Loading"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Loading"];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.text = @"Téléchargement...";
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        return cell;
    }
}

#pragma mark UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        self.formController = [[FCLFormViewController alloc] initWithNibName:nil bundle:nil];
        self.formController.delegate = self;
        self.formController.form = [self.businessFile.forms objectAtIndex:indexPath.row];
        [self.formController.form reset];
        [self.formController.form loadDefaults];
        [self.navigationController pushViewController:self.formController animated:YES];
    }
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([[FCLUploader sharedUploader] isUploading])
    {
        return 32.0;
    }
    else
    {
        return 0.0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([[FCLUploader sharedUploader] isUploading])
    {
        return self.loadingView;
    }
    else
    {
        return nil;
    }
    
}

// MARK: FCLFormViewControllerDelegate

-(void) formViewControllerSend:(FCLFormViewController *)formController {
    [self.navigationController popViewControllerAnimated:YES];
    
    FCLUpload* upload = [[FCLUpload alloc] init];
    
    [formController.form saveDefaults];
    
    NSLog(@"Sending form %@ (%@) to business_file %@ (%@)", formController.form.name, formController.form.key, self.businessFile.name, self.businessFile.identifier);
    
    upload.fileId = self.businessFile.identifier;
    upload.categoryKey = formController.form.key;
    upload.fields = [formController fields];
    upload.image = formController.image;
    upload.username = self.username;
    upload.password = self.password;
    
    [[FCLUploader sharedUploader] addUpload:upload];
}

@end
