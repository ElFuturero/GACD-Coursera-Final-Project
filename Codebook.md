---
title: "Codebook"
output: github_document
---

## Introduction

The following codebook describes the data, the variables, and the transformations/ work applied on such data for the final project of Coursera's "Getting and Cleaning Data". The following codebook will quote and expand on the data and information originally found on  <http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones>

## The Data

The raw data comes originally from experiments that were carried out with a group of 30 volunteers within an age bracket of 19-48 years. Each person performed six activities (`WALKING`, `WALKING_UPSTAIRS`, `WALKING_DOWNSTAIRS`, `SITTING`, `STANDING`, `LAYING`) wearing a smartphone (Samsung Galaxy S II) on the waist. Using its embedded accelerometer and gyroscope, they captured 3-axial linear acceleration and 3-axial angular velocity at a constant rate of 50Hz.

> The sensor signals (accelerometer and gyroscope) were pre-processed by applying noise filters and then sampled in fixed-width sliding windows of 2.56 sec and 50% overlap (128 readings/window). The sensor acceleration signal, which has gravitational and body motion components, was separated using a Butterworth low-pass filter into body acceleration and gravity. The gravitational force is assumed to have only low frequency components, therefore a filter with 0.3 Hz cutoff frequency was used. From each window, a vector of features was obtained by calculating variables from the time and frequency domain.

## The Variables

The following text describes how the variables were collected and first processed into the raw data we manipulated:

> The features selected for this database come from the accelerometer and gyroscope 3-axial raw signals `tAcc-XYZ` and `tGyro-XYZ`. These time domain signals (prefix 't' to denote time) were captured at a constant rate of 50 Hz. Then they were filtered using a median filter and a 3rd order low pass Butterworth filter with a corner frequency of 20 Hz to remove noise. Similarly, the acceleration signal was then separated into body and gravity acceleration signals (`tBodyAcc-XYZ` and `tGravityAcc-XYZ`) using another low pass Butterworth filter with a corner frequency of 0.3 Hz. 

> Subsequently, the body linear acceleration and angular velocity were derived in time to obtain Jerk signals (`tBodyAccJerk-XYZ` and `tBodyGyroJerk-XYZ`). Also the magnitude of these three-dimensional signals were calculated using the Euclidean norm (`tBodyAccMag`, `tGravityAccMag`, `tBodyAccJerkMag`, `tBodyGyroMag`, `tBodyGyroJerkMag`). 

> Finally a Fast Fourier Transform (FFT) was applied to some of these signals producing `fBodyAcc-XYZ`, `fBodyAccJerk-XYZ`, `fBodyGyro-XYZ`, `fBodyAccJerkMag`, `fBodyGyroMag`, `fBodyGyroJerkMag`. (Note the 'f' to indicate frequency domain signals). 

These signals were used to estimate variables of the feature vector for each pattern:  
'-XYZ' is used to denote 3-axial signals in the X, Y and Z directions.

* `tBodyAcc-XYZ`
* `tGravityAcc-XYZ`
* `tBodyAccJerk-XYZ`
* `tBodyGyro-XYZ`
* `tBodyGyroJerk-XYZ`
* `tBodyAccMag`
* `tGravityAccMag`
* `tBodyAccJerkMag`
* `tBodyGyroMag`
* `tBodyGyroJerkMag`
* `fBodyAcc-XYZ`
* `fBodyAccJerk-XYZ`
* `fBodyGyro-XYZ`
* `fBodyAccMag`
* `fBodyAccJerkMag`
* `fBodyGyroMag`
* `fBodyGyroJerkMag`

Out of a vector of 561 features that were originally provided in the raw data set, the following were selected for each of the above variables:

* `mean()`: Mean value
* `std()`: Standard deviation

Additional vectors obtained by averaging the signals in a signal window sample. These are used on the `angle()` variable:

* `gravityMean`
* `tBodyAccMean`
* `tBodyAccJerkMean`
* `tBodyGyroMean`
* `tBodyGyroJerkMean`

Additionally there are two more variables, `Subject` and `Activity`. The first one represents which experimental subject performed what activity for each of the rows, and it can take on values from `Subject1` to `Subject30`. The variable `Activity` can take on the following values:

* `WALKING`
* `WALKING_UPSTAIRS`
* `WALKING_DOWNSTAIRS`
* `SITTING`
* `STANDING`
* `LAYING`

In total, there are a total of 88 variables over 180 observations.

## The Work/Transformations

The script `run_analysis.R` contains the work and transformations performed on the raw data that can be found on:

<https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip>

The files were downloaded and extracted onto a `data` folder and `features.txt` was read as a `character` vector. Out of these 561 features, we selected those that included the strings `"mean"` or `"std"` using the `grep` function. We ended up with a vector of 86 elements that we then used to select and name the corresponding columns on the files `X_test.txt` and `X_train.txt`. We used the `dplyr` package to manage the dataframes that we worked with, especially to `select` the features we wanted. We then merged the test and the training dataframes using the `full_join` function (alternatively we considered using `rbind` but we still have to explore which one would be faster).

```
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
```

We then created the `Subject` column by reading the `subject_test.txt` and `subject_train.txt` files using `rbind` to knit them together into the `subjectCol` variable. Then the following code was applied to add the string `"Subject"` at the beginning of each of the subject numbers:

```
subjectCol <- sapply(subjectCol, function(x) paste0("Subject", x), USE.NAMES=FALSE)
```

Then to create the `Activity` column we read the files `y_test.txt` and `y_train.txt` and they were binded with `rbind` as above. We then read the `activity_labels.txt` file into a list `activityList` in order to iterate over it in order to substitute the activity numbers for their actual name.

```
activityLabels <- read.table("./data/UCI HAR Dataset/activity_labels.txt")
activityList <- activityLabels$V2
names(activityList) <- activityLabels$V1
activityList <- lapply(activityList, as.character)

# Now we want to iterate over the activityCol using the activityList to make the
# required text substitutions

for(i in 1:length(activityCol[,1])){
  activityCol[i,1] <- activityList[[as.numeric(activityCol[i,1])]]
}
```

We then used `cbind` to join both columns and transformed each into factors (rather than character columns).

```
subjectAct <- cbind(subjectCol, activityCol) %>%
  tbl_df %>%
  mutate(Activity = as.factor(Activity)) # and we turn the Activity column into a factor
```

Then we joined this frame to our previous data frame and grouped it by `Subject` and `Activity`.

```
finalFrame <- cbind(subjectAct,joinFrame) %>%
  tbl_df %>%
  group_by(Subject, Activity)
```

This gave us a dataset with 88 variables and 10,299 observations which we further summarized by the mean of each variable by `Subject` and `Activity`:

```
summaryFrame <- summarize_each(finalFrame, funs(mean))
```

Finally, we wrote out our finalized dataset as a csv into a file `finalDataset.csv` which is included in this repository.





