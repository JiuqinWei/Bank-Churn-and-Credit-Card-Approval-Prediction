library(caret)
library(glmnet)
library(mgcv)
library(car)
library(pROC)

data <- read.csv("/Users/edmund1/Desktop/Bank\ Customer\ Churn\ Prediction\ copy.csv") #change the path
str(data)
summary(data)
dim(data)

library(caret)
set.seed(123)
split <- createDataPartition(data$churn, p = 0.8, list = FALSE)

trainingData <- data[split, ]
testingData <- data[-split, ]

# Fitting the logistic regression model
fit <- glm(churn ~ ., data = trainingData, family = binomial())
summary(fit)

# Logistic Regression Diagnostics: VIF and MMP
library(car)
vif(fit)  # Check for multicollinearity
# Compute the predicted probabilities for the training data
predicted_values <- predict(fit, newdata = trainingData, type = "response")

# Now proceed to generate the PDF and plot the predicted probabilities against predictors
pdf("Manual_MMPs.pdf")
par(mfrow=c(3, 3))  # Adjust the layout based on the number of predictors
for(i in 2:ncol(trainingData)) {  # Assuming first column is the response
  if(is.numeric(trainingData[[i]])) {  # Ensure that the variable is numeric
    plot(predicted_values, trainingData[[i]], main=colnames(trainingData)[i],
         xlab="Predicted Probability", ylab="Predictor")
    abline(h = median(trainingData[[i]], na.rm = TRUE), col = "red")
  }
}
dev.off()

# Prepare the matrix for glmnet
x <- model.matrix(churn ~ ., data = trainingData)[,-1]  # predictor matrix without intercept
y <- trainingData$churn  # binary outcome

# Fit lasso model with cross-validation
cv.lasso <- cv.glmnet(x, y, family = "binomial", alpha = 1)
plot(cv.lasso)
best.lambda <- cv.lasso$lambda.min
lasso.model <- glmnet(x, y, family = "binomial", alpha = 1, lambda = best.lambda)
coef(lasso.model)  # View coefficients


gam.model <- gam(churn ~ s(credit_score) + s(age) + s(balance) + country + gender + products_number + credit_card + active_member + estimated_salary, data = trainingData, family = binomial())
summary(gam.model)
pdf("GAM_Smooth_Plots.pdf")
plot(gam.model, pages = 1)  # Plotting smooth terms
dev.off()

# Prediction and Model Evaluation
predictions <- predict(fit, newdata = testingData, type = "response")
predicted_classes <- ifelse(predictions > 0.5, 1, 0)
confusionMatrix <- table(Predicted = predicted_classes, Actual = testingData$churn)
print(confusionMatrix)

# Calculate accuracy, precision, recall, and F1 score
accuracy <- sum(diag(confusionMatrix)) / sum(confusionMatrix)
precision <- confusionMatrix[2, 2] / sum(confusionMatrix[2, ])
recall <- confusionMatrix[2, 2] / sum(confusionMatrix[, 2])
f1_score <- 2 * ((precision * recall) / (precision + recall))
print(paste("Accuracy: ", accuracy))
print(paste("Precision: ", precision))
print(paste("Recall: ", recall))
print(paste("F1 Score: ", f1_score))

# ROC Curve and AUC
roc_obj <- roc(response = testingData$churn, predictor = as.numeric(predictions))
plot(roc_obj, main = "ROC Curve for Logistic Regression Model")
abline(a = 0, b = 1, col = "red", lty = 2)  # Adding reference line
auc_value <- auc(roc_obj)
print(paste("AUC: ", auc_value))