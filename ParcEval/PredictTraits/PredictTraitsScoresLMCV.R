############ Load Required Libraries ##################

library(foreach)
library(doFuture)
library(doRNG)

###################################################

# Read Input 
args <- commandArgs(trailingOnly = TRUE)
# 1st Arg: Trait to predict
# 2nd Arg: Parcellation (desk, avgsc, etc.) 
# 3rd Arg: Number of Parcels 
# Source R script with necessary functions & libraries
#args <- c()
#args[1] <- "SSAGA_Alc_Hvy_Max_Drinks"
#args[2] <- "avgsc" 
#args[3] <- 100
source("/pine/scr/a/a/aallen1/PredictTraits/PredictTraitsFunctions.R")
setwd("/pine/scr/a/a/aallen1/PredictTraits/data")
plan(multisession)


############  Load and Format HCP Data ###################

hcp_dat <- read.csv("hcp_traits.csv") # Cognitive Traits
age_dat <- read.csv("restricted_zhengwu.csv")
hcp_dat <- left_join(hcp_dat,age_dat,by="Subject")
hcp_dat <- within(hcp_dat,rm("Age"))
colnames(hcp_dat)[which(names(hcp_dat)=="Age_in_Yrs")] <- "Age"

# Add handling of outside parcellations
if(args[2] == "desk" || args[2] == "bn" || args[2] == "hcp" || args[2] == "yeo_17" || args[2] == "yeo_7"){
  
  dat_file <- paste(args[2],"_","pc_scores.csv",sep="")
  
} else{
  
  dat_file <- paste(args[2],"_",args[3],"_","pc_scores.csv",sep="")
  
}

# Load file and Rename Columns 
data <- read.csv(dat_file,header=FALSE)
name = c(rep(0,ncol(data)-1))
for( j in 1:length(name))name[j]  = paste0("scPC", j)
colnames(data) = c("Subject", name )

# Combine HCP and Network Data 
trait_data <- hcp_dat %>% filter(Subject %in% data$Subject)
full_data = left_join(trait_data,data, by = "Subject")
full_data$Gender <- as.factor(full_data$Gender)
full_data <- full_data %>% drop_na(any_of(args[1])) #Drop NA Values

if(args[1] == "SSAGA_Alc_Hvy_Max_Drinks" || args[1] == "SSAGA_Mj_Times_Used")
{
    full_data <- full_data %>% filter(Gender == "M")
    full_data <- full_data %>% select(-Gender); 
}

hcp_traits_cats <- read.csv("HCP_Data_Cats_Unadj.csv") # Traits and Categories
train_test_splits <- readRDS('train_test_splits.RData') # Trait/Test ID Splits

###############################################################################

################## Loop Through Traits and Splits ############################

registerDoFuture()
registerDoRNG()

plan("multisession",workers=3)

loop_traits <- foreach(i=1:nrow(hcp_traits_cats), .combine="rbind") %:% 
                  foreach (split=train_test_splits,.combine="c") %dopar% {
                    modelAndFitScoresCVLM(hcp_traits_cats$Trait[i],full_data,split)
                  }
  
  
  
  
  





##############################################################################


# Run all fits and get results
ptm <- proc.time()
test_run <- future_map(trait=args[1],full_data=full_data,.x =train_test_splits, .f = modelAndFitScoresCVLM,.options = furrr_options(seed=TRUE))
#test_run <- map(trait=args[1],full_data=full_data,.x =train_test_splits, .f = modelAndFitScoresCVLM)
proc.time() - ptm

# Save Results

model_type <- "pca_lm_v"

save_name <- paste0("/pine/scr/a/a/aallen1/PredictTraits/results/",
                    args[1],"/",model_type,"_",args[2],"_",args[3],"_rmse_cor_glmnet.RData")

saveRDS(test_run,save_name)
