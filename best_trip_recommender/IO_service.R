hash.code <- function() {
  alpha.numeric = c('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0')
  
  hash <- paste(sample(alpha.numeric, 20, replace = TRUE), collapse = "")
  return(hash)
}

save.models <- function() {
  hash <- hash.code()
  splitted.filename <- strsplit(model.data.filepath, "[.]")
  filename <- paste0(splitted.filename[[1]][1:length(splitted.filename)], hash, ".", splitted.filename[[1]][-1])
  save(passengers.number.model, trip.duration.model, file = filename)
  file.rename(from = filename, to = model.data.filepath)
}

load.models <- function() {
  loaded.models <- 
      tryCatch({
        attach(model.data.filepath)
        load(model.data.filepath)
        ge <- globalenv()
        ge$passengers.number.model <- passengers.number.model
        ge$trip.duration.model <- trip.duration.model
        #detach(paste0("file:", model.data.filepath), unload = TRUE)
        print("Loaded modules correctly")
        return(TRUE)
      }, warning = function(war) {
      }, error = function(err) {
        print("Could not load modules.")
        return(FALSE)
      }, finally = {
      })
  return(loaded.models)
}

get.last.time.updated.models <- function(force = FALSE) {
  if (!exists("last.time.updated.models") || is.null(last.time.updated.models) || force) {
    last.time.updated.models <<- file.info(model.data.filepath)$mtime
  }
}

get.prediction.data <- function(file = training.data.filepath, time.window = weeks(1)) {
  if(!exists("prediction.data") || is.null(prediction.data)) {
    get.current.prediction.data(file, time.window)
  }
}

get.current.prediction.data <- function(file = training.data.filepath, time.window = weeks(1)) {
  temp <- prediction.feature.extractor(file)
  
  limit.date <- max(temp$date) %m-% time.window
  
  temp$route <- as.factor(temp$route)
  
  temp <- temp %>% 
    filter(date > limit.date)
  
  temp$route <- droplevels(temp$route)
  
  prediction.data <<- temp
}

get.trips.schedule <- function(file = test.metadata.filepath) {
  if(!exists("trips.schedule") || is.null(trips.schedule)) {
    trips.schedule <<- getTripsSchedule(file)
  }
}

getTripsSchedule <- function(file) {
  data <- read.csv(file)
  
  data <- data %>%
    dplyr::rename(
      route = rota,
      day.type = tipo_dia,
      stop.id = id_parada,
      mean.timetable = horario_medio,
      previous.timetable = horario_anterior,
      next.timetable = horario_posterior,
      trip.initial.time = inicio_viagem,
      trip.final.time = fim_viagem
    )
  
  data <- closest.trip.feature.extractor(data)
  
  return(data)
}

init.variables <- function() {
  get.prediction.data(file = training.data.filepath, time.window = months(3))
  get.trips.schedule()
  get.last.time.updated.models()
}
