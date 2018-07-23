#!/bin/bash

#SBATCH -p medium
#SBATCH -t 5-00:00
#SBATCH -n 8
#SBATCH --mem-per-cpu=24G
#SBATCH --job-name asym
#SBATCH -o ../logs/%x_%j.out
#SBATCH -e ../logs/%x_%j.err

######################################
# USAGE: inside <prj>/src/
# sbatch s1a.sh ../config/HONDA_P2_V50.yaml
######################################

module load gcc/6.2.0
module load samtools/1.3.1
module load bowtie2/2.2.9
module load perl/5.24.0
module load star/2.5.4a

# include parse_yaml function
. parse_yaml.sh

# read yaml file
yamlfile=$1
eval $(parse_yaml $yamlfile "config_")

# check version
ver_expected="5.0"
if [[ $ver_expected = $config_version ]]
then
    echo ""
else
    echo "ERROR $0: wrong version of YAML file:"
    echo ">$ver_expected< expected, >$config_version< actually"
    echo
    exit 2
fi

# access yaml content
where=$config_alignment_fastq_dir
f1=$config_alignment_R1
f2=$config_alignment_R2

ref=$config_alignment_reference
#### the following is a kludge for o2 index location
ref=/n/groups/shared_databases/star_reference/$ref

sam=$config_alignment_SAM_name_base
workdir=$config_alignment_SAM_location

loc=$config_scripts_location
asym=$config_scripts_asymagic
##### now just do work

if [ -d $workdir ]
then
    echo "Using existing working directory [$workdir]"
else
    mkdir $workdir
fi
cd $workdir
h=`pwd`
here="$h/"
echo "now in $h"

echo "Aligning..."

STAR \
    --runThreadN 8 \
    --genomeDir $ref \
    --readFilesIn ${where}$f1 ${where}$f2 \
    --outSAMtype BAM SortedByCoordinate \
    --outSAMunmapped Within KeepPairs \
    --outSAMorder Paired \
    --outStd BAM_SortedByCoordinate > $here${sam}.bam

#echo -n "Samtools transforms... sam->bam... "
#samtools view -ubSh $here$sam.sam > $here${sam}.bam
echo -n "sort... "
samtools sort -l 0 -o $here${sam}.sorted.bam $here${sam}.bam
echo -n "index... "
samtools index $here${sam}.sorted.bam $here${sam}.sorted.bai
echo  "done "
#rm $here${sam}.bam
