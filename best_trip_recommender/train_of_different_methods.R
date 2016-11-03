Sys.setlocale("LC_TIME","en_US.utf8")

library(caret)
library(dplyr)
library(ggplot2)
library(resample)
library(reshape2)
library(lubridate)

# Separa o dataset em uma parte para treino e outra para teste
split.dataset <- function(dataset, train.percent) {
  splitted.dataset <- list()
  
  train.size <- nrow(dataset) * train.percent
  train.rows <- sample(nrow(dataset),train.size)
  splitted.dataset$train.set <-
    dataset %>% filter(row_number() %in% train.rows)
  splitted.dataset$test.set <-
    dataset %>% filter(!(row_number() %in% train.rows))
  
  return(splitted.dataset)
}

# Categoriza os dias da semanas em determinados grupos quando possuem características semelhantes.
day.type <- function(date) {
  week.day <- weekdays(as.Date(date))
  #print(week.day)
  ifelse(week.day == "Sunday", "SUN",
         ifelse(
           week.day == "Monday", "MON",
           ifelse(
             week.day == "Tuesday" |
               week.day == "Wednesday" |
               week.day == "Thursday", "TUE WED THU",
             ifelse(week.day == "Friday", "FRI",
                    "SAT")
           )
         ))
}

get.duration.model.formula <- function() {
  duration.formula <-
    duration ~ route + date + week.day + day.type + grouped.timetable + difference.next.timetable + difference.previous.timetable  
}

get.num.passengers.model.formula <- function() {
  num.passengers.formula <-
    total.passengers ~ route + date + week.day + day.type + grouped.timetable + difference.next.timetable + difference.previous.timetable  
}

train.model <- function(input.data, num.rounds, train.perc, formula, training.methods) {

  results.data <- data.frame()

  for (i in 1:num.rounds) {
    #Split data
    splitted.dataset <- split.dataset(input.data, train.perc)
    train.set <- splitted.dataset$train.set
    test.set <- na.omit(splitted.dataset$test.set)
    
    control <- trainControl(method = "cv", number = 10)
    
    if ("knn" %in% training.methods) {
      results.data <- rbind(results.data,trainKNN(control,train.set,test.set,formula))
      
    }
    if ("svm" %in% training.methods) {
      results.data <- rbind(results.data,trainSVM(control,train.set,test.set,formula))
      
    }
    if ("rf" %in% training.methods) {
      results.data <- rbind(results.data,trainRandomForest(control,train.set,test.set,formula))
      
    }
    if ("lasso" %in% training.methods) {
      results.data <- rbind(results.data,trainLasso(control,train.set,test.set,formula))
      
    }
    if ("gbm" %in% training.methods) {
      results.data <- rbind(results.data,trainGBM(control,train.set,test.set,formula))
    }
  }
  return(results.data)
}

trainKNN <- function(control,train.set,test.set,formula) {
  tt.knn <<-
    system.time({
      fit.knn <-
        train(
          form = formula,
          data = train.set,
          method = "knn",
          trControl = control,
          allowParallel = TRUE
        )
    })
  
  predict.test.knn <- predict(fit.knn, newdata = test.set)
  
  rmse.knn <- data.frame(model = "knn",
                         mae = mean(abs(predict.test.knn - test.set$duration)),
                         tt = tt.knn[3])
  
  return(rmse.knn)
}

trainSVM <- function(control,train.set,test.set,formula) {
  tt.svm <<-
    system.time({
      fit.svm <-
        train(
          form = formula,
          data = train.set,
          method = "svmRadial",
          preProc = c("center","scale"),
          trControl = control,
          allowParallel = TRUE
        )
    })
  
  predict.test.svm <- predict(fit.svm, newdata = test.set)
  
  rmse.svm <- data.frame(model = "svm",
                         mae = mean(abs(predict.test.svm - test.set$duration)),
                         tt = tt.svm[3])
  
  return(rmse.svm)
}

trainRandomForest <- function(control,train.set,test.set,formula) {
  tt.rf <<-
    system.time({
      fit.rf <-
        train(
          form = formula,
          data = train.set,
          method = "rf",
          trControl = control,
          ntree = 10,
          importance = TRUE,
          prox = TRUE,
          allowParallel = TRUE
        )
    })
  
  predict.test.rf <- predict(fit.rf, newdata = test.set)
  
  rmse.rf <- data.frame(model = "rf",
                        mae = mean(abs(predict.test.rf - test.set$duration)),
                        tt = tt.rf[3])
  
  return(rmse.rf)
}

trainLasso <- function(control,train.set,test.set,formula) {
  tt.lasso <<-
    system.time({
      fit.lasso <-
        train(
          form = formula,
          data = train.set,
          method = "lasso",
          preProc = c("center","scale"),
          trControl = control
        )
    })
  
  predict.test.lasso <- predict(fit.lasso, newdata = test.set)
  
  rmse.lasso <- data.frame(model = "lasso",
                           mae = mean(abs(predict.test.lasso - test.set$duration)),
                           tt = tt.lasso[3])
  
  return(rmse.lasso)
}

trainGBM <- function(control,train.set,test.set,formula) {
  tt.gbm <<-
    system.time({
      fit.gbm <-
        train(
          form = form.duration,
          data = train.set,
          method = "gbm",
          preProc = c("center","scale"),
          trControl = control
        )
    })
  
  predict.test.gbm <- predict(fit.gbm, newdata = test.set)
  
  rmse.gbm <- data.frame(model = "gbm",
                         mae = mean(abs(predict.test.gbm - test.set$duration)),
                         tt = tt.gbm[3])
  
  return(rmse.gbm)
}

plot_results <- function(results, variable_name, data_amount) {
    results.melt <- melt(results, id.vars = c("model"))
    
    results.cis <- results.melt %>%
        group_by(model,variable) %>%
        do(as.data.frame(CI.percentile(bootstrap(.,mean(
            value
        )))))
    
    names(results.cis) <- c("model","variable","lower","upper")
    results.cis <- results.cis %>% mutate(mean = mean(c(lower,upper)))
    
    mae.cis <- results.cis %>%
        filter(variable == "mae") %>%
        ggplot(aes(
            x = model, y = mean, colour = factor(model)
        )) +
        geom_point() +
        geom_errorbar(aes(ymin = lower, ymax = upper)) +
        ggtitle(paste("MAE - Variable: ", variable_name, ", data amount: ", data_amount)) +
        labs(x = "Model",y = "MAE")
    print(mae.cis)
    
    tt.cis <- results.cis %>%
        filter(variable == "tt") %>%
        ggplot(aes(
            x = model, y = mean, colour = factor(model)
        )) +
        geom_point() +
        geom_errorbar(aes(ymin = lower, ymax = upper)) +
        ggtitle(paste("MAE - Variable: ", variable_name, ", data amount: ", data_amount)) +
        labs(x = "Model",y = "Training Time (in seconds)")
    print(tt.cis)
}

preprocess.data <- function(collected.data, num.weeks) {
    collected.data$date <- as.Date(collected.data$date)
    
    # Escolha os dados mudando essa função Por exemplo, para selecionar 1 semana de dados coloque "weeks(1)"
    limit.date <- max(collected.data$date) %m-% weeks(num.weeks)
    input.data <<- collected.data %>%
        filter(date > limit.date)
    
    input.data <- input.data %>%
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
        dplyr::mutate(day.type = day.type(date),
                      date = as.Date(date))
    
    input.data$day.type = as.factor(input.data$day.type)
    
    return(input.data)
}

########################## MAIN CODE ###################################

# Pegando dados
collected.data <-
  read.csv("data/curitiba/prediction_data_ctba.csv", stringsAsFactors = FALSE)

input.data <- preprocess.data(collected.data,num.weeks=3)

#Experiment
training.results.duration <- train.model(input.data,num.rounds=3,train.perc=0.8,get.num.passengers.model.formula(),"lasso")
plot_results(training.results.duration, variable_name = "number of passengers", data_amount = "1 week")

training.results.num.passengers <- train.model(input.data,num.rounds=3,train.perc=0.8,get.duration.model.formula(),"lasso")
plot_results(training.results.num.passengers, variable_name = "trip duration", data_amount = "1 week")

########### RESULTS PLOTS #############
# plot(varImp(fit.knn))
# plot(varImp(fit.svm))
# plot(varImp(fit.rf))
#plot(varImp(fit.lasso))
# plot(varImp(fit.gbm))
