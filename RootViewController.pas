namespace Steps;

interface

uses
  Foundation,
  TwinPeaks,
  UIKit;

type
  [IBObject]
  RootViewController = public class (UITableViewController)
  private
    method newSteps(notification: NSNotification);
    method newStepsToday(notification: NSNotification);
    method refresh(sender: id);
  protected
  public
    method awakeFromNib; override;
    method viewDidLoad; override;
    method didReceiveMemoryWarning; override;

    {$REGION Table view data source}
    method numberOfSectionsInTableView(tableView: UITableView): Integer;
    method tableView(tableView: UITableView) numberOfRowsInSection(section: Integer): Integer;
    method tableView(tableView: UITableView) cellForRowAtIndexPath(indexPath: NSIndexPath): UITableViewCell;

    method tableView(tableView: UITableView) canMoveRowAtIndexPath(indexPath: NSIndexPath): Boolean;
    method tableView(tableView: UITableView) canEditRowAtIndexPath(indexPath: NSIndexPath): Boolean;
    {$ENDREGION}

    {$REGION Table view delegate}
    method tableView(tableView: UITableView) didSelectRowAtIndexPath(indexPath: NSIndexPath);
    {$ENDREGION}
  end;

implementation

method RootViewController.awakeFromNib;
begin
  inherited awakeFromNib;
end;

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
  result := AppDelegate.instance.Data:count;
end;

method RootViewController.tableView(tableView: UITableView) cellForRowAtIndexPath(indexPath: NSIndexPath): UITableViewCell;
begin
  //var CellIdentifier := StepsCellView.class.description;
  //result := tableView.dequeueReusableCellWithIdentifier(CellIdentifier);

  //if not assigned(result) then
  result := new BaseCell withStyle(UITableViewCellStyle.UITableViewCellStyleSubtitle) viewClass(StepsCellView.class);
  var lKeys :=  AppDelegate.instance.Data.allKeys.sortedArrayUsingDescriptors([NSSortDescriptor.alloc.initWithKey('self') ascending(NO)]);

  var lKey := lKeys[indexPath.row];
  //result.textLabel.text := AppDelegate.instance.Data[lKey].stringValue;

  var lView := (result as BaseCell).view as StepsCellView;
  lView.steps := AppDelegate.instance.Data[lKey];
  lView.date := lKey;
  lView.first := indexPath.row = 0;

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
