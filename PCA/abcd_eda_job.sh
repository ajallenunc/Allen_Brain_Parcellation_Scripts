#!/bin/bash
#SBATCH -p debug_queue
#SBATCH -n 50
#SBATCH --mem=500g
#SBATCH -t 4:00:00
#SBATCH --mail-type=end
#SBATCH --mail-user=aallen1@email.unc.edu

module add matlab/2020a

matlab -nodesktop -nosplash -singleCompThread -r ABCD_EDA
~
~

