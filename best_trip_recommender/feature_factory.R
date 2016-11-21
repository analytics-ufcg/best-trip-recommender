# Features to predict:
# Duration
# total.passengers

# Features used to predict:
# route
# date
# week.day
# day.type
# trip.initial.time (departure)
# trip.final.time (arrival)
# group.15.minutes
# difference.next.timetable
# difference.previous.timetable

# In order to install bestBus package, uncomment and run the following lines:
# install.packages("devtools")
# library(devtools)
# install_github("analytics-ufcg/bestBus")

library(bestBus)
library(lubridate)

calculate.error <- function(previous.time, next.time) {
  previous.time.in.seconds <- period_to_seconds(hms(previous.time))
  next.time.in.seconds <- period_to_seconds(hms(next.time))
  amplitude.in.minutes <- (period_to_seconds(hms(next.time)) - period_to_seconds(hms(previous.time))) / 60
  error <- amplitude.in.minutes / 2
  return(error)
}

day.type <- function(date) {
  week.day <- weekdays(as.Date(date))
  ifelse(week.day == "Sunday", "SUN", 
  ifelse(week.day == "Monday", "MON",
  ifelse(week.day == "Tuesday" | week.day == "Wednesday" | week.day == "Thursday", "TUE WED THU",
  ifelse(week.day == "Friday", "FRI",
  "SAT"))))
}

closest.trip.feature.extractor <- function(whole.dataset) {
  whole.dataset <- whole.dataset %>%
    mutate(
      grouped.timetable = bestBus::group_minutes(mean.timetable, 15),
      error = calculate.error(as.character(previous.timetable), as.character(next.timetable)),
      time.in.seconds = period_to_seconds(hms(mean.timetable))
    )

  return(whole.dataset)
}

prediction.feature.extractor <- function(file) {
  dataset <- read.csv(file)
  
  dataset <- dataset %>%
    dplyr::rename(
      trip.initial.time = departure,
      trip.final.time = arrival,
      difference.previous.timetable = difference.previous.schedule,
      difference.next.timetable = difference.next.schedule,
      grouped.timetable = group.15.minutes
     ) %>%
    dplyr::select(
      route,
      date,
      week.day,
      trip.initial.time,
      trip.final.time,
      grouped.timetable,
      difference.previous.timetable,
      difference.next.timetable,
      total.passengers,
      duration
    ) %>%
    dplyr::mutate(
      day.type = day.type(date),
      date = as.Date(date)
      )
  
  dataset$day.type = as.factor(dataset$day.type)
  
  return(dataset)
}

user.feature.extractor <- function(n.probable.trips, date) {
  n.probable.trips <- n.probable.trips %>%
    dplyr::mutate(
      date = as.Date(date),
      week.day = weekdays(as.Date(date, "%Y-%m-%d")),
      difference.previous.timetable = as.integer((time.in.seconds - lag(time.in.seconds)) / 60),
      difference.next.timetable = as.integer((lead(time.in.seconds) - time.in.seconds) / 60),
      grouped.timetable = period_to_seconds(hms(grouped.timetable)),
      difference.next.timetable = ifelse(is.na(difference.next.timetable), -1, difference.next.timetable),
      difference.previous.timetable = ifelse(is.na(difference.previous.timetable), -1, difference.previous.timetable)
    ) %>%
    dplyr::select(
      route,
      date,
      week.day,
      trip.initial.time,
      trip.final.time,
      grouped.timetable,
      difference.previous.timetable,
      difference.next.timetable,
      day.type,
      mean.timetable,
      time.difference
    )
  
  n.probable.trips <- get.surrounding.trips(n.probable.trips)
  
  n.probable.trips$date <- as.Date(n.probable.trips$date, "%d-%m-%Y")
  n.probable.trips$week.day <- as.factor(n.probable.trips$week.day)
  
  return(n.probable.trips)
}

get.surrounding.trips <- function(trips) {
  closest.row <- which.min(trips$time.difference)
  number.rows = nrow(trips)
  if (number.rows == 3) {
    if(closest.row == 1) {
      row.trips = seq(closest.row, closest.row + 1)
    } else {
      row.trips = seq(closest.row - 1, closest.row)
    }
  } else {
    row.trips = seq(closest.row - 1, closest.row + 1)
  }
  
  trips <- trips %>%
    mutate(row = row_number()) %>%
    filter(row %in% row.trips) %>%
    select(-row)
  
  return(trips)
}
