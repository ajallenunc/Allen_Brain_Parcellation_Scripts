#!/bin/bash

#SBATCH -p 528_queue
#SBATCH -n 60
#SBATCH --mem=500g
#SBATCH -t 5:00:00
#SBATCH --mail-type=end
#SBATCH --mail-user=aallen1@email.unc.edu

module add r/4.1.0

TRAIT=${1}
PARC=${2}
K=${3}
MIX=${4}

Rscript ./PredictCogTraitGLMNETScores.R $TRAIT $PARC $K $MIX 
#Rscript ./PredictCogTrait.R $TRAIT $PARC $K $MIX 

