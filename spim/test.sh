#!/bin/bash
for i in {1..100}     
do 
    echo "try $i" >> out.txt 
    ./spim -f spimos_gtu_1.s >> out.txt
    ./spim -f spimos_gtu_2.s >> out.txt
    ./spim -f spimos_gtu_3.s >> out.txt
done  