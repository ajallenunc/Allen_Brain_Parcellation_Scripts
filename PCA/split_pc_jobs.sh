#!/bin/bash
PARC_LIST=($1)
ADD_DENDO=$2
HORIZ_CUT=$3
LOG_T=0
for i in "${PARC_LIST[@]}"; do
     for k in 10 25 68 100 150 200 250 300 400 500 600 700 800 900 1000;do
     #for k in 200 250 300 400 500 600 700 800 900 1000;do
     #for k in 700 800 900 1000;do
     #for k in 10 25 68;do
        sbatch pca_job_template.sh $i $k $ADD_DENDO $HORIZ_CUT $LOG_T
     done
done

                                        


