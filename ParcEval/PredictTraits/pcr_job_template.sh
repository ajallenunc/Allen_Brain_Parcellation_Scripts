#!/bin/bash

#SBATCH -p debug_queue
#SBATCH -n 50  
#SBATCH --mem=500g
#SBATCH -t 4:00:00 
#SBATCH --mail-type=end
#SBATCH --mail-user=aallen1@email.unc.edu

module add r/4.1.0

TRAIT=${1}
PARC=${2}
K=${3}

Rscript ./PredictCogTraitPCR.R $TRAIT $PARC $K  
#Rscript ./PredictCogTrait.R $TRAIT $PARC $K $MIX 

