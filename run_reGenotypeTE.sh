#! /bin/bash

###########################################
# reGenotypeTE - run_reGonotypeTE         #
#                                         #
# This is the main script of the pipeline #
#                                         #
# Author: Clement Goubert                 #
# Date: 04/2018                           #
# Version: 1.0                            #
###########################################

#load the user options, outdir path and dependencies paths
source parameterfile.init

#START
echo "###########################"
echo "#      reGenotypeTE       #"
echo "###########################"

#locate working directoty
# whereamI=$(pwd)

# #Creates the $OUTDIR

# {
# if [ $OUTDIR == "" ]; then
#     echo "OUTDIR not set, don't know where to create output folder..."
#     exit 0
# fi
# }

# mkdir -p $OUTDIR/$PROJECT

# #Creates the <project>.input in $OUTDIR/$PROJECT

# paste <(date | awk '{print $4}') <(echo "preparing input from MELT vcf...")

# ./input_from_melt.sh $VCF $PROJECT


# #Join ind names to coordinates and generate the list of locus/individuals ("$OUTDIR/$PROJECT/sample_file.txt.list.txt")

# paste <(date | awk '{print $4}') <(echo "DONE.")
# echo "Joining individuals and MEI coordinates..."

# perl makelist_v1.0.pl -t $BAMFILE -f $OUTDIR/$PROJECT/$PROJECT.input -p $OUTDIR/$PROJECT

# # split the input in order to paralellize read extraction

# paste <(date | awk '{print $4}') <(echo "DONE.")
# paste <(date | awk '{print $4}') <(echo "Splitting individuals for paralellization of read extraction...")

# perl 02_splitfile_jt_v3.0_pipeline.pl -f $OUTDIR/$PROJECT/file.list.txt -s yes -n $individual_nb -p $OUTDIR/$PROJECT

# # Process bams: extract reads from bam files and extract mappability

# paste <(date | awk '{print $4}') <(echo "Extracting reads and mappability scores...")

# #cd in splitfile directory
# cd  $OUTDIR/$PROJECT/splitbyindividuals

# cat ../List_of_split_files.txt | $PARALLEL -j $CPU --results $OUTDIR/$PROJECT/Process_bams "perl $whereamI/03_processbam_extract_GM_scoresv15.0.pl -t $BAMFILE -f {} -p $OUTDIR/$PROJECT -bl $BAMPATH -pt $PICARD -m yes -db jainys_db -u jainy -pd wysql123 -mt hg19wgEncodeCrgMapabilityAlign100mer_index" 


# #comes back to working dir
# cd $whereamI

#############################################################################################################################
################## MODULE 4: Find TE annotations and consensus using RepeatMasker track #####################################

paste <(date | awk '{print $4}') <(echo "Finding Repbase consensus for each MEI...")

# counting loci and dividing into subfiles for paralellization
total_locus=$(ls -lh $OUTDIR/$PROJECT/IGV | awk ' NR > 1 {print $NF}')
nb_locus=$(echo "total_locus" | wc -l)
per_file=$( echo "$nb_locus/$CPU" | bc)
if(($per_file < 1))
then 
	splitnb=$((1))
else
	splitnb=$(((nb_locus+1)/$CPU))
fi

mkdir -p $OUTDIR/$PROJECT/splitbylocus
split -l $splitnb <(echo "$total_locus") --additional-suffix .part $OUTDIR/$PROJECT/splitbylocus/locus_
ls $OUTDIR/$PROJECT/splitbylocus/locus_* > $OUTDIR/$PROJECT/splitbylocus/List_of_loci_files.txt

# Run in parallel find TE from Repbase
mkdir -p  $OUTDIR/$PROJECT/Repbase_intersect # creates the output folder if inexistent
rm -r $OUTDIR/$PROJECT/Repbase_intersect/position_and_TE # remove the output table for safety if one already exist
ls $OUTDIR/$PROJECT/splitbylocus/*.part | $PARALLEL --bibtex -j $CPU --results $OUTDIR/$PROJECT/Repbase_intersect "./identify_mei_from_RM.sh {} $OUTDIR/$PROJECT/Repbase_intersect"

# orienTE_extracTE.pl -d $OUTDIR/processbamout -t TE_directory_from_indetify_mei_from_RM.sh -l list_outout_from_indetify_mei_from_RM.sh -g ExtractGenomicSequences

# Extract the TE sequence
paste <(date | awk '{print $4}') <(echo "Extracting the TE sequences in fasta format...")

mkdir $OUTDIR/$PROJECT/Repbase_intersect/TE_sequences
awk '{print $3}' $OUTDIR/$PROJECT/Repbase_intersect/position_and_TE | sort | uniq | awk '{print $1"#SINE/Alu"}' > $OUTDIR/$PROJECT/Repbase_intersect/TE_headers

TEheads=$(cat $OUTDIR/$PROJECT/Repbase_intersect/TE_headers)
for head in $TEheads
do
	name=$(echo "$head" | sed 's/\#SINE\/Alu//g')
	echo "$name"
	perl -ne 'if(/^>(\S+)/){$c=$i{$1}}$c?print:chomp;$i{$_}=1 if @ARGV' <(echo "$head") $RM_FASTA > $OUTDIR/$PROJECT/Repbase_intersect/TE_sequences/$name"".fasta
done

rm $OUTDIR/$PROJECT/Repbase_intersect/TE_headers

paste <(date | awk '{print $4}') <(echo "Done! Results in $2")

##################################################### END OF MODULE 4 #####################################################
###########################################################################################################################

paste <(date | awk '{print $4}') <(echo "Assembling MEI, retreiving orientation and TSDs...")

# de_novo_create_input.sh (correct it, and modify Jainy's table before)

paste <(date | awk '{print $4}') <(echo "Generating input table for genotyping...")

