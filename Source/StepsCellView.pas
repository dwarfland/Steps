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
  var lFont := if first then UIFont.boldSystemFontOfSize(26) else UIFont.systemFontOfSize(26);
  var lDayFont := if first then UIFont.systemFontOfSize(26) else UIFont.fontWithName('HelveticaNeue-Light') size(26);

  var lCalendar := NSCalendar.currentCalendar;
  var lUnitFlags := NSCalendarUnit.NSWeekdayCalendarUnit;
  var lComponents := lCalendar.components(lUnitFlags) fromDate(date);

  var lDiffComponents := lCalendar.components(NSCalendarUnit.NSDayCalendarUnit) fromDate(date) toDate(NSDate.date) options(0); 
  var lOverOneWeek := lDiffComponents.day > 7;

  var lNearDateFormatter := new NSDateFormatter;
  lNearDateFormatter.dateFormat := 'EEEE';
  
  var lFarDateFormatter := new NSDateFormatter;
  lFarDateFormatter.dateFormat := 'EEEE, MMM dd';

  var f := frame;

  UIColor.whiteColor.setFill;
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

	var lDayString := '';
  if first then 
    lDayString := 'Today'
  else if lOverOneWeek then
    lDayString := lDayString+lFarDateFormatter.stringFromDate(date)
  else
    lDayString := lDayString+lNearDateFormatter.stringFromDate(date);
  
  var lDaySize := lDayString.sizeWithAttributes(lDayAttributes); 
	var lDayFrame := CGRectMake(5.0, 5.0, lDaySize.width, lDaySize.height);
  lDayString.drawInRect(lDayFrame) withAttributes(lDayAttributes);
  
	var lStepString := steps.stringValue;
  
  var lStepSize := lStepString.sizeWithAttributes(lStepAttributes); 
	var lStepFrame := CGRectMake(f.size.width-5-lStepSize.width, 5.0, lStepSize.width, lStepSize.height);
  lStepString.drawInRect(lStepFrame) withAttributes(lStepAttributes);
end;

end.
