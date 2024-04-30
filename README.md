# STAT675 - Final Project Proposal

Group Members: Jiuqin (Jacob) Wei, Yiming Wang

## Project Topic

Advanced Modeling of Categorical Data in Credit Card Approval Prediction

## Dataset Description:

Our analysis will utilize the "Credit Card Approval Prediction" dataset available on Kaggle (https://www.kaggle.com/datasets/rikdifos/credit-card-approval-prediction), which is sufficiently large to meet our project's needs with over 400,000 observations and 20 predictor variables. 

## Dataset Variables: 

The dataset comprises 20 predictor variables: **ID** (client number), **CODE_GENDER** (gender of the client), **FLAG_OWN_CAR** (car ownership status), **FLAG_OWN_REALTY** (real estate ownership status), **CNT_CHILDREN** (number of children), **AMT_INCOME_TOTAL** (total annual income), **NAME_INCOME_TYPE** (income category), **NAME_EDUCATION_TYPE** (education level), **NAME_FAMILY_STATUS** (marital status), **NAME_HOUSING_TYPE** (housing situation), **DAYS_BIRTH** (age of client in days, negative values), **DAYS_EMPLOYED** (employment duration in days, negative values), **FLAG_MOBIL** (mobile phone ownership status), **FLAG_WORK_PHONE** (work phone ownership status), **FLAG_PHONE** (phone ownership status), **FLAG_EMAIL** (email ownership status), **OCCUPATION_TYPE** (occupation), **CNT_FAM_MEMBERS** (family size), **MONTHS_BALANCE** (record month, the month of the extracted data is the starting point, counting backward), and **STATUS** (credit status ranging from 0 for 1-29 days past due, to 5 for overdue or bad debts, 'C' for paid off that month, and 'X' for no loan for the month).

## Project Analysis Overview

In Part 1, we will deploy Logistic Regression and its enhancements, such as Lasso and Generalized Additive Models (GAM), to predict binary outcomes of 'good' or 'bad' creditworthiness from the STATUS variable in our dataset. For Part 2, we will extend our analysis to Multinomial Logistic Regression, utilizing the same **STATUS** variable now treated as a multi-categorical outcome to model different credit statuses. Optional enhancements using Lasso and GAM will also be explored for comparison in both parts.

## Objectives:

The project aims to provide a comprehensive analysis of logistic regression techniques for predicting credit card approval, enhancing our understanding of different model behaviors and their implications in real-world scenarios.
