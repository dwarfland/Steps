namespace Steps;

interface

uses
  CoreMotion,
  HealthKit,
  UIKit;

type
  [IBObject]
  AppDelegate = class(IUIApplicationDelegate)
  private
    fQueue: NSOperationQueue := new NSOperationQueue;
    fCounter: CMStepCounter;
    fDataFileName: NSString;
    fDistanceDataFileName: NSString;
    fLoadingNewData: Boolean;

    method StepsQueryHandler(numberOfSteps: NSInteger; error: NSError);
    method StepsUpdateHandler(numberOfSteps: NSInteger;  timestamp: NSDate; error: NSError);
    method save; locked on self;
    method updateStatictics;

    const FETCH_INTERVAL = 60 * 60 * 12; //twice a day

    const KEY_STEP_DATA_BY_DATE = 'StepDataByDate';
    const KEY_DISTANCE_DATA_BY_DATE = 'DistanceDataByDate';
    const KEY_LAST_FINISHED_DAY = 'DateOfLastFinishedDay';
  public
    property window: UIWindow;

    property daybreak: Int32 := 4; // 4:00 AM

    property Data: NSMutableDictionary;
    property HealthKitData: NSMutableDictionary;
    property DistanceData: NSMutableDictionary;
    property best: NSNumber := 0;
    property weeklyAverage: NSNumber;
    property monthlyAverage: NSNumber;

    property LastFinishedDay: NSDate;
    
    class property StepCountQuantityType: HKQuantityType := HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount);// lazy;
    class property DistanceCountQuantityType: HKQuantityType := HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning); //lazy;
    class property HealthStore: HKHealthStore := new HKHealthStore(); //lazy;

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
    method LoadNewHealthKitData;
    method LoadNewHealthKitDataWithCompletion(aCompletion: block);
    method AuthorizeHealthKitWithCompletion(aCompletion: block(aSuccess: Boolean));

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
  //lNavigationController.navigationBar.barTintColor := UIColor.colorWithRed(0.0) green(0.0) blue(0.5) alpha(1.0);// somehowe the logic for this changed in 7.0.3?
  lNavigationController.navigationBar.barTintColor := UIColor.colorWithRed(83.0/256.0) green(83.0/256.0) blue(166.0/256.0) alpha(1.0);
  
  var lAttributes := new NSMutableDictionary;
  lAttributes[NSForegroundColorAttributeName] :=  UIColor.colorWithRed(1.0) green(1.0) blue(1.0) alpha(1.0);
  lNavigationController.navigationBar.titleTextAttributes := lAttributes;
  
  window.rootViewController := lNavigationController;

  self.window.makeKeyAndVisible;

  if CMStepCounter.isStepCountingAvailable then begin
    NSLog('CMStepCounter.isStepCountingAvailable');
    fCounter := new CMStepCounter;
    fCounter.startStepCountingUpdatesToQueue(fQueue) updateOn(1) withHandler(@StepsUpdateHandler); 
  end 
  else begin
    var lAlert := new UIAlertView withTitle('No M7 or M8 Chip') 
                                      message('We''re sorry, but for for "Steps" to be useful, you need a device with an M7 or M8 chip, such as the iPhone 5S.') 
                                      &delegate(nil) 
                                      cancelButtonTitle('Ah, that sucks. :(') otherButtonTitles(nil); 
    lAlert.show();
  end;

  //async begin
  AuthorizeHealthKitWithCompletion(method (aSuccess: Boolean) begin
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), -> begin
      LoadData;
      if aSuccess then
        LoadNewHealthKitData();
      LoadNewData;
      dispatch_async(dispatch_get_main_queue(), method begin 
        NSNotificationCenter.defaultCenter.postNotificationName(NEW_STEPS_NOTIFICATION) object(self);
      end);
    end);
  end);

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
  NSLog('applicationDidBecomeActive: loadLoadNewDatanewdata');
  //async LoadNewData();
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), -> begin
    {async} LoadNewData();
  end);
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
  fDistanceDataFileName := lHomeFolder.stringByAppendingPathComponent('DistanceData.plist');
  if not NSFileManager.defaultManager.createDirectoryAtPath(lHomeFolder) withIntermediateDirectories(true) attributes(nil) error(nil) then
    NSLog('eror crearing documents folder%@', lHomeFolder);

  if NSFileManager.defaultManager.fileExistsAtPath(fDataFileName) then begin
    var lData := new NSData withContentsOfFile(fDataFileName);
    var lUnarchiver := new NSKeyedUnarchiver forReadingWithData(lData);

    Data := lUnarchiver.decodeObjectForKey(KEY_STEP_DATA_BY_DATE):mutableCopy();
    if not assigned(Data) then
      Data := new NSMutableDictionary;

    DistanceData := lUnarchiver.decodeObjectForKey(KEY_DISTANCE_DATA_BY_DATE):mutableCopy();
    if not assigned(DistanceData) then
      DistanceData := new NSMutableDictionary;

    if assigned(Data) then begin
      LastFinishedDay := lUnarchiver.decodeObjectForKey(KEY_LAST_FINISHED_DAY);
      NSLog('LastFinishedDay %@', LastFinishedDay);
    end;

    lUnarchiver.finishDecoding();
  end;
end;

method AppDelegate.LoadNewData;
begin
  LoadNewDataWithCompletion(nil);
end;

method AppDelegate.LoadNewHealthKitData;
begin
  LoadNewHealthKitDataWithCompletion(nil);
end;

method AppDelegate.LoadNewDataWithCompletion(aCompletion: block);
begin
  if fLoadingNewData then exit;
  fLoadingNewData := true;
  try

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
    // NSLog('now: %@', lNow);
    // NSLog('morning: %@', lMorning);

    if lComponents.hour < daybreak then begin
      //NSLog('it''s still yesterday');
      lMorning := lCalendar.dateByAddingComponents(lGotoYesterdayComponents) toDate(lMorning) options(0); 
    end;
    var lEnd := lNow;

    var lNewLastFinishedDay := lMorning;

    var lCount := 0;
    while (lCount < 10) do begin

      if assigned(LastFinishedDay) and (lEnd.compare(LastFinishedDay) in [NSComparisonResult.NSOrderedSame, NSComparisonResult.NSOrderedAscending]) then begin
        //NSLog('stopping');
        break;
      end;
      //NSLog('getting: %@ - %@ (%@)', lMorning, lEnd, LastFinishedDay);

      var lDayComponents := lCalendar.components(lDayUnitFlags) fromDate(lMorning); 
      var lDay := lCalendar.dateFromComponents(lDayComponents);

      fCounter.queryStepCountStartingFrom(lMorning) 
               &to(lEnd)
               toQueue(fQueue)
               withHandler(method (numberOfSteps: NSInteger; error: NSError) begin
                             //NSLog('%@ - %ld', lDay, numberOfSteps);
                             if (not assigned( Data[lDay])) or (Data[lDay].integerValue < numberOfSteps) then
                               Data[lDay] := numberOfSteps;
                             //else
                               //NSLog('skipped updating %@ (%d)', lDay, numberOfSteps);
                             dispatch_async(dispatch_get_main_queue(), method begin 
                                                                         updateStatictics();
                                                                         NSNotificationCenter.defaultCenter.postNotificationName(NEW_STEPS_NOTIFICATION) object(self);
                                                                      
                                                                         if assigned(LastFinishedDay) and lEnd.isEqualToDate(LastFinishedDay) then
                                                                           if assigned(aCompletion) then aCompletion();
                                                                         save();
                                                                       end);
                           end);

      lEnd := lMorning;
      lMorning := lCalendar.dateByAddingComponents(lGotoYesterdayComponents) toDate(lMorning) options(0); 

      inc(lCount);
    end;

    // clean up the last days w/o data
    {var lKeys := Data.allKeys.sortedArrayUsingDescriptors([NSSortDescriptor.alloc.initWithKey('self') ascending(true)]);
    for each k in lKeys do begin
      if Data[k].integerValue > 0 then break;
      Data.removeObjectForKey(k);
    end;
    NSNotificationCenter.defaultCenter.postNotificationName(NEW_STEPS_NOTIFICATION) object(self);}

    LastFinishedDay := lNewLastFinishedDay;
    //NSLog('set last finished day to %@', LastFinishedDay);
    save();

  finally
    fLoadingNewData := false;
  end;
end;

method AppDelegate.AuthorizeHealthKitWithCompletion(aCompletion: block(aSuccess: Boolean));
begin
  var readTypes := NSSet.setWithObjects(StepCountQuantityType, DistanceCountQuantityType, nil);
  HealthStore.requestAuthorizationToShareTypes(NSSet.set) readTypes(readTypes) completion( method (aSuccess: Boolean; aError: NSError) begin
    if not aSuccess then 
      NSLog('Error accessing Health Kit: %@', aError);
    if assigned(aCompletion) then aCompletion(aSuccess);
  end);  
end;

method AppDelegate.LoadNewHealthKitDataWithCompletion(aCompletion: block);
begin
  //if fLoadingNewData then exit;
  //fLoadingNewData := true;
  try

    NSLog('LoadNewHealthKitData');

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

    if lComponents.hour < daybreak then begin
      NSLog('it''s still yesterday');
      lMorning := lCalendar.dateByAddingComponents(lGotoYesterdayComponents) toDate(lMorning) options(0); 
    end;
    var lEnd := lNow;

    var lNewLastFinishedDay := lMorning;

    HealthKitData := new NSMutableDictionary();

    var lCount := 0;
    while (lCount < 10) do begin

      var lCouldBeDone := assigned(LastFinishedDay) and (lEnd.compare(LastFinishedDay) in [NSComparisonResult.NSOrderedSame, NSComparisonResult.NSOrderedAscending]);
      NSLog('getting: %@ - %@ (%@)', lMorning, lEnd, LastFinishedDay);

      var lDayComponents := lCalendar.components(lDayUnitFlags) fromDate(lMorning); 
      var lDay := lCalendar.dateFromComponents(lDayComponents);
      var lPredicate := HKQuery.predicateForSamplesWithStartDate(lMorning) endDate(lEnd) options(HKQueryOptions.HKQueryOptionNone);
      
      if lCouldBeDone and assigned(Data[lDay]) and assigned(HealthKitData[lDay]) then begin
        NSLog('stopping');
        break;
      end;

      if not assigned(Data[lDay]) or not lCouldBeDone then begin
        var q := new HKSampleQuery withSampleType(StepCountQuantityType) 
                                      predicate(lPredicate) 
                                      limit(HKObjectQueryNoLimit) 
                                      sortDescriptors(nil) 
                                      resultsHandler( method (aQuery: HKSampleQuery; aResults: NSArray; aError: NSError) begin
          if aResults.count > 0 then begin
            var lSteps := 0;
            for each s in aResults do begin
              lSteps := lSteps+Integer(s.quantity.doubleValueForUnit(HKUnit.countUnit))
            end;
            NSLog('Steps: %ld', lSteps);
            
            if (not assigned(HealthKitData[lDay])) or (HealthKitData[lDay].integerValue < lSteps) then begin
              HealthKitData[lDay] := lSteps;
              dispatch_async(dispatch_get_main_queue(), method begin 
                //updateStatictics();
                NSNotificationCenter.defaultCenter.postNotificationName(NEW_STEPS_NOTIFICATION) object(self);
                save();
              end);
            end;
            
          end;
        end);
        HealthStore.executeQuery(q);
      end
      else begin
        NSLog('skipping getting steps');
      end;

      if not assigned(HealthKitData[lDay]) or not lCouldBeDone then begin
        var q := new HKSampleQuery withSampleType(DistanceCountQuantityType) 
                                      predicate(lPredicate) 
                                      limit(HKObjectQueryNoLimit) 
                                      sortDescriptors(nil) 
                                      resultsHandler( method (aQuery: HKSampleQuery; aResults: NSArray; aError: NSError) begin
          if aResults.count > 0 then begin
            NSLog('got %ld walking distance info records', aResults.count);
            var lDistance := 0.0;
            for each s in aResults do begin
              lDistance := lDistance+s.quantity.doubleValueForUnit(HKUnit.meterUnitWithMetricPrefix(HKMetricPrefix.Kilo))
            end;
            NSLog('Distance: %f', lDistance);
            
            if (not assigned(DistanceData[lDay])) or (DistanceData[lDay].doubleValue < lDistance) then begin
              DistanceData[lDay] := lDistance;
              dispatch_async(dispatch_get_main_queue(), method begin 
                //updateStatictics();
                NSNotificationCenter.defaultCenter.postNotificationName(NEW_STEPS_NOTIFICATION) object(self);
                save();
              end);
            end;
            
          end;
        end);
        HealthStore.executeQuery(q);
      end
      else begin
        NSLog('skipping getting distance');
      end;

      lEnd := lMorning;
      lMorning := lCalendar.dateByAddingComponents(lGotoYesterdayComponents) toDate(lMorning) options(0); 

      inc(lCount);
      NSLog('count: %ld', lCount);
    end;

    // clean up the last days w/o data
    {var lKeys := Data.allKeys.sortedArrayUsingDescriptors([NSSortDescriptor.alloc.initWithKey('self') ascending(true)]);
    for each k in lKeys do begin
      if Data[k].integerValue > 0 then break;
      Data.removeObjectForKey(k);
    end;
    NSNotificationCenter.defaultCenter.postNotificationName(NEW_STEPS_NOTIFICATION) object(self);}

    //LastFinishedDay := lNewLastFinishedDay;
    //NSLog('set last finished day to %@', LastFinishedDay);
    //save();

  finally
    //fLoadingNewData := false;
  end;
end;

method AppDelegate.updateStatictics;
begin
  best := Data.allValues.valueForKeyPath('@max.self');

  var lWeek := new NSMutableArray;
  var lMonth := new NSMutableArray;

  var lKeys := AppDelegate.instance:Data:allKeys:sortedArrayUsingDescriptors([NSSortDescriptor.alloc.initWithKey('self') ascending(false)]);
  for each k in lKeys index i do begin
    if i ≥ 30 then break;
    var lData := Data[k];
    if not assigned(lData) or (lData.intValue = 0) then continue;
    if i < 7 then lWeek.addObject(lData);
    if i < 30 then lMonth.addObject(lData);
  end;

  weeklyAverage := lWeek.valueForKeyPath('@avg.self').intValue;
  monthlyAverage := lMonth.valueForKeyPath('@avg.self').intValue;

  //NSLOg('best: %@', Best);
end;

method AppDelegate.save;
begin
  if assigned(Data) then begin
    var lData := new NSMutableData;
    var lArchiver := new NSKeyedArchiver forWritingWithMutableData(lData);
    lArchiver.encodeObject(Data) forKey(KEY_STEP_DATA_BY_DATE);
    lArchiver.encodeObject(DistanceData) forKey(KEY_DISTANCE_DATA_BY_DATE);
    if assigned(LastFinishedDay) then
      lArchiver.encodeObject(LastFinishedDay) forKey(KEY_LAST_FINISHED_DAY);
    lArchiver.finishEncoding();
  
    if lData.writeToFile(fDataFileName) atomically(YES) then
      NSLog('data saved to %@', fDataFileName)
    else
      NSLog('error saving data to %@', fDataFileName)
  end;
end;

method AppDelegate.StepsQueryHandler(numberOfSteps: NSInteger; error: NSError);
begin

end;

method AppDelegate.StepsUpdateHandler(numberOfSteps: NSInteger; timestamp: NSDate; error: NSError);
begin

end;

method AppDelegate.application(application: UIApplication) performFetchWithCompletionHandler(completionHandler: block (fetchResult: UIBackgroundFetchResult));
begin
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), -> begin
    {async} LoadNewDataWithCompletion(-> completionHandler(UIBackgroundFetchResult.UIBackgroundFetchResultNewData));
  end);
end;

end.
