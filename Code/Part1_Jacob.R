# Load necessary libraries
library(tidyverse)
library(caret)
library(glmnet)
library(mgcv)
library(pROC)
library(ROSE)
library(corrplot)
library(car)

# Load the dataset
data <- read.csv("Bank Customer Churn Prediction.csv")

# Exploratory Data Analysis
## Summary Statistics
summary(data)
str(data)

## Check for missing values
sum(is.na(data))

# Histograms for numerical variables
hist(data$age, main = "Age Distribution", xlab = "Age", col = "skyblue")
hist(data$credit_score, main = "Credit Score Distribution", xlab = "Credit Score", col = "lightgreen")
hist(data$balance, main = "Balance Distribution", xlab = "Balance", col = "salmon")
hist(data$estimated_salary, main = "Estimated Salary Distribution", xlab = "Estimated Salary", col = "purple")
hist(data$tenure, main = "Tenure Distribution", xlab = "Tenure", col = "red")
hist(data$products_number, main = "Number of Products Distribution", xlab = "Number of Products", col = "yellow")

# Bar plots for categorical variables
ggplot(data, aes(x = churn)) + geom_bar(fill = "pink") + labs(title = "Churn Distribution")
ggplot(data, aes(x = country)) + geom_bar(fill = "lightgray") + labs(title = "Geography Distribution")
ggplot(data, aes(x = gender)) + geom_bar(fill = "turquoise") + labs(title = "Gender Distribution")
ggplot(data, aes(x = as.factor(active_member))) + geom_bar(fill = "gold") + labs(title = "Active Status Distribution")
ggplot(data, aes(x = as.factor(active_member))) + geom_bar(fill = "green") + labs(title = "Credit Card Distribution")

# Check balance of the 'churn' variable
churn_table <- table(data$churn)
print(churn_table) # Ratio: 4:1, imbalance

# Balancing the dataset using SMOTE
data_balanced <- ovun.sample(churn ~ ., data = data, method = "over", N = 2*max(churn_table), seed = 123)$data

# Check balance after applying SMOTE
new_churn_table <- table(data_balanced$churn)
print(new_churn_table) # Ratio: 1:1, perfect balance

### Boxplots showing the distribution of XXX by churn

# Analyzing churn by age
ggplot(data_balanced, aes(x = as.factor(churn), y = age, fill = as.factor(churn))) +
  geom_boxplot() + labs(title = "Age Distribution by Churn", x = "Churn", y = "Age")

# Analyzing churn by gender
ggplot(data_balanced, aes(x = as.factor(gender), fill = as.factor(churn))) +
  geom_bar(position = "fill") + labs(y = "Proportion", title = "Churn by Gender")

# Analyzing churn by country
ggplot(data_balanced, aes(x = country, fill = as.factor(churn))) +
  geom_bar(position = "fill") + labs(y = "Proportion", title = "Churn by Country")

# Analyzing churn by active member status
ggplot(data_balanced, aes(x = as.factor(active_member), fill = as.factor(churn))) +
  geom_bar(position = "fill") + labs(y = "Proportion", title = "Churn by Active Membership")

### Correlation Plot
numerical_data <- data_balanced[, c("credit_score", "age", "tenure", "balance", "estimated_salary")]
correlations <- cor(numerical_data)
corrplot(correlations, method = "circle", type = "upper", order = "hclust", 
         tl.col = "black", tl.srt = 45, addCoef.col = "black")

# Automatically plotting histograms for all numerical attributes
numerical_vars <- sapply(data_balanced, is.numeric)
numerical_data <- data_balanced[, numerical_vars]

# Loop through each numerical variable to create a histogram
for (var in names(numerical_data)) {
  hist(numerical_data[[var]], main=paste("Distribution of", var), xlab=var, col="lightblue")
}

# Assuming all predictors are numeric and preparing the correlation matrix
numerical_data <- data[, sapply(data, is.numeric)]
cor_matrix <- cor(numerical_data)
library(corrplot)
corrplot(cor_matrix, method = "circle", type = "upper")

###############################################################################
### Model Building

# Data Preparation
## Convert categorical variables to factors
data$Geography <- as.factor(data$country)
data$Gender <- as.factor(data$gender)
data$Exited <- as.factor(data$churn)

## Split the data into training and testing sets
set.seed(123)
trainIndex <- createDataPartition(data$Exited, p = 0.7, list = FALSE, times = 1)
train_data <- data[trainIndex,]
test_data <- data[-trainIndex,]

# Simple Logistic Regression Model
logit_model <- glm(Exited ~ credit_score + age + balance + Geography + Gender + tenure + products_number + credit_card + active_member + estimated_salary, data = train_data, family = binomial)
summary(logit_model)

# Model prediction and evaluation on the test set
logit_pred_prob <- predict(logit_model, newdata = test_data, type = "response")
logit_pred_class <- ifelse(logit_pred_prob > 0.5, 1, 0)

# Confusion matrix
confusionMatrix(as.factor(logit_pred_class), as.factor(test_data$Exited))

# ROC Curve and AUC
roc_curve_logit <- roc(test_data$Exited, logit_pred_prob)
auc_logit <- auc(roc_curve_logit)
plot(roc_curve_logit, main = paste("ROC Curve for Logistic Regression (AUC =", round(auc_logit, 3), ")"))

###############################################################################

# Prepare data for glmnet
x <- model.matrix(Exited ~ credit_score + age + balance + Geography + Gender + tenure + products_number + credit_card + active_member + estimated_salary - 1, data = train_data)
y <- train_data$Exited

# Fit LASSO model
set.seed(123)
cv.out <- cv.glmnet(x, y, family = "binomial", alpha = 1)
best_lambda <- cv.out$lambda.min

# Plot log(lambda) vs. deviance
plot(cv.out)
title(main = "Log(lambda) vs Deviance")

# Fit the final model with the best lambda
lasso_model <- glmnet(x, y, family = "binomial", alpha = 1, lambda = best_lambda)

# Coefficients of the model
coef(lasso_model)

# Model prediction and evaluation on the test set
x_test <- model.matrix(Exited ~ credit_score + age + balance + Geography + Gender + tenure + products_number + credit_card + active_member + estimated_salary - 1, data = test_data)
lasso_pred_prob <- predict(lasso_model, newx = x_test, type = "response")
lasso_pred_class <- ifelse(lasso_pred_prob > 0.5, 1, 0)

# Confusion matrix
confusionMatrix(as.factor(lasso_pred_class), as.factor(test_data$Exited))

# ROC Curve and AUC
roc_curve_lasso <- roc(test_data$Exited, lasso_pred_prob)
auc_lasso <- auc(roc_curve_lasso)
plot(roc_curve_lasso, main = paste("ROC Curve for LASSO Logistic Regression (AUC =", round(auc_lasso, 3), ")"))

###############################################################################

# Base logistic regression model
m0 <- glm(Exited ~ credit_score + age + balance + Geography + Gender + tenure + products_number + credit_card + active_member + estimated_salary, data = train_data, family = binomial)
mmps(m0)

# GAM model with separate smoothing terms
m1 <- gam(Exited ~ s(credit_score) + s(age) + s(balance) + Geography + Gender + tenure + products_number + credit_card + active_member + estimated_salary, family = binomial, data = train_data)
summary(m1)

# ANOVA test to compare models
anova(m0, m1, test = "Chisq")

# Update model to try different smooth terms
m2 <- update(m1, ~ . - s(balance) + balance)
anova(m2, m1, test = "Chisq")

m3 <- update(m1, ~ s(credit_score, age) + s(balance) + Geography + Gender + tenure + products_number + credit_card + active_member + estimated_salary)
anova(m3, m1, test = "Chisq")

m4 <- update(m1, ~ s(credit_score, age, balance) + Geography + Gender + tenure + products_number + credit_card + active_member + estimated_salary)
anova(m4, m1, test = "Chisq")

# Choose the best model based on ANOVA results
best_gam_model <- m1

# Model prediction and evaluation on the test set
gam_pred_prob <- predict(best_gam_model, newdata = test_data, type = "response")
gam_pred_class <- ifelse(gam_pred_prob > 0.5, 1, 0)

# Confusion matrix
confusionMatrix(as.factor(gam_pred_class), as.factor(test_data$Exited))

# ROC Curve and AUC
roc_curve_gam <- roc(test_data$Exited, gam_pred_prob)
auc_gam <- auc(roc_curve_gam)
plot(roc_curve_gam, main = paste("ROC Curve for GAM (AUC =", round(auc_gam, 3), ")"))

###############################################################################

# Comparison of AUCs
auc(roc_curve_logit)
auc(roc_curve_lasso)
auc(roc_curve_gam)

