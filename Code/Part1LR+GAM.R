data <- read.csv("/Users/edmund1/Desktop/Bank\ Customer\ Churn\ Prediction\ copy.csv") #change the path
str(data)
summary(data)

# Fitting the logistic regression model
fit <- glm(churn ~ ., data = data, family = binomial())
# Summary of the model
summary(fit)


library(glmnet)
# Prepare the matrix for glmnet
x <- model.matrix(churn ~ ., data = data)[,-1]  # predictor matrix without intercept
y <- data$churn  # binary outcome

# Fit lasso model with cross-validation
cv.lasso <- cv.glmnet(x, y, family = "binomial", alpha = 1)
plot(cv.lasso)
best.lambda <- cv.lasso$lambda.min
lasso.model <- glmnet(x, y, family = "binomial", alpha = 1, lambda = best.lambda)

library(mgcv)
gam.model <- gam(churn ~ s(credit_score) + s(age) + s(balance) + country + gender + products_number + credit_card + active_member + estimated_salary, data = data, family = binomial())
summary(gam.model)

library(ROCR)
predictions <- predict(fit, type = "response")
pred <- prediction(predictions, data$churn)
perf <- performance(pred, measure = "tpr", x.measure = "fpr")
plot(perf, main = "ROC Curve", colorize = TRUE)

# Replace `data_to_predict` with your actual new dataset
predicted_values <- predict(fit, newdata = data_to_predict, type = "response")