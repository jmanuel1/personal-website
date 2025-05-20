' Works in Just BASIC v2
' The state is not reset at the beginning of [input], so generating more than
' one calendar in a single run of the program is bugged. (The calendars will be
' appended to each other and month names will carry over between calendars.)

newline$ = chr$(13) + chr$(10)
PrinterFont$ = "courier_new 10"

[input]
  input "Please enter length of year (earth days): "; year 'length of year in earth days
  input "Length of day (earth hours): "; day 'length of day in earth hours
  input "Number of months: "; months 'number of months in year
  months = int(months)
  for i = 1 to months
    input "Name of month " + str$(i) + ": "; name$
    names$ = names$ + name$ + " "
  next i
  input "Days per week (planet days): "; weeks 'length of week in planet days
  day = day/24 'length of day from earth hours to earth days
  numOfDays = year/day 'days per year
  lenMonths = int(numOfDays/months) 'days per month
  unaccountedDays = numOfDays - (months * lenMonths)
  backup1 = unaccountedDays
  leftoverTime = unaccountedDays - int(unaccountedDays)
  if (unaccountedDays <> 0) then
    print "Months will have unequal lengths."
  end if
  if (leftoverTime <> 0) then
    print "Leap year will be created."
    leapYear = 1
  end if
  i = 0

[calender.generation]
  i = i + 1
  currDay = 0
  currMonthExtraDays = 0
  if (unaccountedDays >= 1) then
    currMonthExtraDays = 1
    unaccountedDays = unaccountedDays - currMonthExtraDays
  end if
  calender$ = calender$ + "Month: " + word$(names$, i) + newline$
  while (currDay < lenMonths + currMonthExtraDays)
    currDay = currDay + 1
    calender$ = calender$ + " " + str$(currDay)
    if (currDay mod weeks < 1) then
      calender$ = calender$ + newline$
    end if
  wend
  calender$ = calender$ + newline$ + newline$ + newline$
  if (i < months) then
    goto [calender.generation]
  end if
  if (leapYear = 0) then
    print calender$
    print
    input "Would you like to print this calender? (y/n) " ; print$
    if (print$ = "y") then
      lprint calender$
      dump
    end if
    goto [input]
  end if

[leapYear]
  i = 0
  tmp = .1
  while (tmp <> int(tmp))
    i = i + 1
    tmp = leftoverTime * i
  wend
  calender$ = calender$ + "Leap year: every " + str$(i) + " years" + newline$
  i = 0
  unaccountedDays = backup1
  unaccountedDays = unaccountedDays + tmp

[lyCal]
  i = i + 1
  currDay = 0
  currMonthExtraDays = 0
  if (unaccountedDays >= 1) then
    currMonthExtraDays = 1
    unaccountedDays = unaccountedDays - currMonthExtraDays
  end if
  calender$ = calender$ + "Month: " + word$(names$, i) + newline$
  while (currDay < lenMonths + currMonthExtraDays)
    currDay = currDay + 1
    calender$ = calender$ + " " + str$(currDay)
    if (currDay mod weeks < 1) then
      calender$ = calender$ + newline$
    end if
  wend
  calender$ = calender$ + newline$ + newline$ + newline$
  if (i < months) then
    goto [lyCal]
  end if
  print calender$
  input "Would you like to print this calender? (y/n) " ; print$
  if (print$ = "y") then
    lprint calender$
    dump
  end if
  goto [input]
