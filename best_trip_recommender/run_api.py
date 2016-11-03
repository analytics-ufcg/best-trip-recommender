import linuxUtils
import sys, os
from multiprocessing import Process

MIN_NUM_ARGS = 7

if len(sys.argv) < MIN_NUM_ARGS:
    print("Wrong number of arguments!")
    print("Usage: python run_api.py <num_processes (< 15)> <method: lasso|svm> <best_trip_recommender_folderpath> <training_data_filepath> <test_metadata_filepath> <model_data_filepath>")
    exit(1)

num_processes = int(sys.argv[1])
method = sys.argv[2]
api_folderpath = sys.argv[3]
training_data_filepath = sys.argv[4]
test_metadata_filepath = sys.argv[5]
model_data_filepath = sys.argv[6]

lu = linuxUtils.LinuxUtils()
#lu.runLinuxCommand('service nginx start')
if num_processes > 15:
    print "Maximum number of processes exceeded!"
    print "Number of processes seted to 15."
    num_processes = 15

valid_methods = {"lasso": "lasso", "svm": "svmRadial", "random-forest": "rf", "knn": "knn", "gradient-boosting": "gbm"}
if method in valid_methods:
    caret_method = valid_methods[method]
else:
    print "Invalid prediction method!"
    print "Choose one of this valid methods: " + str(valid_methods.keys())
    exit(1)

if not os.path.isdir(api_folderpath):
    print "Invalid api_folderpath!"
    exit(1)

if not os.path.isdir(training_data_filepath):
    print "Invalid training_data_filepath!"
    exit(1)

if not os.path.isdir(test_metadata_filepath):
    print "Invalid test_metadata_filepath!"
    exit(1)

if not os.path.isdir(model_data_filepath):
    print "Invalid model_data_filepath!"
    exit(1)

def start_process(port):
    lu.runLinuxCommand('Rscript ' + api_folderpath + '/run_api.R %d %s %s %s %s %s &' % (port, caret_method, api_folderpath, training_data_filepath, test_metadata_filepath, model_data_filepath))

initial_port = 12345
host = '0.0.0.0'
for port in range(initial_port, initial_port + num_processes):
    port_is_free = lu.runLinuxCommand('nc -z %s %s' %(host, port))[1] == 1
    if port_is_free:
        print port
        p = Process(target=start_process, args=(port,))
        p.start()
