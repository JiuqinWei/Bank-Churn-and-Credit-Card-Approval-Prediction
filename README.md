1. # STAT675 Final Project Report

   ## Title

   **Analyzing Bank Churn and Credit Card Approval Using Logistic Regression Techniques**

   ## Abstract

   This report explores bank churn prediction and credit card approval using logistic regression models. Utilizing data from Kaggle, we applied logistic regression with LASSO, GAM, and multinomial logistic regression to analyze customer churn and credit card approval. Our findings highlight key predictors of churn and approval, demonstrating the effectiveness of these models in customer retention and risk assessment. The results suggest actionable strategies for improving financial services and decision-making accuracy.

   ## Introduction

   The financial sector constantly strives to understand customer behavior to enhance service delivery and maintain profitability. Two critical areas of focus are predicting bank customer churn and assessing credit card approval likelihood. Customer churn directly impacts a bank's revenue and operational efficiency, while accurate credit card approval processes are vital for risk management and regulatory compliance. This project utilizes logistic regression techniques to analyze these phenomena using datasets from Kaggle.

   ## Methods

   We employed logistic regression (with LASSO), generalized additive models (GAM), and multinomial logistic regression to analyze the datasets. LASSO regression helps in feature selection and regularization, while GAM allows for flexibility in modeling non-linear relationships. Multinomial logistic regression are suited for categorical outcomes with multiple levels.

   ## Exploratory Data Analysis

   ### Bank Churn Data (10,000 obs, 12 variables)

   - **Summary Statistics**:

   From the summary statistics for the raw data, we can see that there are 6 numeric variables (excluding *customer_id*) and 5 categorical variables.

   - **Key Findings**:

   Numerical variables: age, credit score, account balance, estimated salary, tenure (from how many years he/she is having bank accunt in ABC Bank), number of products:

   Categorical variables

   Binary: churn, gender, active status, credit card.

   We can see that the upper left plot that outcome variable (*churn*) is imbalanced (approximately non-churn to churn ratio =4:1). We need to balance the dataset using SMOTE (Synthetic Minority Over-sampling Technique). After over-sampling, the dataset is balanced. Then we utilized the box plots of *age, gender, country, active_status* by *chrun* to visually see how customers churn by their demographics.

   Exploratory data analysis revealed that older people and being located in Germany increased the likelihood of churn, while males were less likely to churn than females, and active members of the bank are less likely to churn than inactive members.

   From the above correlation matrix (treat all categorical variables as numeric): **Balance**: Higher balances are associated with lower churn rates and higher credit scores; **Credit Score**: Higher credit scores are associated with higher balances and a greater number of products; **Products Number**: More products are associated with higher credit scores and balances; **Age**: Older customers tend to have slightly higher balances.

   ### Credit Card Approval Data (36,457 obs, 17 variables)

   - **Summary Statistics (Raw Data)** :
     - Numerical variables include number of children, income, family size, age, employment duration.
     - Categorical variables include gender, having a car or not, education level, having a house or not, having a mobile phone or not (ommitted due to same value for all obs), having a work phone or not, having a phone or not, having an email or not, marital status, housing type, income type, and occupation type (ommitted due to missing values).

   We defined there are three levels of outcome variable (*Avg_Status*): 

   > - −1 (Non-risky, little profit): approve with further investigation (applicants with no loan, 4525 observations)
   > - 0 (Semi-risky, some profit): approve without further investigation (applicants with paid-off accounts, 17425 obs)
   > - 1 (Risky, most profit, ref): no approval (longer past due, 14507 observations)

   However, the data is unbalanced regarding the *Avg_Status* (accuracy is a poor measure of a model's success on an un-balanced dataset). We use the downsampling method and make the levels of the outcome variables change from 1:4:3 to 1:1:1. The distribution plots are as follows:

   - **Key Findings**:

   Strong correlations were found between child number and family size, suggesting potential multicollinearity. Interactions between age and employment status were notable, though we didn't include the interaction for simplicity.

   ## Statistical Analysis/Modeling

   ### Bank Churn Data

   #### Logistic Regression Model

   A standard logistic regression model was fitted to the data without any regularization.

   - **Model Summary**:
   - **Model Evaluation**:
     - **Confusion Matrix**: Accuracy: 82.16%, Sensitivity: 97.28%, Specificity: 23.08%.
     - **ROC Curve and AUC**: AUC: 0.7796

   #### Logistic Regression with LASSO Penalty

   The `glmnet` package was used to fit a logistic regression model with a LASSO penalty.

   - **Model Summary**: Best lambda (determined by cross-validation): 0.001103737
   - **Model Evaluation**:
     - **Confusion Matrix**: Accuracy: 82.09%, Sensitivity: 97.32%, Specificity: 22.59%.
     - **ROC Curve and AUC**: AUC: 0.7797
     - **Log(lambda) vs Deviance**:

   #### Generalized Additive Models (GAM)

   Different smoothing terms were applied to the GAM model, and the best model was chosen based on ANOVA tests.

   - **Model Summary**:

     - Best model: Separate smoothing terms for `credit_score`, `age`, and `balance`.

   - Marginal Model Plots for `m0`:

   - **ANOVA Test Results**:

   - Comparing base model (`m0`) with GAM model (`m1`):

     ```R
     anova(m0, m1, test = "Chisq")
     Analysis of Deviance Table
     
     Model 1: Exited ~ credit_score + age + balance + Geography + Gender + tenure + products_number + credit_card + active_member + estimated_salary
     Model 2: Exited ~ s(credit_score) + s(age) + s(balance) + Geography + Gender + tenure + products_number + credit_card + active_member + estimated_salary
       Resid. Df Resid. Dev     Df Deviance  Pr(>Chi)    
     1    6989.0     6062.4                              
     2    6970.9     5578.1 18.101    484.3 < 2.2e-16 ***
     ```

   - **Model Evaluation**:

     - **Confusion Matrix**: Accuracy: 83.96%, Sensitivity: 95.77%, Specificity: 37.81%
     - **ROC Curve and AUC**: AUC: 0.8075

   #### Comparison of AUCs

   - Simple Logistic Regression: 0.7796
   - Logistic Regression with LASSO: 0.7797
   - Generalized Additive Model (GAM): 0.8075 ⇒ Best model

   ### Credit Card Approval Data

   #### Multinomial Logistic Regression:

   - **Model Summary**
     - Selection method: backward selection
   - Analyzed the likelihood of credit card approval across three risk levels.
   - **Model Evaluation**:
     - Value/DF<2, Deviance and Pearson goodness-of-fit stats are good (although Pr>ChiSq is less than 0.001). The p-value of Hosmer and Lemeshow Goodness-of-Fit test is larger than 0.05, indicating no violation of model of good-fit.
     - Revealed that age, income, income type, education level, housing type, having a work phone, and having a phone significantly influence approval status.

   #### Multinomial Logistic Regression with LASSO

   - **Confusion Matrix**: The model achieved an accuracy of 36.28%, which is higher than the No Information Rate (33.33%), indicating that the model performs better than random guessing. However, the Kappa value of 0.0442 suggests poor agreement between the predicted and actual classifications. The multi-class AUC for the model was calculated using the `HandTill2001` package, resulting in an AUC of 0.5353. This value indicates that the model performs slightly better than random guessing, but there is substantial room for improvement.

   ## Discussion

   ### Bank Churn Data

   The logistic regression models demonstrated that age, balance, geography, gender, tenure, number of products, credit card possession, active membership status, and estimated salary significantly influence customer churn. Specifically, older customers and those located in Germany were more likely to churn, while males and active members were less likely to churn.

   The application of LASSO penalty helped in feature selection, providing a more interpretable model with slightly improved performance compared to the standard logistic regression. The LASSO model achieved an AUC of 0.7797, which was marginally better than the simple logistic regression model (AUC = 0.7796).

   The GAM approach allowed for modeling non-linear relationships and interactions between predictors. The best GAM model, selected through ANOVA tests, used separate smoothing terms for credit score, age, and balance. This model provided the highest AUC of 0.8075, indicating better performance in capturing the complexities of customer churn behavior.

   ### Credit Card Approval Data

   For the credit card approval data, multinomial logistic regression was used to classify applicants into three risk levels: non-risky, semi-risky, and risky. The model identified significant predictors including age, income, income type, education level, housing type, having a work phone, and having a phone. Applying LASSO to the multinomial logistic regression improved feature selection but did not substantially enhance model performance, as indicated by the multi-class AUC of 0.5353. The model's overall accuracy was 36.28%, which was slightly better than random guessing (33.33%). The low Kappa value of 0.0442 suggested poor agreement between predicted and actual classifications. This result highlights the challenge of predicting credit card approval accurately with the given data.

   ## Conclusion

   Our analysis reveals that logistic regression techniques, including LASSO and GAM, can effectively identify key predictors of bank churn and credit card approval. The GAM model emerged as the best performer for bank churn prediction, capturing non-linear relationships and interactions that other models missed. However, the performance of the multinomial logistic regression for credit card approval indicates room for improvement. Future work could explore more advanced techniques, such as ensemble learning or deep learning, to enhance predictive accuracy.

   In summary, this project demonstrates the utility of logistic regression methods in financial services for customer retention and risk assessment. The findings suggest actionable strategies for banks to improve service delivery and decision-making accuracy, ultimately enhancing profitability and customer satisfaction.

   ## References

   1. Kaggle Datasets: [Bank Customer Churn Dataset](https://www.kaggle.com/datasets/gauravtopre/bank-customer-churn-dataset/data) and [Credit Card Approval Prediction](http://www.kaggle.com/datasets/rikdifos/credit-card-approval-prediction).
