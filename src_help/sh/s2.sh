#!/bin/bash

#SBATCH -p short
#SBATCH -t 0-10:00
#SBATCH -n 1
#SBATCH --mem-per-cpu=4G
#SBATCH --job-name s2
#SBATCH -o ../log/%x_%j.out
#SBATCH -e ../log/%x_%j.err

module load gcc/6.2.0
module load samtools/1.3.1
module load bowtie2/2.2.9
module load perl/5.24.0
eval `perl -Mlocal::lib=/home/ak583/perl5-O2`

# include parse_yaml function
. parse_yaml.sh

# read yaml file
yamlfile=$1
eval $(parse_yaml $yamlfile "config_")

# access yaml content
#~ sam=$config_output_sam

loc=$config_scripts_location
s2=$config_scripts_s2

###################### looking for the following genes:
#~ echo "command = perl $scripts/step2.pl $yamlfile"
perl $loc/$s2 $yamlfile
