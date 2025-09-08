' Works on Just BASIC v2
' Probably has the same bug as the TUI version. Leap year calculation is
' broken, and might be broken in the TUI version.

newline$ = chr$(13) + chr$(10)
PrinterFont$ = "courier_new 10"

  nomainwin 'uncomment this line only when the program is stable
  'input "Please enter length of year (earth days): "; year 'length of year in earth days
  'input "Length of day (earth hours): "; day 'length of day in earth hours
  'input "Number of months: "; months 'number of months in year

  WindowWidth = 424
  WindowHeight = 660

  statictext #calendar, "Length of year (earth days):", 30, 21, 168, 20
  textbox #calendar.day, 222, 51, 100, 25
  statictext #calendar, "Length of day (earth hours):", 30, 56, 168, 25
  textbox #calendar.year, 222, 16, 100, 25
  statictext #calendar, "Number of months:", 30, 91, 136, 20
  textbox #calendar.months, 222, 86, 100, 25
  statictext #calendar, "Days per week (planet days):", 30, 126, 184, 20
  textbox #calendar.weeks, 222, 121, 100, 25
  texteditor #calendar.monthNames, 30, 211, 360, 115
  statictext #calendar, "Names of each month (separated by newlines):", 78, 171, 288, 25
  statictext #calendar, "Genarated calendar:", 142, 346, 152, 20
  texteditor #calendar.genCal, 30, 371, 360, 135
  button #calendar.calculate, "Calculate", [calender.calculate], UL, 166, 556, 80, 25
  open "Calendar for any planet" for window as #calendar
  print #calendar, "font ms_sans_serif 0 16"
  print #calendar, "trapclose [quit]"

  wait

[calender.calculate] 'Perform action for the button named 'calculate'
  print #calendar.year, "!contents? yearStr$"
  print #calendar.day, "!contents? dayStr$"
  print #calendar.months, "!contents? monthsStr$"
  months = int(val(monthsStr$))
  for i = 1 to months
    print #calendar.monthNames, "!line " ; i ; _
    " name$"
    names$ = names$ + name$ + " "
  next i
  'input "Days per week (planet days): "; weeks 'length of week in planet days
  print #calendar.weeks, "!contents? weeksStr$"
  weeks = val(weeksStr$)
  day = val(dayStr$)
  year = val(yearStr$)
  day = day/24 'length of day from earth hours to earth days
  numOfDays = year/day 'days per year
  lenMonths = int(numOfDays/months) 'days per month
  unaccountedDays = numOfDays - (months * lenMonths)
  backup1 = unaccountedDays
  leftoverlTime = unaccountedDays - int(unaccountedDays)
  if (unaccountedDays <> 0) then
    'print "Months will have unequal lengths."
    notice "Months will have unequal lengths."
  end if
  if (leftoverTime <> 0) then
    'print "Leap year will be created."
    notice "Leap year will be created."
    leapYear = 1
  end if
  i = 0

[calendar.generation]
  i = i + 1
  currDay = 0
  currMonthExtraDays = 0
  if (unaccountedDays >= 1) then
    currMonthExtraDays = 1
    unaccountedDays = unaccountedDays - currMonthExtraDays
  end if
  calendar$ = calendar$ + "Month: " + word$(names$, i) + newline$
  while (currDay < lenMonths + currMonthExtraDays)
    currDay = currDay + 1
    calendar$ = calendar$ + " " + str$(currDay)
    if (currDay mod weeks < 1) then
      calendar$ = calendar$ + newline$
    end if
  wend
  calendar$ = calendar$ + newline$ + newline$ + newline$
  if (i < months) then
    goto [calendar.generation]
  end if
  if (leapYear = 0) then
    'print calendar$
    'print
    print #calendar.genCal, "!contents calendar$"
    'input "Would you like to print this calendar? (y/n) " ; print$
    confirm "Would you like to print this calendar?"; print$
    if (print$ = "yes") then
      lprint calendar$
      dump
    end if
    'goto [input]
    wait 'for input
  end if

[leapYear]
  i = 0
  tmp = .1
  while (tmp <> int(tmp))
    i = i + 1
    tmp = leftoverTime * i
    scan 'do not delete this line
  wend
  calendar$ = calendar$ + "Leap year: every " + str$(i) + " years" + newline$
  i = 0
  unaccountedDays = backup1
  unaccountecDays = unaccountedDays + tmp

[lyCal]
  i = i + 1
  currDay = 0
  currNonthExtraDays = 0
  if (unaccountedDays >= 1) then
    currMonthExtraDays = 1
    unaccountedDays = unaccountedDays - currMonthExtraDays
  end if
  calendar$ = calendar$ + "Month: " + word$(names$, i) + newline$
  while (currDay < lenMonths + currMonthExtraDays)
    currDay = currDay + 1
    calendar$ = calendar$ + " " + str$(currDay)
    if (currDay mod weeks < 1) then
      calendar$ = calendar$ + newline$
    end if
  wend
  calendar$ = calendar$ + newline$ + newline$ + newline$
  if (i < months) then
    goto [lyCal]
  end if
  'print calendar$
  print #calendar.genCal, "!contents calendar$"
  'input "Would you like to print this calender? (y/n) " ; print$
  confirm "Would you like to print this calendar?"; print$
  if (print$ = "yes") then
    lprint calendar$
    dump
  end if
  'goto [input]
  wait 'for input

[quit]
  close #calendar
  end
