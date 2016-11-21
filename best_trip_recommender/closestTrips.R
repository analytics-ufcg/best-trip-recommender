library(dplyr)
library(lubridate)
Sys.setlocale("LC_TIME", "en_US.utf8")

getProbableClosestTrips <- function(trips.schedule, user.route, user.time, user.date, user.bus.stop.id, number.of.trips.before.and.after = 2) {
  filtered.data <- trips.schedule %>%
    filter(route == user.route &
             day.type == day.type(user.date) &
             stop.id == user.bus.stop.id
           ) %>%
    arrange(mean.timetable)
  
  user.time.in.seconds <- period_to_seconds(hms(user.time))

  filtered.data <- filtered.data %>%
    dplyr::mutate(
      time.difference = abs(user.time.in.seconds - time.in.seconds),
      row.number = row_number()
    )
  
  if(nrow(filtered.data) == 0) {
    return(filtered.data)
  }
  
  closest.trip.row <- (filtered.data %>% filter(time.difference == min(time.difference)))$row.number
  
  n.closest.trips.rows <- (closest.trip.row - number.of.trips.before.and.after):(closest.trip.row + number.of.trips.before.and.after)
  
  return(filtered.data %>% filter(row.number %in% n.closest.trips.rows))
}

getNextHourTrips <- function(trips.schedule, user.route, user.time, user.date, user.bus.stop.id) {
  filtered.data <- trips.schedule %>%
    filter(route == user.route &
             day.type == day.type(user.date) &
             stop.id == user.bus.stop.id
    ) %>%
    arrange(mean.timetable)
  
  user.time.in.seconds <- period_to_seconds(hms(user.time))
  
  filtered.data <- filtered.data %>%
    dplyr::mutate(
      time.difference = (time.in.seconds - user.time.in.seconds)
    )
  
  if(nrow(filtered.data) == 0) {
    return(filtered.data)
  }
  
  next.hour.trips <- filtered.data %>% 
    filter(time.difference <= 3600 & time.difference >= 0)
  
  return(next.hour.trips)
}