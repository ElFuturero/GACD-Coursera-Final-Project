# Getting and Cleaning Data Course Projectless 
# The purpose of this project is to demonstrate your ability to collect,
# work with, and clean a data set. The goal is to prepare tidy data that
# can be used for later analysis. You will be graded by your peers on a series
# of yes/no questions related to the project. You will be required to submit:
# 1) a tidy data set as described below,
# 2) a link to a Github repository with your script for performing the analysis, and 
# 3) a code book that describes the variables, the data, and any transformations or 
# work that you performed to clean up the data called CodeBook.md. 
# You should also include a README.md in the repo with your scripts.
# This repo explains how all of the scripts work and how they are connected.
# 
# One of the most exciting areas in all of data science right now is wearable computing - 
# see for example this article . Companies like Fitbit, Nike, and Jawbone Up are
# racing to develop the most advanced algorithms to attract new users.
# The data linked to from the course website represent data collected from
# the accelerometers from the Samsung Galaxy S smartphone. 
# A full description is available at the site where the data was obtained:
#   
#   http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones
# 
# Here are the data for the project:
#   
#   https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip
# 
# You should create one R script called run_analysis.R that does the following.
# 
# Merges the training and the test sets to create one data set.
# Extracts only the measurements on the mean and standard deviation for each measurement.
# Uses descriptive activity names to name the activities in the data set
# Appropriately labels the data set with descriptive variable names.
# From the data set in step 4, creates a second, independent tidy data
# set with the average of each variable for each activity and each subject.
# Good luck!

# First let's load the dplyr library

library(dplyr)

# Then let's download the raw data that we want to work with into a "data" directory:

if (!file.exists("data")){
  dir.create("data")
}

fileURL <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
fileDest <- "./data/GCDdataset.zip"

if (!file.exists(fileDest)){
  download.file(fileURL, fileDest, method = "curl")
  # Now let's unzip the file contents
  unzip(fileDest, exdir = "./data" )
}

# Now let's create a logical vector that will have the columns that we want to use from
# the X_test.txt files. It starts as a factor vector and then we'll convert it to a
# character vector.

featuresVector <- read.table("./data/UCI HAR Dataset/features.txt")[[2]]
featuresVector <- as.vector(featuresVector, mode = "character")

# Now we want to create a l vector that returns the index of the columns that
# contain either "mean" or "std", regardless of the letter case.

featuresSelect <- grep("(mean|std)", featuresVector, ignore.case = TRUE)

# Now, let's read the test and train data into data frames

testFrame <- read.table("./data/UCI HAR Dataset/test/X_test.txt",
                        col.names = featuresVector) %>%
  tbl_df %>% # we turn it into a dplyr data frame
  select(featuresSelect) # and then we select the columns that we want

# We do the same for the train dataset

trainFrame <- read.table("./data/UCI HAR Dataset/train/X_train.txt",
                         col.names = featuresVector) %>%
  tbl_df %>%
  select(featuresSelect)

# Now we join the two data frames with the test data on top of the training data.
# It will default to join by the common column names.

joinFrame <- full_join(testFrame, trainFrame)

# Now we will go ahead and create the subject column.

testSubject <- read.table("./data/UCI HAR Dataset/test/subject_test.txt", col.names = "Subject")
trainSubject <- read.table("./data/UCI HAR Dataset/train/subject_train.txt", col.names = "Subject")

# We will then join the two vectors
subjectCol <- rbind(testSubject, trainSubject)

# We will match the numbers on both the test and training "subject.txt" files to 
# the appropriate subject by prefixing every number with the word "Subject".

subjectCol <- sapply(subjectCol, function(x) paste0("Subject", x), USE.NAMES=FALSE)

# Now we will create the Activity column
testActivity <- read.table("./data/UCI HAR Dataset/test/y_test.txt", col.names = "Activity",
                           colClasses = "character")
trainActivity <- read.table("./data/UCI HAR Dataset/train/y_train.txt", col.names = "Activity",
                            colClasses = "character")
activityCol <- rbind(testActivity, trainActivity)

# Now we will create a list of the activity names
activityLabels <- read.table("./data/UCI HAR Dataset/activity_labels.txt")
activityList <- activityLabels$V2
names(activityList) <- activityLabels$V1
activityList <- lapply(activityList, as.character)

# Now we want to iterate over the activityCol using the activityList to make the
# required text substitutions

for(i in 1:length(activityCol[,1])){
  activityCol[i,1] <- activityList[[as.numeric(activityCol[i,1])]]
}

# Then we add the subject & activity columns into a new data frame
subjectAct <- cbind(subjectCol, activityCol) %>%
  tbl_df %>%
  mutate(Activity = as.factor(Activity)) # and we turn the Activity column into a factor

# Then we join this new data frame with the first one that we made

finalFrame <- cbind(subjectAct,joinFrame) %>%
  tbl_df %>%
  group_by(Subject, Activity) # and we make sure to group this new frame by subject and activity

# Now we create a summary Frame that gives the mean of each of the variables by activity and subject

summaryFrame <- summarize_each(finalFrame, funs(mean))

# Finally we want to save the tidy dataset
fileWrite <- "./finalDataset.txt"
write.table (summaryFrame, fileWrite, row.names = FALSE)



