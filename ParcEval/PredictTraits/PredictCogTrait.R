# Read In Arguments 
args <- commandArgs(trailingOnly = TRUE)
# 1st Arg: Trait to predict
# 2nd Arg: Parcellation (desk, avgsc, etc.) 
# 3rd Arg: Number of Parcels 
# 4th Arg: Penalty Parameter (alpha for ridge, lasso, elastic net)
# Source R script with necessary functions & libraries

source("PredictTraitsFunctions.R")
#setwd("D:/Research/Tree Pruning/RNew/")

setwd("/pine/scr/a/a/aallen1/PredictTraits/data")

plan(multisession)

# Load and Format HCP Data

hcp_dat <- read.csv("hcp_traits.csv") # Cognitive Traits
age_dat <- read.csv("restricted_zhengwu.csv")
hcp_dat <- left_join(hcp_dat,age_dat,by="Subject")
hcp_dat <- within(hcp_dat,rm("Age"))
colnames(hcp_dat)[which(names(hcp_dat)=="Age_in_Yrs")] <- "Age"

# Add handling of outside parcellations
if(args[2] == "desk" || args[2] == "bn" || args[2] == "hcp"){
  
  dat_file <- paste(args[2],"_","all_scs.csv",sep="")
  
} else{
  
  dat_file <- paste(args[2],"_",args[3],"_","all_scs.csv",sep="")
  
}
  
# Load file
data <- read.csv(dat_file,header=FALSE)
colnames(data)[1] <- "Subject" # Rename First Column to Subject (ID)

# Combine HCP and Network Data 
trait_data <- hcp_dat %>% filter(Subject %in% data$Subject)
full_data = left_join(trait_data,data, by = "Subject")

train_test_splits <- readRDS('train_test_splits.RData')

# Run all fits and get results
test_run <- future_map(trait=args[1],alpha=as.numeric(args[4]),full_data=full_data,.x =train_test_splits, .f = modelAndFitTidy)

# Save Results
if (args[4] == 0){
  model_type <- "ridge"
} else if(args[4] == 1){
  model_type <- "lasso"
} else if(args[4] == 0.5){
  model_type <- "elasticNet"
}
      

if(args[2] == "desk" || args[2] == "bn" || args[2] == "hcp"){
  
    save_name <- paste0("/pine/scr/a/a/aallen1/PredictTraits/results/",
                        args[1],"/",model_type,"_",args[2],"_rmse_cor.RData")
  
} else{
  
    save_name <- paste0("/pine/scr/a/a/aallen1/PredictTraits/results/",
                        args[1],"/",model_type,"_",args[2],"_",args[3],"_rmse_cor.RData")
  
}
saveRDS(test_run,save_name)
