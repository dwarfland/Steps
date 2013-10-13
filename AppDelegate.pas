namespace Steps;

interface

uses
  CoreMotion,
  UIKit;

type
  [IBObject]
  AppDelegate = class(IUIApplicationDelegate)
  private
    fQueue: NSOperationQueue := new NSOperationQueue;
    fCounter: CMStepCounter;
    fDataFileName: NSString;

    method StepsQueryHandler(numberOfSteps: NSInteger; error: NSError);
    method StepsUpdateHandler(numberOfSteps: NSInteger;  timestamp: NSDate; error: NSError);
    method save; locked on self;

    const FETCH_INTERVAL = 60 * 60 * 12; //twice a day
  public
    property window: UIWindow;

    property daybreak: Int32 := 4; // 4:00 AM

    property Data: NSMutableDictionary;

    class property instance: AppDelegate;

    const NEW_STEPS_NOTIFICATION = 'com.dwarfland.steps.newsteps';
    const NEW_STEPS_TODAY_NOTIFICATION = 'com.dwarfland.steps.newsteps.today';

    method application(application: UIApplication) didFinishLaunchingWithOptions(launchOptions: NSDictionary): Boolean;
    method applicationWillResignActive(application: UIApplication);
    method applicationDidEnterBackground(application: UIApplication);
    method applicationWillEnterForeground(application: UIApplication);
    method applicationDidBecomeActive(application: UIApplication);
    method applicationWillTerminate(application: UIApplication);

    method application(application: UIApplication) performFetchWithCompletionHandler(completionHandler: block (fetchResult: UIBackgroundFetchResult));

    method LoadData;
    method LoadNewData;
    method LoadNewDataWithCompletion(aCompletion: block);

  end;

implementation

method AppDelegate.application(application: UIApplication) didFinishLaunchingWithOptions(launchOptions: NSDictionary): Boolean;
begin
  instance := self;

  application.setMinimumBackgroundFetchInterval(FETCH_INTERVAL);

  window := new UIWindow withFrame(UIScreen.mainScreen.bounds);

  application.statusBarStyle := UIStatusBarStyle.UIStatusBarStyleLightContent;
  var lNavigationController := new UINavigationController withRootViewController(new RootViewController);
  
  lNavigationController.navigationBar.tintColor := UIColor.colorWithRed(0.8) green(0.8) blue(1.0) alpha(1.0);
  lNavigationController.navigationBar.barTintColor := UIColor.colorWithRed(0.0) green(0.0) blue(0.5) alpha(1.0);
  
  var lAttributes := new NSMutableDictionary;
  lAttributes[NSForegroundColorAttributeName] :=  UIColor.colorWithRed(1.0) green(1.0) blue(1.0) alpha(1.0);
  lNavigationController.navigationBar.titleTextAttributes := lAttributes;
  
  window.rootViewController := lNavigationController;

  self.window.makeKeyAndVisible;

  if CMStepCounter.isStepCountingAvailable then begin
    NSLog('CMStepCounter.isStepCountingAvailable');
    fCounter := new CMStepCounter;
    fCounter.startStepCountingUpdatesToQueue(fQueue) updateOn(1) withHandler(@StepsUpdateHandler); 
  end;

  if not CMStepCounter.isStepCountingAvailable then begin
    var lAlert := new UIAlertView withTitle('No M7 Chip') 
                                      message('We''re sorry, but for for "Steps" to be useful, you need a device with an M7 chip, such as the iPhone 5S.') 
                                      &delegate(nil) 
                                      cancelButtonTitle('Ah, that sucks. :(') otherButtonTitles(nil); 
    lAlert.show();
  end;

  async begin
    LoadData;
    LoadNewData;
  end;

  result := true;
end;

method AppDelegate.applicationWillResignActive(application: UIApplication);
begin
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
end;

method AppDelegate.applicationDidEnterBackground(application: UIApplication);
begin
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
end;

method AppDelegate.applicationWillEnterForeground(application: UIApplication);
begin
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
end;

method AppDelegate.applicationDidBecomeActive(application: UIApplication);
begin
  async LoadNewData();
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
end;

method AppDelegate.applicationWillTerminate(application: UIApplication);
begin
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
end;

method AppDelegate.LoadData;
begin

  var lHomeFolder := NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.NSDocumentDirectory, NSSearchPathDomainMask.NSUserDomainMask, true):objectAtIndex(0);
  fDataFileName := lHomeFolder.stringByAppendingPathComponent('StepData.plist');
  if not NSFileManager.defaultManager.createDirectoryAtPath(lHomeFolder) withIntermediateDirectories(true) attributes(nil) error(nil) then
    NSLog('eror crearing documents folder%@', lHomeFolder);

  if NSFileManager.defaultManager.fileExistsAtPath(fDataFileName) then begin

    var lData := new NSData withContentsOfFile(fDataFileName);
    var lUnarchiver := new NSKeyedUnarchiver forReadingWithData(lData);
    Data := lUnarchiver.decodeObjectForKey('StepDataByDate').mutableCopy();
    lUnarchiver.finishDecoding();
  end;
  
  if not assigned(Data) then begin
    NSLog('no cached data found in %@', fDataFileName);
    Data := new NSMutableDictionary
  end
  else
    NSLog('data loaded from %@', fDataFileName);

end;

method AppDelegate.LoadNewData;
begin
  LoadNewDataWithCompletion(nil);
end;

method AppDelegate.LoadNewDataWithCompletion(aCompletion: block);
begin
  NSLog('LoadNewData');
  if not CMStepCounter.isStepCountingAvailable then begin
    if assigned(aCompletion) then aCompletion();
    exit;
  end;

  var lCalendar := NSCalendar.currentCalendar;
  var lNow := NSDate.date;
  var lUnitFlags := NSCalendarUnit.NSYearCalendarUnit or 
                    NSCalendarUnit.NSMonthCalendarUnit or 
                    NSCalendarUnit.NSDayCalendarUnit or 
                    NSCalendarUnit.NSHourCalendarUnit;
  var lDayUnitFlags := NSCalendarUnit.NSYearCalendarUnit or 
                       NSCalendarUnit.NSMonthCalendarUnit or 
                       NSCalendarUnit.NSDayCalendarUnit;
  var lGotoYesterdayComponents := new NSDateComponents;
  lGotoYesterdayComponents.day := -1;

  var lComponents := lCalendar.components(lUnitFlags) fromDate(lNow);
  var lComponents4AM := lComponents.copy;
  lComponents4AM.hour := 4;

  var lMorning := lCalendar.dateFromComponents(lComponents4AM);
  NSLog('now: %@', lNow);
  NSLog('morning: %@', lMorning);

  if lComponents.hour < daybreak then begin
    NSLog('it''s still yesterday');
    lMorning := lCalendar.dateByAddingComponents(lGotoYesterdayComponents) toDate(lMorning) options(0); 
  end;
  var lEnd := lNow;

  var lCount := 0;
  while (lCount < 10) do begin
    NSLog('morning: %@', lMorning);

    var lDayComponents := lCalendar.components(lDayUnitFlags) fromDate(lMorning); 
    var lDay := lCalendar.dateFromComponents(lDayComponents);
    // NSLog('day: %@', lDay);

    if (lCount > 0) and assigned(Data[lDay]) then break; 
    
    fCounter.queryStepCountStartingFrom(lMorning) 
             &to(lEnd)
             toQueue(fQueue)
             withHandler(method (numberOfSteps: NSInteger; error: NSError) begin
                           NSLog('%@ - %ld', lDay, numberOfSteps);
                           Data[lDay] := numberOfSteps;
                           dispatch_async(dispatch_get_main_queue(), method begin 
                                                                       NSNotificationCenter.defaultCenter.postNotificationName(NEW_STEPS_NOTIFICATION) object(self); 
                                                                       if assigned(aCompletion) then aCompletion();
                                                                       save();
                                                                     end);
                         end);

    if assigned(aCompletion) then break; // for now: only load one, when we are launched from background

    lEnd := lMorning;
    lMorning := lCalendar.dateByAddingComponents(lGotoYesterdayComponents) toDate(lMorning) options(0); 

    inc(lCount);

  end;
end;

method AppDelegate.save;
begin
  var lData := new NSMutableData;
  var lArchiver := new NSKeyedArchiver forWritingWithMutableData(lData);
  lArchiver.encodeObject(Data) forKey('StepDataByDate');
  lArchiver.finishEncoding();

  if lData.writeToFile(fDataFileName) atomically(YES) then
    NSLog('data saved to %@', fDataFileName)
  else
    NSLog('error saving data to %@', fDataFileName)
end;

method AppDelegate.StepsQueryHandler(numberOfSteps: NSInteger; error: NSError);
begin

end;

method AppDelegate.StepsUpdateHandler(numberOfSteps: NSInteger; timestamp: NSDate; error: NSError);
begin

end;

method AppDelegate.application(application: UIApplication) performFetchWithCompletionHandler(completionHandler: block (fetchResult: UIBackgroundFetchResult));
begin
  async LoadNewDataWithCompletion(-> completionHandler(UIBackgroundFetchResult.UIBackgroundFetchResultNewData));
end;

end.
