# Install necessary packages
install.packages("dplyr")

# Load necessary packages
library(dplyr)

# Read two data frames
applicant = read.csv("/Users/jiuqinwei/Documents/GitHub/STAT675-Final-Project/application_record.csv") # Applicants Demographic Data
credit = read.csv("/Users/jiuqinwei/Documents/GitHub/STAT675-Final-Project/credit_record.csv") # Applicants Accounts Data

# Merge two data frames by ID
result = inner_join(applicant, credit, by = "ID")


