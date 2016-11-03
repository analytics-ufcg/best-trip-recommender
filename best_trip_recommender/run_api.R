#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

MIN_NUM_ARGS = 6

if (length(args) != MIN_NUM_ARGS) {
    stop(paste("Wrong number of arguments!",
               "Usage: RScript run_api.R <port> <prediction.method> <api.folder.path> <training.data.folderpath> <test.metadata.folderpath> <model.data.folderpath>",sep="\n"))
}

library(plumber)

create.recommender <- function(p, api.folder.path) {
  r <- plumb(paste0(api.folder.path, "/best_trip_recommender_api.R"))
  r$run(port=p)
}

port <- as.integer(args[1])
prediction.method <<- args[2]
api.folder.path <<- args[3]
training.data.folderpath <<- args[4]
test.metadata.folderpath <<- args[5]
model.data.folderpath <<- args[6]

create.recommender(port, api.folder.path)