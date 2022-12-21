#!/bin/bash
#SBATCH -p 528_queue
#SBATCH -n 50
#SBATCH --mem=400g
#SBATCH -t 5:00:00
#SBATCH --mail-type=end
#SBATCH --mail-user=aallen1@email.unc.edu

module add matlab/2020a

PARC=${1}
K=${2}
DENDO=$3
HORIZ_CUT=$4
LOG_T=$5
matlab -nodesktop -nosplash -singleCompThread -r "getPCScoresAndData(\"$PARC\",$K,$DENDO,$HORIZ_CUT,$LOG_T)"
~
~

