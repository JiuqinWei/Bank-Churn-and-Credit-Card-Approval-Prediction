# Install necessary packages
install.packages("dplyr")
install.packages("tidyr")
install.packages("MASS")
install.packages("ggplot2")

# Load necessary packages
library(dplyr)
library(tidyr)
library(MASS)
library(ggplot2)

# Read two data frames
data = read.csv("/Users/jiuqinwei/Documents/GitHub/STAT675-Final-Project/application_record.csv") # Applicants Demographic Data
record = read.csv("/Users/jiuqinwei/Documents/GitHub/STAT675-Final-Project/credit_record.csv") # Applicants Accounts Data

# Merge this data frame with the original data frame
new_data <- merge(data, record, by = "ID", all.x = TRUE)

# Renaming columns using dplyr
new_data <- new_data %>%
  rename(Gender = CODE_GENDER,
         Car = FLAG_OWN_CAR,
         Reality = FLAG_OWN_REALTY,
         ChldNo = CNT_CHILDREN,
         inc = AMT_INCOME_TOTAL,
         edutp = NAME_EDUCATION_TYPE,
         famtp = NAME_FAMILY_STATUS,
         houtp = NAME_HOUSING_TYPE,
         email = FLAG_EMAIL,
         inctp = NAME_INCOME_TYPE,
         wkphone = FLAG_WORK_PHONE,
         phone = FLAG_PHONE,
         famsize = CNT_FAM_MEMBERS,
         occyp = OCCUPATION_TYPE)

# Total missing values in the data frame
total_missing_values <- sum(is.na(new_data))

# Print total number of missing values
print(total_missing_values)

# Remove all rows with missing values
new_data <- na.omit(new_data)

# Filter the data (drop all obs of STATUS with "X" and "C")
new_data <- subset(new_data, !(STATUS %in% c("X", "C")))

# Create a frequency table of STATUS
status_freq <- table(new_data$STATUS)
status_freq

# Convert STATUS to a factor with ordered levels
new_data$STATUS <- factor(new_data$STATUS, levels = c("0", "1", "2", "3", "4", "5"), ordered = TRUE)

# Plot the frequency of STATUS
barplot(table(new_data$STATUS), 
        main = "Frequency Plot of STATUS",
        xlab = "STATUS",
        ylab = "Frequency",
        col = "skyblue")

# Identify duplicate values
duplicated(new_data) 

# Count of duplicated data
sum(duplicated(new_data)) # There is no duplicate value.

# Check the data
glimpse(new_data)

# Treat all the features

## Binary Features
### Gender
new_data <- new_data %>%
  mutate(Gender = case_when(
    Gender == "F" ~ "0",  # Replace 'F' with '0'
    Gender == "M" ~ "1",  # Replace 'M' with '1'
    TRUE ~ Gender         # Keep all other values unchanged (if any)
  )) %>%
  mutate(Gender = as.numeric(Gender))  # Convert Gender to numeric

### Car
new_data <- new_data %>%
  mutate(Car = case_when(
    Car == "N" ~ "0",
    Car == "Y" ~ "1",
    TRUE ~ Car  # Handles cases where Car might not be N or Y
  )) %>%
  mutate(Car = as.numeric(Car))  # Convert Car to numeric

### House Reality
new_data <- new_data %>%
  mutate(Reality = case_when(
    Reality == "N" ~ "0",
    Reality == "Y" ~ "1",
    TRUE ~ Reality  # Handles cases where Reality might not be N or Y
  )) %>%
  mutate(Reality = as.numeric(Reality))  # Convert Reality to numeric

## Continuous Features
### Children number
new_data$ChldNo[new_data$ChldNo >= 2] <- '2More'
print(table(new_data$ChldNo))
new_data = convert_dummy(new_data, 'ChldNo')

### Annual Income
# Convert 'inc' column to numeric
new_data$inc <- as.numeric(new_data$inc)

# Divide 'inc' values by 10,000
new_data$inc <- new_data$inc / 10000

# Calculate frequency counts of 'inc' values grouped into 10 bins
inc_bins <- cut(new_data$inc, breaks = 10, labels = FALSE)

# Categorize 'inc' column into three categories based on quantiles
new_data$inc_category <- cut(new_data$inc, quantile(new_data$inc, 
                                                    probs = c(0, 1/3, 2/3, 1), 
                                                    na.rm = TRUE), 
                             labels = c("low", "medium", "high"), 
                             include.lowest = TRUE)

# Print the frequency counts of 'inc' values grouped into 10 bins
print(table(inc_bins))

# Print the frequency counts of 'inc_category' values
print(table(new_data$inc_category))

# Convert the income category to dummy variable
new_data = convert_dummy(new_data,'inc_category')

### Age
# Step 1: Calculate Age
new_data$Age <- -new_data$DAYS_BIRTH / 365

# Step 2: Calculate frequency counts of Age values grouped into 10 bins and normalize
age_bins <- cut(new_data$Age, breaks = 10, labels = FALSE)
age_counts <- table(age_bins, useNA = "ifany")
age_freq <- age_counts / sum(age_counts, na.rm = TRUE)

# Print the normalized frequency counts of Age values
print(age_freq)

# Step 3: Plot histogram of Age values
hist(new_data$Age, breaks = 20, main = "Histogram of Age", xlab = "Age", ylab = "Density", prob = TRUE)

# Step 4: Categorize Age into five categories: "lowest", "low", "medium", "high", "highest"
new_data$gp_Age <- cut(new_data$Age, 5, labels = c("lowest", "low", "medium", "high", "highest"))

# Step 5: Convert the categorical variable 'gp_Age' into dummy variables
new_data <- convert_dummy(new_data, 'gp_Age')

### Days Employed
# Step 1: Calculate worktm
new_data$worktm <- -new_data$DAYS_EMPLOYED / 365

# Step 2: Replace negative values with NA
new_data$worktm[new_data$worktm < 0] <- NA

# Step 3: Replace NA values with mean
new_data$worktm[is.na(new_data$worktm)] <- mean(new_data$worktm, na.rm = TRUE)

# Step 4: Plot histogram of worktm values
hist(new_data$worktm, breaks = 20, main = "Histogram of worktm", xlab = "worktm", ylab = "Density", prob = TRUE)

# Step 5: Categorize worktm into five categories: "lowest", "low", "medium", "high", "highest"
new_data$gp_worktm <- cut(new_data$worktm, 5, labels = c("lowest", "low", "medium", "high", "highest"))

# Step 6: Convert the categorical variable 'gp_worktm' into dummy variables
new_data <- convert_dummy(new_data, 'gp_worktm')

### Family Size
# Step 1: Get frequency counts of 'famsize'
table(new_data$famsize)

# Step 2: Convert 'famsize' to integer
new_data$famsize <- as.integer(new_data$famsize)

# Step 3: Create a new column 'famsizegp' and convert it to object
new_data$famsizegp <- new_data$famsize
new_data$famsizegp <- as.character(new_data$famsizegp)

# Step 4: Replace values in 'famsizegp' >= 3 with '3more'
new_data$famsizegp[new_data$famsizegp >= 3] <- '3more'

# Step 5: Convert 'famsizegp' into dummy variables
new_data <- convert_dummy(new_data, 'famsizegp')

## Categorical Features






# Fit the model
model <- polr(STATUS ~ .,
              data = result_filtered, Hess = TRUE)

# Get a summary of the model
summary(model)

# Write data to CSV file
write.csv2(result_filtered, file = "/Users/jiuqinwei/Desktop/part2.csv")
