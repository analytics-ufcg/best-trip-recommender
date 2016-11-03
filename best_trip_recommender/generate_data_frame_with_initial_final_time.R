library(plyr)
library(dplyr)
library(lubridate)

melhor.busao.schedules.campina <-
  read.csv(
    "~/Analytics/busmonitor/R/best_trip_recommender/melhor_busao_schedules_campina.csv"
  )

generate.model.final.data <- function(schedules.data.frame) {
  schedules.data.frame <-
    identify_first_stops(schedules.data.frame) %>%
    mark_stop_type() %>%
    adjust_stop_type() %>%
    set_trip_initial_final_time() %>%
    select(-primeira_parada,-tipo_parada)
  return(schedules.data.frame)
}

# Identifica e acrescenta ao data frame o id da primeira parada de cada viagem para cada rota
identify_first_stops <- function(schedules.data.frame) {
  first.stop <- 1
  firt.stop.per.route <-
    ddply(melhor.busao.schedules.campina, "rota", head, first.stop) %>%
    select(rota, id_parada) %>% dplyr::rename(primeira_parada = id_parada)
  schedules.with.first.stop <-
    merge(schedules.data.frame, firt.stop.per.route, by = "rota")
  return(schedules.with.first.stop)
}

initial <<- "inicial"
final <<- "final"
ordinary <<- "normal"

# Marca as paradas como inicial, final ou normal
mark_stop_type <- function(schedules.data.frame) {
  schedules.data.frame %>% group_by(rota, tipo_dia) %>%
    mutate(
      tipo_parada = ifelse(
        id_parada == primeira_parada | lead(id_parada) == primeira_parada,
        ifelse(
          lead(id_parada) != primeira_parada,
          initial,
          ifelse(lead(id_parada, 2) != primeira_parada,
                 final,
                 ordinary)
        ),
        ordinary
      )
    ) %>%
    adjust_stop_type()
}

# Ajusta os valores NA na coluna tipo_parada para os valores corretos
adjust_stop_type <- function(schedules.data.frame) {
  schedules.data.frame %>% group_by(rota, tipo_dia) %>%
    mutate(tipo_parada = ifelse(
      is.na(tipo_parada),
      ifelse(is.na(lag(tipo_parada)),
             final,
             ordinary),
      tipo_parada
    ))
}

#  Define, para cada parada, o horário inicial e final da viagem
set_trip_initial_final_time <- function(schedules.data.frame) {
  schedules.data.frame %>%
    group_by(rota, tipo_dia) %>%
    set_trip_initial_time() %>%
    set_trip_final_time()
}

# Define, para cada parada, o horário inicial da viagem
set_trip_initial_time <- function(route.schedules) {
  route.schedules["horario_medio"] <-
    lapply(route.schedules["horario_medio"], as.character)
  for (i in 1:nrow(route.schedules)) {
    if (route.schedules[i, "tipo_parada"] == initial) {
      current.initial.time <- route.schedules[i, "horario_medio"]
    }
    route.schedules$inicio_viagem[i] <- current.initial.time
  }
  return(route.schedules)
}

# Define, para cada parada, o horário inicial da viagem
set_trip_final_time <- function(route.schedules) {
  route.schedules["horario_medio"] <-
    lapply(route.schedules["horario_medio"], as.character)
  for (i in nrow(route.schedules):1) {
    if (route.schedules[i, "tipo_parada"] == final) {
      current.final.time <- route.schedules[i, "horario_medio"]
    }
    route.schedules$fim_viagem[i] <- current.final.time
  }
  return(route.schedules)
}

prediction.model.data <-
  generate.model.final.data(melhor.busao.schedules.campina)

write.csv(prediction.model.data, "prediciton_model_data.csv", row.names = FALSE)

# _________________ testes ___________________ #

schedules.one.route <- melhor.busao.schedules.campina %>% filter(rota == "003B")

schedules.one.route <- schedules.one.route %>% generate.model.final.data()

test_initial_time <- function(row) {
  mean.time <- period_to_seconds(hms(row$horario_medio))
  initial.time <- period_to_seconds(hms(row$iniicio_viagem))
  return(ifelse(mean.time >= initial.time, TRUE, FALSE))
}

test.result <- apply(schedules.one.route, 1, test_initial_time())
