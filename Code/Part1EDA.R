library(ggplot2)
library(dplyr)
library(corrplot)
library(ROSE) #For data balancing

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

# Check balance of the 'churn' variable
churn_table <- table(data$churn)
print(churn_table) #ratio: 4:1, imbalance

# Balancing the dataset using SMOTE
data_balanced <- ovun.sample(churn ~ ., data = data, method = "over", N = 2*max(churn_table), seed = 123)$data

# Check balance after applying SMOTE
new_churn_table <- table(data_balanced$churn)
print(new_churn_table) #ratio: 1:1, perfectly balance

# Correlation Plot
numerical_data <- data_balanced[, c("credit_score", "age", "tenure", "balance", "estimated_salary")]
correlations <- cor(numerical_data)
corrplot(correlations, method = "circle", type = "upper", order = "hclust", 
         tl.col = "black", tl.srt = 45, addCoef.col = "black")

# Analyzing churn by country
ggplot(data_balanced, aes(x = country, fill = as.factor(churn))) +
  geom_bar(position = "fill") + labs(y = "Proportion", title = "Churn by Country")

# Analyzing churn by active member status
ggplot(data_balanced, aes(x = as.factor(active_member), fill = as.factor(churn))) +
  geom_bar(position = "fill") + labs(y = "Proportion", title = "Churn by Active Membership")



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

library(GGally)
ggpairs(data_balanced, columns = c("credit_score", "age", "balance", "estimated_salary"), aes(color = as.factor(churn)))


# Density plots for 'age' by 'churn' status
ggplot(data_balanced, aes(x = age, fill = as.factor(churn))) +
  geom_density(alpha = 0.5) +
  labs(title = "Density Plot of Age by Churn Status", x = "Age", y = "Density")

# Density plots for 'balance' by 'churn' status
ggplot(data_balanced, aes(x = balance, fill = as.factor(churn))) +
  geom_density(alpha = 0.5) +
  labs(title = "Density Plot of Balance by Churn Status", x = "Balance", y = "Density")

# Interaction between 'gender' and 'balance' in relation to churn
ggplot(data_balanced, aes(x = balance, fill = as.factor(churn))) +
  geom_histogram(bins = 30, position = "identity", alpha = 0.6) +
  facet_grid(. ~ gender) +
  labs(title = "Balance Distribution by Gender and Churn", x = "Balance", y = "Count")

# Chi-squared test for 'gender' and 'churn'
chisq.test(table(data_balanced$gender, data_balanced$churn))

# T-test for 'age' between churned and non-churned customers
t.test(age ~ churn, data = data_balanced)

# ANOVA for 'balance' across multiple categories if applicable
aov_results <- aov(balance ~ as.factor(churn), data = data_balanced)
summary(aov_results)

# Correlation matrix for numerical data
numerical_data <- data_balanced[, sapply(data_balanced, is.numeric)]
cor_matrix <- cor(numerical_data)
corrplot(cor_matrix, method = "number")
