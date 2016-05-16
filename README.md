# GACD-Coursera-Final-Project

This repository contains the final project for Coursera's "Getting and Cleaning Data".

The repository contains the following files:

* `Codebook.md`: describes the data, variables, and work/transformations performed on the raw data.
* `run_analysis.R`: a file that performs the actual transformations on data originally from <http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones>
* `finalDataset.csv`: the dataset that results from running the above script
* `GACD-Coursera-Final-Project.Rproj`: an Rproject file to help manage the above R script file within RStudio
* a `.gitignore` file
* this `README.md` file

## How the R script works

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