# Install necessary packages
install.packages("dplyr")
install.packages("tidyr")
install.packages("MASS")
install.packages("ggplot2")
install.packages("xgboost")
install.packages("corrplot")
install.packages("cluster")
install.packages("nnet")
install.packages("caret")
install.packages("fastDummies")
install.packages("glmnet")
install.packages("dummies")
install.packages("pheatmap")
install.packages("brant")
install.packages("randomForest")
install.packages("ranger")

# Load necessary packages
library(dplyr)
library(tidyr)
library(MASS)
library(ggplot2)
library(xgboost)
library(corrplot)
library(cluster)
library(caret)
library(fastDummies)
library(glmnet)
library(nnet)
library(pheatmap)
library(brant)
library(randomForest)
library(ranger)

# Read two data frames
data = read.csv("/Users/jiuqinwei/Documents/GitHub/STAT675-Final-Project/application_record.csv") # Applicants Demographic Data
record = read.csv("/Users/jiuqinwei/Documents/GitHub/STAT675-Final-Project/credit_record.csv") # Applicants Accounts Data

# Merging the data frames on 'ID'
new_data <- merge(data, record, by = "ID", all.x = TRUE)

# Renaming columns
new_data <- new_data %>%
  rename(Gender = CODE_GENDER,
         Car = FLAG_OWN_CAR,
         Realty = FLAG_OWN_REALTY,
         ChldNo = CNT_CHILDREN,
         inc = AMT_INCOME_TOTAL,
         edutp = NAME_EDUCATION_TYPE,
         famtp = NAME_FAMILY_STATUS,
         houtp = NAME_HOUSING_TYPE,
         email = FLAG_EMAIL,
         inctp = NAME_INCOME_TYPE,
         mobile = FLAG_MOBIL,
         wkphone = FLAG_WORK_PHONE,
         phone = FLAG_PHONE,
         famsize = CNT_FAM_MEMBERS,
         occyp = OCCUPATION_TYPE)

# Feature Engineering
new_data$Age <- -new_data$DAYS_BIRTH / 365.25
new_data$Employment_Duration <- -new_data$DAYS_EMPLOYED / 365.25
new_data$DAYS_BIRTH = NULL
new_data$DAYS_EMPLOYED = NULL
new_data$mobile = NULL # All the values are "1".

# Identify duplicate values
# sum(duplicated(new_data)) # There is no duplicate value.

# Check for missing values in key columns
colSums(is.na(new_data[, c("Gender", "inc", "occyp", "STATUS")]))

# Filling missing 'occyp' based on the most frequent category per 'ID'
# new_data <- new_data %>%
#    group_by(ID) %>%
#    mutate(occyp = if_else(is.na(occyp), first(occyp[!is.na(occyp)]), occyp)) %>%
#    ungroup()

# Impute or remove missing values
new_data$occyp[new_data$occyp == ""] <- NA  # Convert empty strings to NA
new_data <- na.omit(new_data)  # Remove rows with any NA values

# Total missing values in the data frame
total_missing_values <- sum(is.na(new_data))
print(total_missing_values)

# Count missing values in each column
colSums(is.na(new_data))

# Create frequency table
print(table(new_data$STATUS))

# Plot the frequency of STATUS
barplot(table(new_data$STATUS), 
        main = "Frequency Plot of STATUS",
        xlab = "STATUS",
        ylab = "Frequency",
        col = "skyblue")

# Check the data
str(new_data)

# Data Encoding
# Convert to binary features
new_data$Gender <- ifelse(new_data$Gender == "M", 1, 0)
new_data$Gender <- as.integer(new_data$Gender)

new_data$Car <- ifelse(new_data$Car == "Y", 1, 0)
new_data$Car <- as.integer(new_data$Car)

new_data$Realty <- ifelse(new_data$Realty == "Y", 1, 0)
new_data$Realty <- as.integer(new_data$Realty)

str(new_data)

# Frequency encoding
library(dplyr)

# inctp
new_data <- new_data %>%
  group_by(inctp) %>%
  mutate(inctp = n()) %>%
  ungroup()

# edutp
new_data <- new_data %>%
  group_by(edutp) %>%
  mutate(edutp = n()) %>%
  ungroup()

# famtp
new_data <- new_data %>%
  group_by(famtp) %>%
  mutate(famtp = n()) %>%
  ungroup()

# houtp
new_data <- new_data %>%
  group_by(houtp) %>%
  mutate(houtp = n()) %>%
  ungroup()

# houtp
new_data <- new_data %>%
  group_by(occyp) %>%
  mutate(occyp = n()) %>%
  ungroup()

# Check data structure
str(new_data)

# Write data to CSV file, use SAS for further analysis
write.csv(new_data, file = "/Users/jiuqinwei/Desktop/part2.csv")

# Multinomial Logistic Regression

# Ensure 'STATUS' is converted properly to a factor
new_data$STATUS <- factor(new_data$STATUS, levels = c("0", "1", "2", "3", "4", "5", "C", "X"))

# Fit the model
model_mlr <- multinom(STATUS ~ ., data = new_data)
model_mlr <- multinom(STATUS ~ MONTHS_BALANCE + Employment_Duration + Age + inc + occyp, data = new_data)

# View model summary
summary(model_mlr)

# Predict STATUS
# Predicting the class
predicted_status <- nnet:::predict.multinom(model_mlr, new_data, type="class")

# Convert predictions to a data frame for plotting
predicted_data <- data.frame(Predicted_Status = predicted_status)

# Create the bar plot
ggplot(predicted_data, aes(x = Predicted_Status)) +
  geom_bar(fill = "blue", alpha = 0.7) +
  labs(title = "Distribution of Predicted STATUS", x = "STATUS Categories", y = "Count") +
  theme_minimal()

# Predicting the probabilities
predicted_probabilities <- predict(model_mlr, new_data, type="probs")

# Assuming 'predicted_probabilities' is a matrix or a data frame
prob_data <- data.frame(predicted_probabilities)
prob_data$ID = row.names(prob_data)  # Add an identifier for merging

# Merge with the predicted status
full_data <- cbind(prob_data, Predicted_Status = predicted_status)

# Melt the data for ggplot
library(reshape2)
melted_data <- melt(full_data, id.vars = c("ID", "Predicted_Status"))

# Plotting
ggplot(melted_data, aes(x = value, fill = Predicted_Status)) +
  geom_density(alpha = 0.5) +
  facet_wrap(~variable, scales = "free") +
  labs(title = "Density of Predicted Probabilities for Each STATUS Category",
       x = "Probability",
       y = "Density") +
  theme_minimal()

# Ordinal Logistic Regression

# Filter the data (drop all obs of STATUS with "X" and "C")
new_data_ordinal <- subset(new_data, !(STATUS %in% c("X", "C")))

# Convert STATUS to a factor with ordered levels
new_data_ordinal$STATUS <- factor(new_data_ordinal$STATUS, levels = c("0", "1", "2", "3", "4", "5"), ordered = TRUE)

# Load necessary library
library(MASS)

# Fit an ordinal logistic regression model
model_olr <- polr(STATUS ~ ., data = new_data_ordinal, Hess = TRUE)

# Summary of the model to view coefficients and statistics
brant(model_olr) 

# Not suitable for ordinal logistic regression

# Write data to CSV file
write.csv(new_data, file = "/Users/jiuqinwei/Desktop/part2.csv")

### XGboost
# Convert data to DMatrix object
dtrain <- xgb.DMatrix(data = as.matrix(new_data[, -which(colnames(new_data) == "STATUS")]), label = as.numeric(new_data$STATUS) - 1)

# Set parameters for an ordinal multi-class classification
params <- list(
  booster = "gbtree",
  objective = "multi:softprob",
  num_class = length(levels(new_data$STATUS)),
  eta = 0.1,
  gamma = 0.1,
  max_depth = 6,
  min_child_weight = 1,
  subsample = 0.8,
  colsample_bytree = 0.8
)

# Train the model
xgb_model <- xgb.train(params, dtrain, nrounds = 100, watchlist = list(eval = dtrain, train = dtrain), print_every_n = 10)

# Feature importance
xgb.importance(feature_names = colnames(new_data[, -which(colnames(new_data) == "STATUS")]), model = xgb_model)
xgb.plot.importance(importance_matrix = xgb.importance(feature_names = colnames(new_data[, -which(colnames(new_data) == "STATUS")]), model = xgb_model))

### Random Forest
new_data$STATUS <- as.factor(new_data$STATUS)
set.seed(123)  # for reproducibility
rf_model <- randomForest(STATUS ~ ., data = new_data, ntree = 100, mtry = sqrt(ncol(new_data)), importance = TRUE)
print(rf_model)

# Accessing importance matrix directly
var_importance <- rf_model$importance

# Checking the structure of the importance matrix
print(var_importance)

# Create a data frame for plotting
importance_df <- data.frame(Variable = rownames(var_importance), Importance = var_importance[, "MeanDecreaseAccuracy"])

# Plot using ggplot2
ggplot(importance_df, aes(x = reorder(Variable, Importance), y = Importance)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +  # Makes it easier to read variable names
  labs(title = "Variable Importance in Random Forest Model", x = "Variables", y = "Importance") +
  theme_minimal()

