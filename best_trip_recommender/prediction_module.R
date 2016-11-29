library(caret)
#library(doMC)
#registerDoMC(cores = 3)

check.last.passengers.model.update <- function() {
  get.last.time.updated.models()
  if (file.info(model.data.filepath)$mtime > last.time.updated.models) {
    load.models()
    get.last.time.updated.models(force = TRUE)
  }
}

train.passengers.number <- function(training.data, training.method) {
  passengers.number.model <- train(
    form = total.passengers ~ route + date + week.day + day.type + grouped.timetable + difference.next.timetable + difference.previous.timetable,
    data = training.data,
    method = training.method,
	na.action = na.omit,
    trControl = trainControl(method="cv",number=10)
  )
  return(passengers.number.model)
}

predict.passengers.number <- function(prediction.dataset) {
  passengers.number.prediction <- predict(passengers.number.model, prediction.dataset)
  return(passengers.number.prediction)
}

get.prediction.passengers.number <- function(n.closest.trips, training.method) {
  if (!exists("passengers.number.model") || is.null(passengers.number.model)) {
    tryCatch({
      load.models()
    }, warning = function(war) {
    }, error = function(err) {
      passengers.number.model <<- train.passengers.number(prediction.data, training.method)  
    }, finally = {
    })  
  } 
  
  n.closest.trips$passengers.number <- predict.passengers.number(n.closest.trips)
  return(n.closest.trips)
}

train.trip.duration <- function(training.data, training.method) {
  trip.duration.model <- train(
    form = duration ~ route + date + week.day + day.type + grouped.timetable + difference.next.timetable + difference.previous.timetable,
    data = training.data,
    method = training.method,
	na.action = na.omit,
    trControl = trainControl(method="cv",number=10)
  )
  return(trip.duration.model)
}

predict.trip.duration <- function(prediction.dataset) {
  trip.duration.prediction <- predict(trip.duration.model, prediction.dataset)
  return(trip.duration.prediction)
}

get.prediction.trip.duration <- function(n.closest.trips, training.method) {
  if (!exists("trip.duration.model") || is.null(trip.duration.model)) {
    tryCatch({
      load.models()
    }, warning = function(war) {
    }, error = function(err) {
      trip.duration.model <<- train.trip.duration(prediction.data, training.method)
    }, finally = {
    }) 
  } 
  n.closest.trips$trip.duration <- predict.trip.duration(n.closest.trips)
  return(n.closest.trips)
}
