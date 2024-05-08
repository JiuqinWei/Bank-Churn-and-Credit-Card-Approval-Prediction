library(ggplot2)
library(dplyr)
library(corrplot)

data <- read.csv("/Users/edmund1/Desktop/Bank\ Customer\ Churn\ Prediction\ copy.csv") #change the path
str(data)
summary(data)

# Check for missing values
sum(is.na(data))

# Remove duplicate rows, if any
data <- data %>% distinct()

# Histograms for numerical variables
hist(data$age, main = "Age Distribution", xlab = "Age", col = "skyblue")
hist(data$credit_score, main = "Credit Score Distribution", xlab = "Credit Score", col = "lightgreen")
hist(data$balance, main = "Balance Distribution", xlab = "Balance", col = "salmon")

# Bar plots for categorical variables
ggplot(data, aes(x = gender)) + geom_bar(fill = "turquoise") + labs(title = "Gender Distribution")
ggplot(data, aes(x = as.factor(products_number))) + geom_bar(fill = "gold") + labs(title = "Products Number Distribution")

# Boxplots showing the distribution of balance and age by churn
ggplot(data, aes(x = as.factor(churn), y = age, fill = as.factor(churn))) +
  geom_boxplot() + labs(title = "Age Distribution by Churn", x = "Churn", y = "Age")

ggplot(data, aes(x = as.factor(churn), y = balance, fill = as.factor(churn))) +
  geom_boxplot() + labs(title = "Balance Distribution by Churn", x = "Churn", y = "Balance")

# Correlation Plot
numerical_data <- data[, c("credit_score", "age", "tenure", "balance", "estimated_salary")]
correlations <- cor(numerical_data)
corrplot(correlations, method = "circle", type = "upper", order = "hclust", 
         tl.col = "black", tl.srt = 45, addCoef.col = "black")

# Analyzing churn by country
ggplot(data, aes(x = country, fill = as.factor(churn))) +
  geom_bar(position = "fill") + labs(y = "Proportion", title = "Churn by Country")

# Analyzing churn by active member status
ggplot(data, aes(x = as.factor(active_member), fill = as.factor(churn))) +
  geom_bar(position = "fill") + labs(y = "Proportion", title = "Churn by Active Membership")



# Automatically plotting histograms for all numerical attributes
numerical_vars <- sapply(data, is.numeric)
numerical_data <- data[, numerical_vars]

# Loop through each numerical variable to create a histogram
for (var in names(numerical_data)) {
  hist(numerical_data[[var]], main=paste("Distribution of", var), xlab=var, col="lightblue")
}


# Assuming all predictors are numeric and preparing the correlation matrix
numerical_data <- data[, sapply(data, is.numeric)]
cor_matrix <- cor(numerical_data)
library(corrplot)
corrplot(cor_matrix, method = "circle", type = "upper")