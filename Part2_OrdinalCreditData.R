# Install necessary packages
install.packages("dplyr")

# Load necessary packages
library(dplyr)

# Read two data frames
applicant = read.csv("/Users/jiuqinwei/Documents/GitHub/STAT675-Final-Project/application_record.csv") # Applicants Demographic Data
credit = read.csv("/Users/jiuqinwei/Documents/GitHub/STAT675-Final-Project/credit_record.csv") # Applicants Accounts Data

# Merge two data frames by ID (inner join)
result = inner_join(applicant, credit, by = "ID")

# Find the location of missing values
which(is.na(result))

# Find the count of missing values 
sum(is.na(result)) # There is no missing value.

# Identify duplicate elements
duplicated(result) 

# Count of duplicated data
sum(duplicated(result)) # There is no duplicate value.




# Write data to CSV file
write.csv2(result, file = "/Users/jiuqinwei/Documents/GitHub/STAT675-Final-Project/part2.csv")