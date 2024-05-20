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
library(ROSE)

rm(list = ls())

# Read two data frames
data = read.csv("~/Documents/GitHub/Bank-Churn-and-Credit-Card-Approval-Prediction/Data/application_record.csv") # Applicants Demographic Data
record = read.csv("~/Documents/GitHub/Bank-Churn-and-Credit-Card-Approval-Prediction/Data/credit_record.csv") # Applicants Accounts Data

# Define the outcome levels
record <- record %>%
  mutate(
    Numeric_STATUS = case_when(
      STATUS == '0' ~ 1,
      STATUS == '1' ~ 1,
      STATUS == '2' ~ 1,
      STATUS == '3' ~ 1,
      STATUS == '4' ~ 1,
      STATUS == '5' ~ 1,
      STATUS == 'C' ~ 0,
      STATUS == 'X' ~ -1,
      TRUE ~ NA_real_  # Handles any unexpected values
    )
  )

# Remove unnecessary columns
data$OCCUPATION_TYPE = NULL
record$MONTHS_BALANCE = NULL

# Step 1: Calculate Average STATUS per ID
id_status_avg <- record %>%
  group_by(ID) %>%
  summarise(Avg_Status = round(mean(Numeric_STATUS, na.rm = TRUE)))

# Step 2: Merge Average STATUS Back to Original Data
analysis_data <- record %>%
  inner_join(id_status_avg, by = "ID")

# Step 3: Inner Join `data` and `analysis_data` on ID
result <- data %>%
  inner_join(analysis_data, by = "ID")

# Renaming columns
result <- result %>%
  rename(Gender = CODE_GENDER,
         Car = FLAG_OWN_CAR,
         Property = FLAG_OWN_REALTY,
         ChldNo = CNT_CHILDREN,
         Inc = AMT_INCOME_TOTAL,
         Edutp = NAME_EDUCATION_TYPE,
         Famtp = NAME_FAMILY_STATUS,
         Houtp = NAME_HOUSING_TYPE,
         Email = FLAG_EMAIL,
         Inctp = NAME_INCOME_TYPE,
         Mobile = FLAG_MOBIL,
         Wkphone = FLAG_WORK_PHONE,
         Phone = FLAG_PHONE,
         Famsize = CNT_FAM_MEMBERS)

# Feature Engineering
result <- result %>%
  mutate(
    Age = -DAYS_BIRTH / 365.25,
    Employment = ifelse(DAYS_EMPLOYED >= 0, 0, abs(DAYS_EMPLOYED) / 365.25)
  )
result$DAYS_BIRTH = NULL
result$DAYS_EMPLOYED = NULL
result$mobile = NULL
result$STATUS = NULL
result$Numeric_STATUS = NULL

# Remove duplicate values
result <- unique(result)

# Impute or remove missing values
# result$occyp[result$occyp == ""] <- NA  # Convert empty strings to NA
# result <- na.omit(result)  # Remove rows with any NA values

# Total missing values in the data frame
# total_missing_values <- sum(is.na(result))
# print(total_missing_values)

# Count missing values in each column
# colSums(is.na(new_data))



### EDA

# Bar plots for categorical variables
ggplot(result, aes(x = Avg_Status)) + geom_bar(fill = "pink") + labs(title = "Avg_Status Distribution")
ggplot(result_balanced, aes(x = Avg_Status)) + geom_bar(fill = "pink") + labs(title = "Avg_Status Distribution After Downsampling")

### Downsampling
# Check balance of the 'Avg_Status' variable
status_table <- table(result$Avg_Status)
print(status_table) # Ratio: 1:4:3, imbalance

# Perform downsampling
result$Avg_Status <- factor(result$Avg_Status, levels = c("-1", "0", "1"))
set.seed(123)
result_balanced <- downSample(x = result[, -which(names(result) == "Avg_Status")], 
                              y = result$Avg_Status)
names(result_balanced)[names(result_balanced) == "Class"] <- "Avg_Status"

# Check balance of the balanced "Avg_Status" variable
status_table_2 <- table(result_balanced$Avg_Status)
print(status_table_2) # Ratio: 1:1:1, perfect balance

# Data Encoding
# Convert to binary features
result_balanced$Gender <- ifelse(result_balanced$Gender == "M", 1, 0)
result_balanced$Gender <- as.integer(result_balanced$Gender)

result_balanced$Car <- ifelse(result_balanced$Car == "Y", 1, 0)
result_balanced$Car <- as.integer(result_balanced$Car)

result_balanced$Property <- ifelse(result_balanced$Property == "Y", 1, 0)
result_balanced$Property <- as.integer(result_balanced$Property)

# Frequency encoding
library(dplyr)

# inctp
result_balanced <- result_balanced %>%
  group_by(Inctp) %>%
  mutate(Inctp = n()) %>%
  ungroup()

# edutp
result_balanced <- result_balanced %>%
  group_by(Edutp) %>%
  mutate(Edutp = n()) %>%
  ungroup()

# famtp
result_balanced <- result_balanced %>%
  group_by(Famtp) %>%
  mutate(Famtp = n()) %>%
  ungroup()

# houtp
result_balanced <- result_balanced %>%
  group_by(Houtp) %>%
  mutate(Houtp = n()) %>%
  ungroup()

# Check data structure
str(result_balanced)

# Multinomial Logistic Regression with LASSO
# Load necessary libraries
install.packages("caret")
install.packages("glmnet")
install.packages("pROC")
install.packages("HandTill2001")
library(caret)
library(glmnet)
library(pROC)
library(HandTill2001)

# Assuming result_balanced is your data frame

# Split the data into training and testing sets
set.seed(123)
trainIndex <- createDataPartition(result_balanced$Avg_Status, p = 0.7, list = FALSE, times = 1)
train_data <- result_balanced[trainIndex,]
test_data <- result_balanced[-trainIndex,]

# Ensure Avg_Status is a factor and levels match between train and test
train_data$Avg_Status <- factor(train_data$Avg_Status, levels = levels(result_balanced$Avg_Status))
test_data$Avg_Status <- factor(test_data$Avg_Status, levels = levels(result_balanced$Avg_Status))

# Prepare data for glmnet
x_train <- model.matrix(Avg_Status ~ Age + Inc + Inctp + Edutp + Houtp + Wkphone + Phone - 1, data = train_data)
y_train <- as.factor(train_data$Avg_Status)

# Fit LASSO model
set.seed(123)
cv.out <- cv.glmnet(x_train, y_train, family = "multinomial", alpha = 1)
best_lambda <- cv.out$lambda.min

# Plot log(lambda) vs. deviance
plot(cv.out)
title(main = "Log(lambda) vs Deviance")

# Fit the final model with the best lambda
lasso_model <- glmnet(x_train, y_train, family = "multinomial", alpha = 1, lambda = best_lambda)

# Coefficients of the model
print(coef(lasso_model))

# Prepare test data for prediction
x_test <- model.matrix(Avg_Status ~ Age + Inc + Inctp + Edutp + Houtp + Wkphone + Phone - 1, data = test_data)

# Predict class probabilities on the test set
lasso_pred_prob <- predict(lasso_model, newx = x_test, type = "response")

# Convert the three-dimensional array to a two-dimensional matrix
lasso_pred_prob_matrix <- matrix(aperm(lasso_pred_prob, c(1, 3, 2)), nrow = nrow(test_data), ncol = length(levels(test_data$Avg_Status)))
colnames(lasso_pred_prob_matrix) <- levels(test_data$Avg_Status)

# Check if all levels are present in the prediction matrix
missing_levels <- setdiff(levels(test_data$Avg_Status), colnames(lasso_pred_prob_matrix))
if (length(missing_levels) > 0) {
  # Add missing columns filled with NA
  for (level in missing_levels) {
    lasso_pred_prob_matrix <- cbind(lasso_pred_prob_matrix, NA)
    colnames(lasso_pred_prob_matrix)[ncol(lasso_pred_prob_matrix)] <- level
  }
}

# Reorder columns to match the levels of the response
lasso_pred_prob_matrix <- lasso_pred_prob_matrix[, levels(test_data$Avg_Status)]
print(dim(lasso_pred_prob_matrix))  # Debug: Check dimensions after reordering

# Convert predicted probabilities to predicted classes
lasso_pred_class <- apply(lasso_pred_prob_matrix, 1, which.max)
print(length(lasso_pred_class))  # Debug: Check length of predicted classes
lasso_pred_class <- factor(lasso_pred_class, levels = 1:length(levels(test_data$Avg_Status)), labels = levels(test_data$Avg_Status))
print(length(lasso_pred_class))  # Debug: Check length after factor conversion

# Confusion matrix
print(length(lasso_pred_class))
print(length(test_data$Avg_Status))
confusionMatrix(lasso_pred_class, test_data$Avg_Status)

# Ensure the response is a factor
test_labels <- factor(test_data$Avg_Status, levels = levels(result_balanced$Avg_Status))

# Compute multi-class AUC using HandTill2001
auc_lasso <- HandTill2001::auc(multcap(response = test_labels, predicted = lasso_pred_prob_matrix))
print(auc_lasso)