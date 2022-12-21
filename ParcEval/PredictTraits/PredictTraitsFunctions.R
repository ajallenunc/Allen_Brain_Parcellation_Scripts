library(ranger)
library(future)
library(glmnet)
library(furrr)
library(tidymodels)
library(pls)
library(CVST)


# Input: all_ids: list of all subject ids in data
#        num_sets: Number of training/test sets to make

# Output: train_test_list: List of lists containing two dataframes. The first is the training subject Ids and the     #         second is the testing subject ids 

createSubSplits <- function(all_ids,num_sets){
  
  # Reformat all_ids data 
  train_test_list <- list()
  all_ids <- as.data.frame(all_ids)
  names(all_ids) <- "Subject"
  
  for (i in 1:num_sets) {
    
    set.seed(i) 
    sample_ids <- as.list(initial_split(all_ids,prop=4/5))
    train_test_list <- append(train_test_list,list(list(training(sample_ids),testing(sample_ids))))
    
  }
  
  saveRDS(train_test_list,"train_test_splits.RData")
  
  return(train_test_list)
}

modelAndFitKernelReg <- function(trait,full_data,train_test_ids){
  
  ####### Load Data ########
  
  train_ids <- train_test_ids[[1]]
  test_ids <- train_test_ids[[2]]
  
  train_data <- full_data %>% filter(Subject %in% train_ids$Subject)
  test_data <- full_data %>% filter(Subject %in% test_ids$Subject)
  
  ####### Clean Data ########
  
  # Keep these variables
  keep_vars <- paste("^scPC\\d|^Age$|^Gender$|^Subject$|^",trait,"$",sep="")
  train_data <- train_data %>% select(matches(keep_vars))
  test_data<- test_data %>% select(matches(keep_vars))
  
  train_text <- paste0("model.matrix(",trait,"~.-Subject,data=train_data)")
  test_text <- paste0("model.matrix(",trait,"~.-Subject,data=test_data)")
  
  train_x <- eval(parse(text=train_text))[,-1] # Remove Intercept (glmnet adds back in)
  test_x <- eval(parse(text=test_text))[,-1] # Remove Intercept (glmnet adds back in)
  test_y < - test_data[,trait]
  
  rm(full_data)
  rm(train_data)
  rm(test_data)

  ##### Construct Learner #####
  
  krr <- constructKRRLearner()
  
  train_y <- train_data[,trait]
  cvst_train <- constructData(as.matrix(train_x),train_y)
  cvst_test <- constructData(as.matrix(test_x),0)
  
  ### Construct Lambda Grid ###
  
  # dot_prod <- apply(train_data,2,function(x){
  #   abs(t(x)%*%train_y)
  # })
  # 
  # if (alpha == 0)
  # {
  #   max_pen <- log(max(dot_prod/900) / 0.0020)
  #   min_pen <- log(max_pen*0.001)
  # }
  # else
  # {
  #   max_pen <- log(max(dot_prod/900) / alpha)
  #   min_pen <- log(max_pen*0.001)
  # }
  # 
  #lambda_grid <- grid_regular(penalty(c(max_pen,min_pen),trans=log_trans(base = exp(1))), levels = 50) %>% as.matrix()
  
  lambda_grid <- 10^(-8:0)
  
  ### Train KRR with CV ### 
  params <- constructParams(kernel="rbfdot",sigma=10^(-5:-5),lambda=10^(-5:-1))
  
  krr_cv <- CV(cvst_train,krr,params,fold=10)
  krr_cv <- krr_cv[[1]]
  
  params <- constructParams(kernel="rbfdot",sigma=krr_cv$sigma,krr_cv$lambda)
  
  
  best_krr <- krr$learn(cvst_train,krr_cv)

  test_pred <- krr$predict(best_krr,cvst_test)

  test_rmse <- sqrt(mean((test_pred-test_y)^2))
  test_corr <- cor(test_pred,test_y)

  fin_results <- list(test_rmse,test_corr[1]);

  return(fin_results)

}

modelAndFitScoresCVLM <- function(trait,full_data,train_test_ids){
  ### Preparing Single Train/Test Split of Data for LM ###
  
  ####### Load Data ########
  
  train_ids <- train_test_ids[[1]]
  test_ids <- train_test_ids[[2]]

  train_data <- full_data %>% filter(Subject %in% train_ids$Subject)
  test_data <- full_data %>% filter(Subject %in% test_ids$Subject)

  rm(full_data)
  
  train_cv_splits <- vfold_cv(train_data,v=10)
  
  ###########################
  
  ####### Clean Data ########
  
  # Keep these variables
  keep_vars <- paste("^scPC\\d|^Age$|^Gender$|^Subject$|^",trait,"$",sep="")
  train_data <- train_data %>% select(matches(keep_vars))
  test_data<- test_data %>% select(matches(keep_vars))

  ### Create Sequence of PCs to Validate ###
  max_pcs <- nrow(train_data) - 10
  pc_iter <- seq(1,max_pcs,3)
  
  ####### Cross Validation Function ##########
  
  # For Single PC in PC Sequence, Send All Train/Test Splits to Fit Function
  splitPCScores<- function(train_data,trait,alpha,num_pcs,num_repeat,train_splits){
    
    map_df(train_splits$splits,prepScoresSplit,num_pcs=num_pcs,trait=trait) %>% group_by(num_pcs) %>% summarize(mean_RMSE = mean(rmse), mean_Cor = mean(cor),n=length(rmse))
    
  }
  # This function prepares a single validation split for glmnet fitting
  prepScoresSplit <- function(splitObj,num_pcs,trait){
    
    train_dat <- analysis(splitObj) #Get Training Set
    test_dat <- assessment(splitObj) # Get Testing Set 
    
    run_my_lm <- myLMFunction(train_dat,test_dat,num_pcs,trait)
    
    split_result <- data.frame(num_pcs = num_pcs,rmse = run_my_lm[[1]],cor = run_my_lm[[2]])
    
  }
  
  # This function performs repeated glmnet fitting 
  myLMFunction <- function(train_dat,test_dat,num_pcs,trait){
    
    # Include Correct Number of PCs
    in_pcs <- sprintf("scPC%s",seq(num_pcs))
    train_dat <- train_dat %>% select(any_of(c("Subject",trait,"Age","Gender",in_pcs)))
    test_dat <- test_dat %>% select(any_of(c("Subject",trait,"Age","Gender",in_pcs)))
    
    
    lm_text <- paste0("lm(",trait,"~.-Subject,data=train_dat)")
    lm_model <- eval(parse(text=lm_text)) # Remove Intercept (glmnet adds back in)
    
    test_pred <- predict(lm_model,newdata=test_dat)
    
    test_rmse <- sqrt(mean((test_pred-test_dat[,trait])^2))
    test_corr <- cor(test_pred,test_dat[,trait])
    
    fin_results <- list(test_rmse,test_corr[1]); 
    
  }
  ###############################################################
  
  # Do CV 
  cv_pc <- map_df(pc_iter,splitPCScores,train_data=train_data,trait=trait,alpha=alpha,num_repeat=num_repeat,train_splits=train_cv_splits)
  
  # Get Best PCs and Fit to Test Data
  
  best_pcs <- cv_pc$num_pcs[which.min(cv_pc$mean_RMSE)]
  best_rmse <- cv_pc$mean_RMSE[cv_pc$num_pcs == best_pcs]
  best_cor <- cv_pc$mean_Cor[cv_pc$num_pcs == best_pcs]
  my_best_fit <- myLMFunction(train_data,test_data,best_pcs,trait)
  
  results <- list(best_pcs,my_best_fit[[1]],my_best_fit[[2]],best_rmse,best_cor)
  
  return(results)
  #return(list(train_data,test_data,trait))
}

modelAndFitScoresLM <- function(trait,full_data,train_test_valid_ids){
  ### Preparing Single Train/Test Split of Data for LM ###
  
  ####### Load Data ########
  
  train_ids <- train_test_valid_ids[[1]]
  test_ids <- train_test_valid_ids[[2]]
  valid_ids <- train_test_valid_ids[[3]]
  
  train_data <- full_data %>% filter(Subject %in% train_ids$Subject)
  test_data <- full_data %>% filter(Subject %in% test_ids$Subject)
  valid_data <- full_data %>% filter(Subject %in% valid_ids$Subject)
  
  rm(full_data)
  
  ###########################
  
  ####### Clean Data ########
  
  # Keep these variables
  keep_vars <- paste("^scPC\\d|^Age$|^Gender$|^Subject$|^",trait,"$",sep="")
  train_data <- train_data %>% select(matches(keep_vars))
  test_data<- test_data %>% select(matches(keep_vars))
  valid_data<- valid_data %>% select(matches(keep_vars))
  
  ### Create Sequence of PCs to Validate ###
  max_pcs <- nrow(train_data) - 10
  pc_iter <- seq(1,max_pcs,3)
  #pc_iter_1 = seq(10,300,10)
  #pc_iter_2 = seq(301,700,5)
  #pc_iter = c(pc_iter_1,pc_iter_2)
  #pc_iter = c(10,20,30,40,50)
  
  ####### Cross Validation Function ##########
  
  # This function performs repeated glmnet fitting 
  myLMFunction <- function(train_dat,test_dat,num_pcs,trait){
    
    # Include Correct Number of PCs
    in_pcs <- sprintf("scPC%s",seq(num_pcs))
    train_dat <- train_dat %>% select(any_of(c("Subject",trait,"Age","Gender",in_pcs)))
    test_dat <- test_dat %>% select(any_of(c("Subject",trait,"Age","Gender",in_pcs)))
    
    
    lm_text <- paste0("lm(",trait,"~.-Subject,data=train_dat)")
    lm_model <- eval(parse(text=lm_text))
    
    test_pred <- predict(lm_model,newdata=test_dat)
    
    test_rmse <- sqrt(mean((test_pred-test_dat[,trait])^2))
    test_corr <- cor(test_pred,test_dat[,trait])
    
    fin_results <- data.frame(num_pcs = num_pcs,rmse = test_rmse,cor = test_corr[1])
    #fin_results <- list(num_pcs,test_rmse,test_corr[1])
    
    
  }
  ###############################################################
  
  # Do CV 
  cv_pc <- map_df(pc_iter,myLMFunction,train_dat=train_data,test_dat=valid_data,trait=trait)
  
  # Get Best PCs and Fit to Test Data
  best_pcs <- cv_pc$num_pcs[which.min(cv_pc$rmse)]
  my_best_fit <- myLMFunction(train_data,test_data,best_pcs,trait)
  results <- list(best_pcs,my_best_fit[[2]],my_best_fit[[3]])
  
  return(cv_pc)
  
}

modelAndFitPCR <- function(trait,full_data,train_test_ids){
  
  
  ####### Load Data ########
  
  train_ids <- train_test_ids[[1]]
  test_ids <- train_test_ids[[2]]
  
  train_data <- full_data %>% filter(Subject %in% train_ids$Subject)
  test_data <- full_data %>% filter(Subject %in% test_ids$Subject)
  
  ###########################
  
  ####### Clean Data ########
  
  keep_vars <- paste("^V\\d|^Age$|^Gender_M$|^",trait,"$",sep="")
  
  
  train_data$Gender_M <- ifelse(train_data$Gender=="M",1,0)
  train_clean <- train_data %>% select(matches(keep_vars))
  #train_clean[,!names(train_clean) == trait] <- scale(train_clean[,!names(train_clean) == trait])
  
  test_data$Gender_M <- ifelse(test_data$Gender=="M",1,0)
  test_clean <- test_data %>% select(matches(keep_vars))
  #test_clean[,!names(test_clean) == trait] <- scale(test_clean[,!names(test_clean) == trait])
  
  rm(train_data)
  rm(test_data)
  
  pcr_txt <- paste0("pcr(",trait," ~., data = train_clean, validation = CV)")
  
  pcr_fit <- eval(parse(text=pcr_txt))
  
 
  #test_pred <- predict(my_fit,newx=test_x,s="lambda.min")
  
  #test_rmse <- sqrt(mean((test_pred-test_y)^2))
  #test_corr <- cor(test_pred,test_y)
  
  fin_results <- list(pcr_fit,train_clean,test_clean)
  #fin_results <- list(ridge_cv,test_x); 
}


modelAndFitGLMNET <- function(trait,alpha,full_data,train_test_ids){
  

  ####### Load Data ########
  
  train_ids <- train_test_ids[[1]]
  test_ids <- train_test_ids[[2]]

  train_data <- full_data %>% filter(Subject %in% train_ids$Subject)
  test_data <- full_data %>% filter(Subject %in% test_ids$Subject)

  rm(full_data)
  
  ###########################
  
  ####### Clean Data ########
  
  keep_vars <- paste("^V\\d|^Age$|^Gender_M$|^",trait,"$",sep="")
  
  
  train_data$Gender_M <- ifelse(train_data$Gender=="M",1,0)
  train_clean <- train_data %>% select(matches(keep_vars))
  #train_clean[,!names(train_clean) == trait] <- scale(train_clean[,!names(train_clean) == trait])
  
  test_data$Gender_M <- ifelse(test_data$Gender=="M",1,0)
  test_clean <- test_data %>% select(matches(keep_vars))
  #test_clean[,!names(test_clean) == trait] <- scale(test_clean[,!names(test_clean) == trait])
  
  rm(train_data)
  rm(test_data)
  
  ####### Recipes Method (DOES NOT WORK WITH DOGWOOD 10/3/2022) ######
  
  #keep_vars <- paste("^V\\d|^Age$|^Gender$|^",trait,"$",sep="")
 
  #recipe_txt <- paste0("recipe(",trait," ~., data = train_data)")
  
  #print("B4 HCP_REC")
  #hcp_rec <- 
  #  eval(parse(text=recipe_txt)) %>%
  #  step_rm(!matches(keep_vars)) %>% # Remove all predictors except Age, Gender, and Vectorized Matrices 
  #  step_dummy(Gender) %>% 
  #  step_normalize(everything(),-all_outcomes())

  #print("AFTER HCP_REC")
 
  #train_clean <- hcp_rec %>% prep() %>% bake(train_data)
  #test_clean <- hcp_rec %>% prep() %>% bake(test_data)
  
  # Format Data Frames as Matrices For GLMNET
  
  train_x <- as.matrix(train_clean %>% select(!(any_of(trait))))
  train_y <- as.matrix(train_clean %>% select(any_of(trait)))
  
  test_x <- as.matrix(test_clean %>% select(!(any_of(trait))))
  test_y <- as.matrix(test_clean %>% select(any_of(trait)))
  
  rm(train_clean)
  rm(test_clean)


  # Run Repeated GLMNET 

  num_repeat <- 10 #Increase later for repeated GLMNET?
  cv_lambdas <- NULL
  for(i in 1:num_repeat) {

    cv_fit <- cv.glmnet(train_x,train_y,nfolds=5,alpha=alpha,standardize=TRUE)
    fit_err <- data.frame(cv_fit$lambda,cv_fit$cvm)
    cv_lambdas <- rbind(cv_lambdas, fit_err) 

  }
   
  # Mean CVM for Each Lambda
  cv_lambdas <- aggregate(cv_lambdas[, 2], list(cv_lambdas$cv_fit.lambda), mean)

  # Select the best one
  bestindex <- which(cv_lambdas[2]==min(cv_lambdas[2]))
  bestlambda <- cv_lambdas[bestindex,1]

  # Fit glmnet at this lambda

  my_fit <- glmnet(train_x,train_y,lambda=bestlambda,alpha=alpha)
  
  test_pred <- predict(my_fit,newx=test_x)
  
  test_rmse <- sqrt(mean((test_pred-test_y)^2))
  test_corr <- cor(test_pred,test_y)
  
  #fin_results <- list(test_rmse,test_corr,cv_lambdas,train_ids,test_ids,full_data)
  #fin_results <- list(test_rmse,test_corr,test_pred,test_y); 
  fin_results <- list(test_rmse,test_corr); 
}
modelAndFitGLMNETSCORES <- function(trait,alpha,full_data,train_test_ids){
  
  
  ### Preparing Single Train/Test Split of Data for GLMNET ###
  
  ####### Load Data ########
  
  train_ids <- train_test_ids[[1]]
  
  test_ids <- train_test_ids[[2]]
  
  train_data <- full_data %>% filter(Subject %in% train_ids$Subject)
  test_data <- full_data %>% filter(Subject %in% test_ids$Subject)
  
  # Create CV Splits on train (For validating # of PCs)
  train_cv_splits <- vfold_cv(train_data,v=10)
  
  
  rm(full_data)
  
  ###########################
  
  ####### Clean Data ########
  
  # Keep these variables
  keep_vars <- paste("^scPC\\d|^Age$|^Gender$|^Subject$|^",trait,"$",sep="")
  train_data <- train_data %>% select(matches(keep_vars))
  test_data<- test_data %>% select(matches(keep_vars))

  ### Create Sequence of PCs to Validate ###
  
  pc_iter_1 = seq(10,300,20)
  pc_iter_2 = seq(301,700,5)
  pc_iter = c(pc_iter_1,pc_iter_2)
  #pc_iter = c(10,20,30,80)
  
  ######### PC Cross Validation Functions ##########
  
  # This function created training data retaining num_pcs pca components. 
  # It then creates cross validation splits of this training data 
  # It then passes each validatin split the the preScoresSplits function 
  
  splitPCScores<- function(train_data,trait,alpha,num_pcs,num_repeat,train_splits){
    
    map_df(train_splits$splits,prepScoresSplit,num_pcs=num_pcs,trait=trait,alpha=alpha,num_repeat=num_repeat) %>% group_by(num_pcs) %>% summarize(mean_RMSE = mean(rmse), n = length(rmse))
  }

  # This function prepares a single validation split for glmnet fitting
  prepScoresSplit <- function(splitObj,num_pcs,trait,alpha,num_repeat){
    
    train_dat <- analysis(splitObj)
    test_dat <- assessment(splitObj)
    
    in_pcs <- sprintf("scPC%s",seq(num_pcs))
    train_dat <- train_dat %>% select(any_of(c("Subject",trait,"Age","Gender",in_pcs)))
    test_dat <- test_dat %>% select(any_of(c("Subject",trait,"Age","Gender",in_pcs)))
    
    
    train_text <- paste0("model.matrix(",trait,"~.-Subject,data=train_dat)")
    test_text <- paste0("model.matrix(",trait,"~.-Subject,data=test_dat)")
    
    train_x <- eval(parse(text=train_text))[,-1] # Remove Intercept (glmnet adds back in)
    test_x <- eval(parse(text=test_text))[,-1] # Remove Intercept (glmnet adds back in)
    
    train_y <- data.matrix(train_dat %>% select(any_of(trait)))
    test_y <- data.matrix(test_dat %>% select(any_of(trait)))
    
    run_glmnet_rmse <- repeatedGLMNet(train_x,train_y,test_x,test_y,alpha,5)
    
    split_result <- data.frame(num_pcs = num_pcs,rmse = run_glmnet_rmse[[1]],cor = run_glmnet_rmse[[2]])
    
  }
  
  
  # This function performs repeated glmnet fitting 
  repeatedGLMNet <- function(train_x,train_y,test_x,test_y,alpha,num_repeat){
    
    cv_lambdas <- NULL
    for(i in 1:num_repeat) {
      
      cv_fit <- cv.glmnet(train_x,train_y,nfolds=10,alpha=alpha,standardize=TRUE)
      fit_err <- data.frame(cv_fit$lambda,cv_fit$cvm)
      cv_lambdas <- rbind(cv_lambdas, fit_err) 
      
    }
    
    # Mean CVM for Each Lambda
    cv_lambdas <- aggregate(cv_lambdas[, 2], list(cv_lambdas$cv_fit.lambda), mean)
    
    # Select the best one
    bestindex <- which(cv_lambdas[2]==min(cv_lambdas[2]))
    bestlambda <- min(cv_lambdas[bestindex,1])
    
    # Fit glmnet at this lambda
    my_fit <- glmnet(train_x,train_y,lambda=bestlambda,alpha=alpha)
    
    test_pred <- predict(my_fit,newx=test_x)
    
    test_rmse <- sqrt(mean((test_pred-test_y)^2))
    test_corr <- cor(test_pred,test_y)
    
    fin_results <- list(test_rmse,test_corr[1]); 
    
    }
  

  
  ####################################################################
  
  ### Do Cross Validation on PC Scores ### 
  cv_pc <- map_df(pc_iter,splitPCScores,train_data=train_data,trait=trait,alpha=alpha,num_repeat=num_repeat,train_splits=train_cv_splits)
  
  best_pcs <- cv_pc$num_pcs[which.min(cv_pc$mean_RMSE)]
  
  ### Perform Final Fitting With Retained Scores ###
  
  
  in_pcs <- sprintf("scPC%s",seq(best_pcs))
  train_data <- train_data %>% select(any_of(c("Subject",trait,"Age","Gender",in_pcs)))
  test_data <- test_data %>% select(any_of(c("Subject",trait,"Age","Gender",in_pcs)))
  
  train_text <- paste0("model.matrix(",trait,"~.-Subject,data=train_data)")
  test_text <- paste0("model.matrix(",trait,"~.-Subject,data=test_data)")
  
  train_x <- eval(parse(text=train_text))[,-1] # Remove Intercept (glmnet adds back in)
  test_x <- eval(parse(text=test_text))[,-1] # Remove Intercept (glmnet adds back in)
  
  train_y <- data.matrix(train_data %>% select(any_of(trait)))
  test_y <- data.matrix(test_data %>% select(any_of(trait)))
  
  rm(train_data)
  rm(test_data)
  
  best_fit <- repeatedGLMNet(train_x,train_y,test_x,test_y,alpha,10)
  
  results <- list(best_pcs,best_fit[[1]],best_fit[[2]])
  
}


modelAndFitGLMNETSCORESV <- function(trait,alpha,full_data,train_test_valid_ids){
  
  ### Preparing Single Train/Test Split of Data for GLMNET ###
  
  ####### Load Data ########
  
  train_ids <- train_test_valid_ids[[1]]
  test_ids <- train_test_valid_ids[[2]]
  valid_ids <- train_test_valid_ids[[3]]
  
  train_data <- full_data %>% filter(Subject %in% train_ids$Subject)
  test_data <- full_data %>% filter(Subject %in% test_ids$Subject)
  valid_data <- full_data %>% filter(Subject %in% valid_ids$Subject)
  
  rm(full_data)
  
  ###########################
  
  ####### Clean Data ########
  
  # Keep these variables
  keep_vars <- paste("^scPC\\d|^Age$|^Gender$|^Subject$|^",trait,"$",sep="")
  train_data <- train_data %>% select(matches(keep_vars))
  test_data<- test_data %>% select(matches(keep_vars))
  valid_data<- valid_data %>% select(matches(keep_vars))
  
  ### Create Sequence of PCs to Validate ###
  
  pc_iter_1 = seq(10,300,10)
  pc_iter_2 = seq(301,700,5)
  pc_iter = c(pc_iter_1,pc_iter_2)
  #pc_iter = c(10,20,30,40,50)

  # This function performs repeated glmnet fitting 
  repeatedGLMNet <- function(train_x,train_y,test_x,test_y,alpha,num_repeat){
    
    cv_lambdas <- NULL

      for(i in 1:num_repeat) {
      
      cv_fit <- cv.glmnet(train_x,train_y,nfolds=10,alpha=alpha,standardize=TRUE)
      fit_err <- data.frame(cv_fit$lambda,cv_fit$cvm)
      cv_lambdas <- rbind(cv_lambdas, fit_err) 
      
    }
    
    # Mean CVM for Each Lambda
    cv_lambdas <- aggregate(cv_lambdas[, 2], list(cv_lambdas$cv_fit.lambda), mean)
    
    # Select the best one
    bestindex <- which(cv_lambdas[2]==min(cv_lambdas[2]))
    bestlambda <- min(cv_lambdas[bestindex,1])
    
    # Fit glmnet at this lambda
    my_fit <- glmnet(train_x,train_y,lambda=bestlambda,alpha=alpha)
    
    test_pred <- predict(my_fit,newx=test_x)
    
    test_rmse <- sqrt(mean((test_pred-test_y)^2))
    test_corr <- cor(test_pred,test_y)
    
    fin_results <- list(test_rmse,test_corr[1],test_y,test_pred); 
    
  }
  
  fitNumPCs <- function(train_dat,valid_dat,num_pcs,trait,alpha,num_repeat){
    
    in_pcs <- sprintf("scPC%s",seq(num_pcs))
    train_dat <- train_dat %>% select(any_of(c("Subject",trait,"Age","Gender",in_pcs)))
    valid_dat <- valid_dat %>% select(any_of(c("Subject",trait,"Age","Gender",in_pcs)))
    
    train_text <- paste0("model.matrix(",trait,"~.-Subject,data=train_dat)")
    valid_text <- paste0("model.matrix(",trait,"~.-Subject,data=valid_dat)")
    
    train_x <- eval(parse(text=train_text))[,-1] # Remove Intercept (glmnet adds back in)
    valid_x <- eval(parse(text=valid_text))[,-1] # Remove Intercept (glmnet adds back in)
    
    train_y <- data.matrix(train_dat %>% select(any_of(trait)))
    valid_y <- data.matrix(valid_dat %>% select(any_of(trait)))
   
    run_glmnet_rmse <- repeatedGLMNet(train_x,train_y,valid_x,valid_y,alpha,1)
    
    split_result <- data.frame(num_pcs = num_pcs,rmse = run_glmnet_rmse[[1]],cor = run_glmnet_rmse[[2]])
    
  }
  
  pc_cv <- map_df(pc_iter,fitNumPCs,train_dat = train_data,valid_dat = valid_data,alpha=alpha,num_repeat=1,trait=trait) #%>% group_by(num_pcs) %>% summarize(mean_RMSE = mean(rmse), n = length(rmse))

  best_pcs <- pc_cv$num_pcs[which.min(pc_cv$rmse)]
  
  ### Perform Final Fitting With Retained Scores ###
  
  
  in_pcs <- sprintf("scPC%s",seq(best_pcs))
  train_data <- train_data %>% select(any_of(c("Subject",trait,"Age","Gender",in_pcs)))
  test_data <- test_data %>% select(any_of(c("Subject",trait,"Age","Gender",in_pcs)))
  
  train_text <- paste0("model.matrix(",trait,"~.-Subject,data=train_data)")
  test_text <- paste0("model.matrix(",trait,"~.-Subject,data=test_data)")
  
  train_x <- eval(parse(text=train_text))[,-1] # Remove Intercept (glmnet adds back in)
  test_x <- eval(parse(text=test_text))[,-1] # Remove Intercept (glmnet adds back in)
  
  train_y <- data.matrix(train_data %>% select(any_of(trait)))
  test_y <- data.matrix(test_data %>% select(any_of(trait)))
  
  rm(train_data)
  rm(test_data)
  
  best_fit <- repeatedGLMNet(train_x,train_y,test_x,test_y,alpha,1)
  
  results <- list(best_pcs,best_fit[[1]],best_fit[[2]],best_fit[[3]],best_fit[[4]],train_test_valid_ids)
  
  
  
  
  
}

modelAndFitTidy <- function(trait,alpha,full_data,train_test_ids){
  
  ####### Load Data ########
  
  train_ids <- train_test_ids[[1]]
  test_ids <- train_test_ids[[2]]
  
  train_dat <- full_data %>% filter(Subject %in% train_ids$Subject)
  test_dat <- full_data %>% filter(Subject %in% test_ids$Subject)
  

  
  ################## Get Data Matrices  #####################
  
  # Create Initial Vars

  keep_vars <- paste("^V\\d|^Age$|^Gender$|^",trait,"$",sep="")
  recipe_txt <- paste0("recipe(",trait," ~., data = train_dat)")
  
  # Create Data Preprocessing Recipe
  hcp_rec <- 
    eval(parse(text=recipe_txt)) %>%
    step_rm(!matches(!!keep_vars)) %>% # Remove all predictors except Age, Gender, and Vectorized Matrices 
    step_dummy(Gender) %>% 
    step_normalize(everything(),-all_outcomes())
  
  ############################################################
  
  # Create Model
  ridge_mod <- linear_reg(mode = "regression",
                          penalty = tune(),
                          mixture = alpha) %>% set_engine("glmnet")
  # Create Workflow
  wf <- workflow() %>%
    add_model(ridge_mod) %>%
    add_recipe(hcp_rec)
  
  # Setup Parameter Tuning
  
  train_clean <- hcp_rec %>% prep() %>% bake(train_dat)
  test_clean <- hcp_rec %>% prep() %>% bake(test_dat)
  
  train_x <- as.matrix(train_clean %>% select(!all_of(trait)))
  train_y <- as.matrix(train_clean %>% select(all_of(trait)))
  
  dot_prod <- apply(train_x,2,function(x){
    abs(t(x)%*%train_y)
  })
  
  # See https://jerryfriedman.su.domains/ftp/glmnet.pdf
  
  if (alpha == 0)
  {
    max_pen <- log(max(dot_prod/900) / 0.0020)
    min_pen <- log(max_pen*0.001)
  }
  else
  {
    max_pen <- log(max(dot_prod/900) / alpha)
    min_pen <- log(max_pen*0.001)
  }
  
  tune_cv <- vfold_cv(train_dat,v=10,repeats=5)
  lambda_grid <- grid_regular(penalty(c(max_pen,min_pen),trans=log_trans(base = exp(1))), levels = 50)
  
  # Tune Model
  my_res <- wf %>%
    tune_grid(resamples = tune_cv, grid = lambda_grid) 
  
  # Select Model With Best RMSE
  best_mod <- my_res %>% select_best("rmse")
  
  final_fitted <- finalize_workflow(wf, best_mod) %>%
    fit(data = train_dat)
  
  # Predict on Test Set
  test_pred <- predict(final_fitted, test_dat)
  
  # Calculate RMSE and Corr on Test Set
  test_rmse <- sqrt(mean((test_pred$.pred-test_dat[,trait])^2))
  test_corr <- cor(test_pred$.pred,test_dat[,trait])
  
  fin_results <- list(test_rmse,test_corr)
  
}
repeatedGLMNET <- function(train_x,train_y,alpha,num_repeat){
  # Run Repeated GLMNET 
  
  num_repeat <- 5 #Increase later for repeated GLMNET?
  cv_lambdas <- NULL
  for(i in 1:num_repeat) {
    
    cv_fit <- cv.glmnet(train_x,train_y,nfolds=10,alpha=alpha,standardize=TRUE)
    fit_err <- data.frame(cv_fit$lambda,cv_fit$cvm)
    cv_lambdas <- rbind(cv_lambdas, fit_err) 
    
  }
  
  # Mean CVM for Each Lambda
  cv_lambdas <- aggregate(cv_lambdas[, 2], list(cv_lambdas$cv_fit.lambda), mean)
  
}
modelAndFitRF <- function(trait,full_data,train_test_ids){
  
  train_ids <- train_test_ids[[1]]
  test_ids <- train_test_ids[[2]]
  
  train_dat <- full_data %>% filter(Subject %in% train_ids$Subject)
  test_dat <- full_data %>% filter(Subject %in% test_ids$Subject)
  
  
  ####### Set Up Data Matrix ######
  keep_vars <- paste("^V\\d|^Age$|^Gender$|^",trait,"$",sep="")
  
  recipe_txt <- paste0("recipe(",trait," ~., data = train_dat)")
  
  hcp_rec <- 
    eval(parse(text=recipe_txt)) %>%
    step_rm(!matches(!!keep_vars)) %>% # Remove all predictors except Age, Gender, and Vectorized Matrices 
    step_dummy(Gender) %>% 
    step_normalize(everything(),-all_outcomes())
  
  tune_rf <- rand_forest(
    mtry = tune(),
    trees = 100,
    min_n = tune()
  ) %>% 
    set_mode("regression") %>% 
    set_engine("ranger")
  
  tune_rf_wf <- workflow() %>%
    add_recipe(hcp_rec) %>%
    add_model(tune_rf)
  
  
  
  rf_grid <- grid_regular(
    mtry(range = c(100,800)),
    min_n(range = c(10,25)),
    levels = 5
  )
  
  tree_folds <- vfold_cv(train_dat)
  
  tune_res <- tune_grid(
    tune_rf_wf,
    resamples = tree_folds,
    grid = rf_grid
  )
  
  best_params <- select_best(tune_res,"rmse")
  final_rf <- finalize_model(
    tune_rf, 
    best_params 
  )
  
  final_wf <- workflow() %>%
    add_recipe(hcp_rec) %>%
    add_model(final_rf) %>% 
    fit(data = train_dat)
  
  test_pred <- predict(final_wf,test_dat)
  
  test_rmse <- sqrt(mean((test_pred$.pred-test_dat[,trait])^2))
  test_corr <- cor(test_pred$.pred,test_dat[,trait])
  
  fin_results <- list(test_rmse,test_corr)
  
}
