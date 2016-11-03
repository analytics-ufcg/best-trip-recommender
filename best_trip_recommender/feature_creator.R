library(dplyr)
library(bestBus)
library(lubridate)

# To use this function the inputfile must contain the following structure:
# route,date,departure,arrival,total.passengers
# 0500,2016-09-16,10:20:00,10:50:00,50
# 0500,2016-09-16,10:15:00,10:45:00,40
# 263A,2016-09-16,09:15:00,10:13:00,75
# 263A,2016-09-16,10:15:00,11:13:00,90
#
# route - string of bus route
# date - date in format YYYY-mm-dd
# departure - time in format HH:MM:SS
# arrival - time in format HH:MM:SS
# total.passengers - integer of number of passengers
feature_creator <- function(inputfile, outputfile) {
  input <- read.csv(inputfile, colClasses=c("route"="character", 
                                            "date"="Date",
                                            "departure"="character",
                                            "arrival"="character",
                                            "total.passengers"="integer"))
  
  output <- input %>%
    select(
      route,
      date,
      departure,
      arrival,
      total.passengers
    ) %>%
    arrange(route, date, departure) %>%
    group_by(route, date) %>%
    mutate(
      week.day = weekdays(as.Date(date)),
      group.15.minutes = bestBus::group_minutes(departure, 15),
      duration = bestBus::time_difference(arrival, departure),
      difference.previous.schedule = ifelse(lag(route) == route, bestBus::time_difference(departure, lag(departure)), NA),
      difference.next.schedule = ifelse(lead(route) == route, bestBus::time_difference(lead(departure), departure), NA),
      departure = lubridate::period_to_seconds(hms(departure)),
      arrival = lubridate::period_to_seconds(hms(arrival))
    )
  
  write.csv(file = outputfile, x = output, row.names = FALSE)
}