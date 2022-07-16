extends TextureButton

signal date_selected(date)

enum Month { JAN = 1, FEB = 2, MAR = 3, APR = 4, MAY = 5, JUN = 6, JUL = 7,
		AUG = 8, SEP = 9, OCT = 10, NOV = 11, DEC = 12 }


const MONTH_NAME = [ 
	"January", "February", "March", "April", 
	"May", "June", "July", "August", 
	"September", "October", "November", "December"
]

const MONTH_DAYS = [
	31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
]

const WEEKDAY_NAME = [ 
	"Sunday", "Monday", "Tuesday", "Wednesday", 
	"Thursday", "Friday", "Saturday"
]

const MAX_YEAR = 9999
const MIN_YEAR = 1970
onready var popup = $popup
onready var label_month = $popup/form/bg/header/labels/month
onready var label_year = $popup/form/bg/header/labels/year
onready var button_month_prev = $popup/form/bg/header/prev_month
onready var button_month_next = $popup/form/bg/header/next_month
onready var button_year_prev = $popup/form/bg/header/prev_year
onready var button_year_next = $popup/form/bg/header/next_year
onready var days = $popup/form/days

var day = 1
var month = 1
var year = 1970
var weekday = 0
var dst = 0
var is_open = false


func _ready():
	# Set to today's date
	var date = OS.get_date()
	month = date["month"]
	year = date["year"]
	day = date["day"]
	dst = date["dst"]
	weekday = date["weekday"]
	connect("pressed", self, "_show_popup")
	button_month_prev.connect("pressed", self, "_goto_prev_month")
	button_month_next.connect("pressed", self, "_goto_next_month")
	button_year_prev.connect("pressed", self, "_goto_prev_year")
	button_year_next.connect("pressed", self, "_goto_next_year")
	popup.connect("popup_hide", self, "set_open", [false])
	setup_day_buttons()


func set_open(value):
	is_open = value


func _show_popup():
	if is_open:
		popup.hide()
		is_open = false
		return
	
	label_month.set_text(MONTH_NAME[month-1])
	label_year.set_text(str(year))
	popup.set_position(get_global_position()+Vector2(40, 40))
	popup.popup()
	is_open = true


func set_year(value):
	year = value
	

func _goto_next_month():
	if month < 12:
		month += 1
		weekday = MONTH_DAYS[month-1] % 7
	else:
		if year >= MAX_YEAR:
			return
		month = 1
		year += 1
	label_month.set_text(MONTH_NAME[month-1])
	label_year.set_text(str(year))
	setup_day_buttons()


func _goto_prev_month():
	if month > 1:
		month -= 1
		weekday = MONTH_DAYS[month-1] % 7
	else:
		if year <= MIN_YEAR:
			return
		month = 12
		year -= 1
	label_month.set_text(MONTH_NAME[month-1])
	label_year.set_text(str(year))
	setup_day_buttons()


func _goto_next_year():
	year = clamp(year+1, MIN_YEAR, MAX_YEAR)
	label_year.set_text(str(year))
	setup_day_buttons()


func _goto_prev_year():
	year = clamp(year-1, MIN_YEAR, MAX_YEAR)
	label_year.set_text(str(year))
	setup_day_buttons()


func get_weekday(date):
	# See ref for details: https://artofmemory.com/blog/how-to-calculate-the-day-of-the-week/
	# Only works for Gregorian calendar
	var day = date["day"]
	var month = date["month"]
	var year = date["year"]
	var is_leap_year = false
	if year % 4 == 0:
		is_leap_year = year % 400 == 0 or year % 100 == 0
	var yy = int(str(year).right(2))	# get last 2 digits in year
	var year_code = fmod((yy + floor(yy / 4)), 7.0)
	var month_code = [0, 3, 3, 6, 1, 4, 6, 2, 5, 0, 3, 5][month-1]
	var century_code = [4, 2, 0, 6, 4, 2, 0][floor(year/100)-17] # -17 because start with 1700
	var leap_year_code = -1 if is_leap_year and month < 2 else 0
#	print("year code: ", year_code, "\nmonth code: ", month_code, "\ncentury_code: ", century_code, "\nleap code: ", leap_year_code, "\nday: ", day)
	return fmod((year_code + month_code + century_code + day + leap_year_code), 7)


func setup_day_buttons():
	var days_in_month = MONTH_DAYS[month-1]
	var date = {"day": 1, "month": month, "year": year}
	var first_weekday_month = get_weekday(date)
#	print("weekday for {month}/{day}/{year}: ".format(date), get_weekday(date))
	clear_buttons()
	var iter = 1
	for i in range(first_weekday_month, first_weekday_month+days_in_month):
		var button = days.get_child(7+i) # +7 for labels
		button.set_text(str(iter))
		if button.is_connected("pressed", self, "emit_signal"):
			button.disconnect("pressed", self, "emit_signal")
		button.connect("pressed", self, "emit_signal", ["date_selected", {"day": iter, "month": month, "year": year}])
		if i == day:
			button.set_pressed(true)
		iter += 1


func clear_buttons():
	for i in range(7, days.get_child_count()):
		var button = days.get_child(i)
		button.set_text("")
