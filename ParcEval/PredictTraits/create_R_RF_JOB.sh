#!/bin/bash
PARC_LIST=($1)
TRAIT_LIST=($2)
#MIXTURE=$3
for t in "${TRAIT_LIST[@]}";do
    for p in "${PARC_LIST[@]}";do
        for k in 10 25 68 100 150 200 250 300 400 500 600 700 800 900 1000;do
        #for k in 150 200 250 300 400 500 600;do
            sbatch R_RF_JOB_template.sh $t $p $k 
        done

    done
done
