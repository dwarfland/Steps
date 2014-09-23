namespace Steps;

interface

uses
  CoreMotion,
  Foundation,
  TwinPeaks,
  UIKit;

type
  [IBObject]
  RootViewController = public class (UITableViewController, IUITableViewDelegate, IUITableViewDataSource)
  private
    fKeys: NSArray;
    method newSteps(notification: NSNotification);
    method newStepsToday(notification: NSNotification);
    method refresh(sender: id);
  protected
  public
    method viewDidLoad; override;
    method didReceiveMemoryWarning; override;

    {$REGION Table view data source}
    method numberOfSectionsInTableView(tableView: UITableView): Integer;
    method tableView(tableView: UITableView) numberOfRowsInSection(section: Integer): Integer;
    method tableView(tableView: UITableView) heightForRowAtIndexPath(indexPath: NSIndexPath): CGFloat;
    method tableView(tableView: UITableView) cellForRowAtIndexPath(indexPath: NSIndexPath): UITableViewCell;

    method tableView(tableView: UITableView) canMoveRowAtIndexPath(indexPath: NSIndexPath): Boolean;
    method tableView(tableView: UITableView) canEditRowAtIndexPath(indexPath: NSIndexPath): Boolean;
    {$ENDREGION}

    {$REGION Table view delegate}
    method tableView(tableView: UITableView) didSelectRowAtIndexPath(indexPath: NSIndexPath);
    {$ENDREGION}
  end;

implementation

method RootViewController.viewDidLoad;
begin
  inherited viewDidLoad;

  title := 'Steps';
  tableView.separatorStyle := UITableViewCellSeparatorStyle.UITableViewCellSeparatorStyleNone;

  NSNotificationCenter.defaultCenter.addObserver(self) &selector(selector(newSteps:)) name(AppDelegate.NEW_STEPS_NOTIFICATION) object(AppDelegate.instance); 
  NSNotificationCenter.defaultCenter.addObserver(self) &selector(selector(newStepsToday:)) name(AppDelegate.NEW_STEPS_TODAY_NOTIFICATION) object(AppDelegate.instance); 
  newSteps(nil);
  
  if CMStepCounter.isStepCountingAvailable then begin
    refreshControl := new UIRefreshControl;
    refreshControl.tintColor := navigationController.navigationBar.barTintColor;
    refreshControl.addTarget(self) 
                    action(selector(refresh:))
                    forControlEvents(UIControlEvents.UIControlEventValueChanged);
  end;

end;

method RootViewController.didReceiveMemoryWarning;
begin
  inherited didReceiveMemoryWarning;
  // Dispose of any resources that can be recreated.
end;

method RootViewController.refresh(sender: id);
begin
  AppDelegate.instance.LoadNewDataWithCompletion(-> refreshControl.endRefreshing());
end;

method RootViewController.newSteps(notification: NSNotification);
begin
  fKeys := AppDelegate.instance:Data:allKeys:sortedArrayUsingDescriptors([NSSortDescriptor.alloc.initWithKey('self') ascending(false)]);
  tableView.reloadData();
end;

method RootViewController.newStepsToday(notification: NSNotification);
begin

end;

{$REGION Table view data source}

method RootViewController.numberOfSectionsInTableView(tableView: UITableView): Integer;
begin
  result := 1;
end;

method RootViewController.tableView(tableView: UITableView) numberOfRowsInSection(section: Integer): Integer;
begin
  result := fKeys:count;
end;

method RootViewController.tableView(tableView: UITableView) heightForRowAtIndexPath(indexPath: NSIndexPath): CGFloat;
begin
  result := 44;//inherited;
  if indexPath.row = 0 then result := result*2.5;
end;

method RootViewController.tableView(tableView: UITableView) cellForRowAtIndexPath(indexPath: NSIndexPath): UITableViewCell;
begin
  result := new TPBaseCell withStyle(UITableViewCellStyle.UITableViewCellStyleSubtitle) viewClass(StepsCellView.class);
  var lKey := fKeys[indexPath.row];
  //result.textLabel.text := AppDelegate.instance.Data[lKey].stringValue;

  var lView := (result as TPBaseCell).view as StepsCellView;
  lView.steps := AppDelegate.instance.Data[lKey];
  lView.date := lKey;
  lView.first := indexPath.row = 0;
  lView.best := assigned(AppDelegate.instance.best) and lView.steps.isEqualToNumber(AppDelegate.instance.best);

  //result.detailTextLabel.text := lKey.description;
end;

// Override to support conditional editing of the table view.
method RootViewController.tableView(tableView: UITableView) canEditRowAtIndexPath(indexPath: NSIndexPath): Boolean;
begin
  result := false;
end;

// Override to support conditional rearranging of the table view.
method RootViewController.tableView(tableView: UITableView) canMoveRowAtIndexPath(indexPath: NSIndexPath): Boolean;
begin
  result := false;
end;

{$ENDREGION}

{$REGION  Table view delegate}

method RootViewController.tableView(tableView: UITableView) didSelectRowAtIndexPath(indexPath: NSIndexPath);
begin
end;

{$ENDREGION}

end.
