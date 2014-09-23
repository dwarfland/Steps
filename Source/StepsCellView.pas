namespace Steps;

interface

uses
  TwinPeaks,
  UIKit;

type
  [IBObject]
  StepsCellView = public class(TPBaseCell)
  private
  public
    method initWithFrame(aFrame: CGRect): id; override;

    method drawRect(rect: CGRect); override;

    property first: Boolean;
    property date: NSDate;
    property steps: NSNumber;
    property best: Boolean;
  end;

implementation

method StepsCellView.initWithFrame(aFrame: CGRect): id;
begin
  self := inherited initWithFrame(aFrame);
  if assigned(self) then begin

    // Custom initialization

  end;
  result := self;
end;

method StepsCellView.drawRect(rect: CGRect);
begin
  //if first then steps := 10376; // demo data for testing.

  var lFont := if first then UIFont.fontWithName('HelveticaNeue-Light') size(58) else UIFont.systemFontOfSize(26);
  
  var lDayFont := if first then UIFont.systemFontOfSize(26) else UIFont.fontWithName('HelveticaNeue-Light') size(26);
  var lDateFont := UIFont.fontWithName('HelveticaNeue-Light') size(13);

  var lCalendar := NSCalendar.currentCalendar;
  var lUnitFlags := NSCalendarUnit.NSWeekdayCalendarUnit or NSCalendarUnit.NSYearCalendarUnit;
  var lComponents := lCalendar.components(lUnitFlags) fromDate(date);

  var lThisYear := lCalendar.components(NSCalendarUnit.NSYearCalendarUnit) fromDate(date).year;

  var lDiffComponents := lCalendar.components(NSCalendarUnit.NSDayCalendarUnit) fromDate(date) toDate(NSDate.date) options(0); 
  var lOverOneWeek := lDiffComponents.day > 7;

  var lDayFormatter := new NSDateFormatter;
  lDayFormatter.dateFormat := 'EEEE';
  
  var lFarDateFormatter := new NSDateFormatter;
  if lThisYear = lComponents.year then
    lFarDateFormatter.dateFormat := ', MMM dd'
  else
    lFarDateFormatter.dateFormat := ', MMM dd, yyyy';

  var f := frame;

  UIColor.whiteColor.setFill;
  if best then 
    UIColor.colorWithRed(1.0) green(0.9) blue(0.9) alpha(1.0).setFill; 
  UIRectFill(f);

  var lColor          := UIColor.blackColor;
  var lDayColor := case lComponents.weekday of
      1: UIColor.redColor;
      7: UIColor.colorWithRed(0.75) green(0) blue(0) alpha(1.0) ;
      else UIColor.darkGrayColor;
    end;

  var lStepAttributes := new NSMutableDictionary withObjects([lFont, lColor]) 
                                                     forKeys([NSFontAttributeName, NSForegroundColorAttributeName]); 
  var lDayAttributes  := new NSMutableDictionary withObjects([lDayFont, lDayColor]) 
                                                     forKeys([NSFontAttributeName, NSForegroundColorAttributeName]); 
  var lDateAttributes  := new NSMutableDictionary withObjects([lDateFont, lDayColor]) 
                                                      forKeys([NSFontAttributeName, NSForegroundColorAttributeName]); 

  var lDayString := '';
  if first then 
    lDayString := 'Today'
  else
    lDayString := lDayString+lDayFormatter.stringFromDate(date);
  
  var lDaySize := lDayString.sizeWithAttributes(lDayAttributes); 
  var lDayFrame := CGRectMake(5.0, 5.0, lDaySize.width, lDaySize.height);
  lDayString.drawInRect(lDayFrame) withAttributes(lDayAttributes);

  if lOverOneWeek then begin
    var lDayString2 := lFarDateFormatter.stringFromDate(date);
    var lDaySize2 := lDayString2.sizeWithAttributes(lDateAttributes); 
    var lDayFrame2 := CGRectMake(lDayFrame.origin.x+lDayFrame.size.width-3, 18.0, lDaySize2.width, lDaySize2.height);
    lDayString2.drawInRect(lDayFrame2) withAttributes(lDateAttributes);
  end;
  
  var lStepString := steps.stringValue;
  if best and not first then lStepString := '☆ '+lStepString;
  
  var lStepSize := lStepString.sizeWithAttributes(lStepAttributes); 
  var lStepFrame := CGRectMake(f.size.width-5-lStepSize.width, 5.0, lStepSize.width, lStepSize.height);
  lStepString.drawInRect(lStepFrame) withAttributes(lStepAttributes);

  if first then begin

    { separator line }
    UIColor.darkGrayColor.setStroke();
    var lLinePath := UIBezierPath.bezierPath();
    lLinePath.moveToPoint(CGPointMake(5.0, f.size.height-1));
    lLinePath.addLineToPoint(CGPointMake(f.size.width-5.0, f.size.height-1));
    lLinePath.lineWidth := 0.5;
    lLinePath.stroke();

    var lDetailsAttributes  := new NSMutableDictionary withObjects([lDateFont, UIColor.darkGrayColor]) 
                                                           forKeys([NSFontAttributeName, NSForegroundColorAttributeName]); 
    var llEncouragementFont := UIFont.boldSystemFontOfSize(13);
    var llEncouragementAttributes  := new NSMutableDictionary withObjects([llEncouragementFont, UIColor.colorWithRed(0.0) green(0.0) blue(0.75) alpha(1.0)]) 
                                                                  forKeys([NSFontAttributeName, NSForegroundColorAttributeName]); 

    var lWeekly := NSString.stringWithFormat('∅ %@ this week', AppDelegate.instance.weeklyAverage);
    var lWeeklySize := lWeekly.sizeWithAttributes(lDetailsAttributes); 
    var lWeeklyFrame := CGRectMake(5.0, lDayFrame.origin.y+lDayFrame.size.height+5.0, lWeeklySize.width, lWeeklySize.height);
    lWeekly.drawInRect(lWeeklyFrame) withAttributes(lDetailsAttributes);

    var lMonthly := NSString.stringWithFormat('∅ %@ this month', AppDelegate.instance.monthlyAverage);
    var lMonthlySize := lMonthly.sizeWithAttributes(lDetailsAttributes); 
    var lMonthlyFrame := CGRectMake(5.0, lWeeklyFrame.origin.y+lWeeklyFrame.size.height+5.0, lMonthlySize.width, lMonthlySize.height);
    lMonthly.drawInRect(lMonthlyFrame) withAttributes(lDetailsAttributes);

    var lEncouragement := '';

    var lStepsLeft := AppDelegate.instance.best.intValue - steps.intValue;
    if (lStepsLeft > 0) then begin
      if (lStepsLeft < (AppDelegate.instance.best.intValue/8)) then 
        lEncouragement := NSString.stringWithFormat('Only %d steps left to beat your best day!', lStepsLeft)
      else
        lEncouragement := NSString.stringWithFormat('%d steps left to beat your best day!', lStepsLeft);
    end
    else begin
      lEncouragement := 'Today is your best day yet!';
    end;

    var lEncouragementSize := lEncouragement.sizeWithAttributes(llEncouragementAttributes); 
    var x := (f.size.width-lEncouragementSize.width)/2;
    var lEncouragementFrame := CGRectMake(x, lMonthlyFrame.origin.y+lMonthlyFrame.size.height+10.0, lEncouragementSize.width, lEncouragementSize.height);
    lEncouragement.drawInRect(lEncouragementFrame) withAttributes(llEncouragementAttributes);

  end;

end;

end.
