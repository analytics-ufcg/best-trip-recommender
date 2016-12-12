source(paste0(api.folder.path, "/closestTrips.R"))
source(paste0(api.folder.path, "/prediction_module.R"))
source(paste0(api.folder.path, "/feature_factory.R"))
source(paste0(api.folder.path, "/IO_service.R"))

#* @get /get_best_trips
get_best_trips <- function(route, time, date, bus_stop_id, closest_trip_type = "next_hour"){
  get.prediction.data(file = training.data.filepath, time.window = months(3))
  get.trips.schedule()
  check.last.passengers.model.update()
  
  switch(
   closest_trip_type,
   "next_hour" = {
     n.closest.trips <- getNextHourTrips(trips.schedule, route, time, date, bus_stop_id)
   }, 
   {
     n.closest.trips <- getProbableClosestTrips(trips.schedule, route, time, date, bus_stop_id)
   }
  )
  
  if(nrow(n.closest.trips) == 0) {
    return("Rota não encontrada neste dia da semana ou nesta parada")
  }
  
  n.closest.trips <- user.feature.extractor(n.closest.trips, date)

  n.closest.trips <- get.prediction.passengers.number(n.closest.trips, training.method = prediction.method)

  n.closest.trips <- get.prediction.trip.duration(n.closest.trips, training.method = prediction.method)

  return(n.closest.trips)
}

#* @get /train_model
train_model <<- function() {
  get.current.prediction.data(file = training.data.filepath, time.window = months(3))

  trip.duration.model.temp <- train.trip.duration(prediction.data, training.method = prediction.method)
  passengers.number.model.temp <- train.passengers.number(prediction.data, training.method = prediction.method)
  
  trip.duration.model <<- trip.duration.model.temp
  passengers.number.model <<- passengers.number.model.temp
  
  save.models()
  get.last.time.updated.models(force = TRUE)
  return(TRUE)
}

#* @get /
health_check <- function() {
  return(TRUE)
}

init.variables()
print("Loading modules...")
loaded.models <- load.models()
if (!loaded.models) {
    print("Modules could not be loaded. Training models.")
    training.time <- system.time({ train_model() }) 
    print(paste("Training Time:",training.time[3]))
}
