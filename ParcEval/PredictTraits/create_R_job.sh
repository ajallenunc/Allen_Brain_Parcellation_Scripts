#!/bin/bash
PARC_LIST=($1)
TRAIT_LIST=($2)
#MIXTURE=$3
for t in "${TRAIT_LIST[@]}";do
    for p in "${PARC_LIST[@]}";do
        for k in 10 25 68 100 200 250 300 400 500 600 700 800 900 1000;do #150 200 250 300 400 500 600;do
        #for k in 10 25 68 100 200 250 300 400;do
        #for k in 500 600 700 800 900 1000;do #150 200 250 300 400 500 600;do
        #for k in 200 250 300 400 500 600;do
        #for k in 10 25 68 100 200 250 300 400 500 600;do
        #for k in 700 800 900 1000;do
            #for m in 0 1 0.5;do
            #for m in 0 1 0.5;do
            #for m in 1 0.5;do
            for m in 0;do
                #sbatch R_job_template.sh $t $p $k $m
                sbatch predict_with_scores.sh $t $p $k $m
            done
        done

    done
done
