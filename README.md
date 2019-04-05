# TypeTE
This pipeline is developped by Jainy Thomas (University of Utah) and Clement Goubert (Cornell University).
Elaborated with the collaboration of Jeffrey M. Kidd (University of Michigan)

Please adress all you questions and comments using the "issue" tab of the repository. This allows the community to search and find directly answers to their issues.
If help is not comming, you can email your questions at goubert.clement[at]gmail.com

## Purpose

TypeTE is a pipeline dedicated to genotype segregating Mobile Element Insertion (MEI) previously scored with a MEI detection tool such as MELT (Mobile Element Locator Tool, Gardner et al., 2017). TypeTE extracts reads from each detected polymorphic MEI and reconstruct acurately both presence and absence alleles. Eventually, remapping of the reads at the infividual level allow to score the genotype of the MEI using a modified version of Li's et al. genotype likelihood. This method drammatically improves the quality of the genotypes of reported MEI and can be directly used after a MELT run on both non-reference and reference insertions.

![picture alt](https://raw.githubusercontent.com/clemgoub/reGenotypeTE/master/Artboard%201.png "TypeTE overview")

TypeTE is divided in two modules: "Non-reference" to genotype insertions absent from the reference genome and "Reference" to genotype TE copies present in the reference genomes.

Currently TypeTE is working only with Alu insertions in the human genome but will be soon available for L1, SVA as well as virtualy any retrotransposon in any organism with a reference genome.

## Installation

### Dependencies

TypeTE rely on popular softwares often already in the toolbox of computational biologists! The following programs need to be installed and their path reported in the file ```"parameterfile_[No]Ref.init"```
Perl executable must be in the user path

* PERL https://www.perl.org/
* PYTHON 2.7 https://www.python.org/download/releases/2.7/ (Not compatible with Python 3)
    * pysam https://github.com/pysam-developers/pysam
* PARALLEL https://www.gnu.org/software/parallel/
* PICARD https://broadinstitute.github.io/picard/
* BEDTOOLS http://bedtools.readthedocs.io/en/latest/
* SEQTK https://github.com/lh3/seqtk
* BAMUTILS https://genome.sph.umich.edu/wiki/BamUtil
* SPADES http://cab.spbu.ru/software/spades/
* MINIA http://minia.genouest.org/
* CAP3 http://seq.cs.iastate.edu/cap3.html
* BLAST ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/
* BWA http://bio-bwa.sourceforge.net/bwa.shtml
* BGZIP http://www.htslib.org/doc/bgzip.html
* TABIX http://www.htslib.org/doc/tabix.html

### Download and install

1. Clone from git repository:

```sh
git clone https://github.com/clemgoub/TypeTE
cd TypeTE
```

2. Complete the fields associated to the path of each dependent program in the files ```"parameterfile_Ref.init"``` and ```"parameterfile_NoRef.init"```

3. And that's it!

- - - -

## Files preparation

You will need:

1. __A vcf/vcf.gz file (VCF)__ such as generated by the MELT discovery workflow. Examples are available in the folder "test_data". The vcf file must contain on Reference or Non-reference loci according to the module chosen. Loci/individuals must be sampled from the original vcf/vcf.gz using the following flag `--recode-INFO-all` in vcftools so the subsetted vcf will be compatible with TypeTE. If a new vcf is created specially for TypeTE, the following tags must be present in the "INFO" field (column ):
* MEINFO= with predicted subfamily (Repbase name) and orientation of the TE (ex: MEINFO=AluYa5,.,.,+ | if the subfamily is unknown: MEINFO=AluUndef;.,.,+)
* TSD= to indicate the predicted TSD (ex: TSD=AATAGAATTAGCAATTTTG | if no TSD detected TSD=null)

example:
```
##fileformat=VCFv4.1
##<HEADER OF THE VCF FILE>
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	NA07056	NA11830	NA12144
1	72639020	ALU_umary_ALU_244	C	<INS:ME:ALU>	.	.	MEINFO=AluUndef,4,281,-;TSD=AGCAATCTTATTTTC	GT	0|1	0|0	0|1
10 69994906 ALU_umary_ALU_8067 G <INS:ME:ALU> . . MEINFO=AluUndef,8,280,+;TSD=AATAGAATTAGCAATTTTG GT 0|0 0|1 0|1
```

note: these fields are not necessary for the Reference module where these will be extracted from the reference genome

2. __bam files__ for each individual found in the vcf file

3. a two column __tab separated table with the sample name and corresponding bam name (BAMFILE)__:

```
sample1 sample1-xxx-file.bam
sample2 sample2-yyy-file.bam
sample3 sample3-zzz-file.bam
```

4. __Reference genome (GENOME)__ in fasta format (to date tested with hg19 and hg38). In another reference genome is used, you will need to update the RepeatMasker track corresponding to your reference as well as the repeat you want to genotype.

5. __RepeatMasker Track__ a .bed files reporting each reference MEI insertion masked by RepeatMasker for the reference sequence provided. The family names must match the names of the consensus given in the RM_FASTA field. _(provided by default for Alu on hg19 and hg38)_ 

6. __RepeatMasker Consensus (RM_FASTA)__ a .fasta file with the consensus sequences of the repeats analysed _(provided by default for Alu)_ 

7. __Edit the file "parameterfile_NoRef.init" or "parameterfile_Ref.init"__ following the indications within:

```sh
### MAIN PARAMETERS
## input
# user data
VCF="/home/xxx/MELT.vcf" #Path to MELT vcf (.vcf or .vcf.gz) must contain INFO field with TSD, MEI type and strand
BAMPATH="/vbod2/xxx/bams" # Path to the folder containing your bam files
BAMFILE="/home/xxx/bams.txt" # <indiv_name> <bam_name> (two fields tab separated table)
# genome data
RM_TRACK="./Ressources/RepeatMasker_Alu_hg19.bed" # set by default for hg19 / use ./Ressources/RepeatMasker_Alu_hg38.bed for hg38 alignments
RM_FASTA="./Ressources/refinelib" # set by default to be compatible with the Repeat Masker track for Alu included in the package
# output
OUTDIR="/home/cgoubert/CorrectHet" # Path to place the output directory (will be named after PROJECT); OUTDIR must exist
PROJECT="TEST_400-100" # Name of the project (name of the folder)

### OPTIONS
## mendatory parameters
individual_nb="10" # number of individual per job (try to minimize that number)
CPU="40" # number of CPU (try to maximize that number such as CPU x individual_nb ~= total nb of individuals)
GENOME="" # Path the the reference genome sequence
## non-mendatory parameters
MAP="NO" #OR NO # to give mappability score of MEI (experimental)

### DEPENDENCIES PATH
PARALLEL="/usr/bin/parallel" #Path to the GNU Parallel program (executable)
PICARD="/home/xxx/software/picard-2.9.2" #Path to Picard Tools (executable)
BEDTOOLS="/home/xxx/bin/bedtools2/bin" #Path to bedtools (folder)
SEQTK="/home/xxx/software/seqtk" (folder)
BAMUTILS="/home/xxx/software/bamUtil" (folder)
SPADES="/home/xxx/software/SPAdes-3.11.1-Linux/bin" #Path to spades bin directory (to locate spades.py and dispades.py)
MINIA="/home/xxx/software/minia-v2.0.7-Source/build/bin" #Path to minia bin directory
CAP3="/home/xxx/software/CAP3" #Path to CAP3 directory
BLAST="/home/xxx/software/ncbi-blast-2.6.0+/bin" #Path to blast bin directory
BWA="/home/xxx/bin/bwa-0.7.16a/bwa" #Path to bwa
BGZIP="/usr/local/bin/bgzip" #Path to bgzip
TABIX="/usr/local/bin/tabix" #Path to tabix
# /!\ PERL MUST BE IN PATH /!\
```

- - - -

## Running TypeTE

1. Fill the appropriated ```parameterfile_[No]Ref.init``` according to your local paths and files
2. Run the following command in the TypeTE folder:

```sh
nohup ./run_TypeTE_[N]R.sh &> TypeTE.log &
```

Use ```./run_TypeTE_R.sh``` for reference insertions and ```./run_TypeTE_NR.sh``` for non-reference insertions.

- - - -

## Test runs

### Non-reference insertions

We have prepared a small tutorial/test-run to check if all the components of TypeTE works perfectly.

We are going to run the pipeline on 2 loci of 3 individuals from the 1000 Genome Project.

1. Download the bam and bam.bai files

Within the TypeTE folder, type:
```sh
cd test_data
wget ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/NA07056/alignment/NA07056.mapped.ILLUMINA.bwa.CEU.low_coverage.20130415.bam
wget ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/NA07056/alignment/NA07056.mapped.ILLUMINA.bwa.CEU.low_coverage.20130415.bam.bai
wget ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/NA11830/alignment/NA11830.mapped.ILLUMINA.bwa.CEU.low_coverage.20120522.bam
wget ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/NA11830/alignment/NA11830.mapped.ILLUMINA.bwa.CEU.low_coverage.20120522.bam.bai
wget ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/NA12144/alignment/NA12144.mapped.ILLUMINA.bwa.CEU.low_coverage.20130415.bam
wget ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/NA12144/alignment/NA12144.mapped.ILLUMINA.bwa.CEU.low_coverage.20130415.bam.bai
```
The corresponding bam/bam.bai files will be downladed into <yourpath>/TypeTE/test_data
  
2. Copy the parameterfile_NoRef.init template present in <yourpath>/TypeTE/test_data to the main folder
  
```sh
cp parameterfile_NoRef.init ../
cd ../
```

3. Edit the parameterfile_NoRef.init according to your dependancies and local path (but do not change anything else!)

4. Run TypeTE

```sh
nohup ./run_TypeTE_NR.sh &> TypeTE_TESTRUN.log &
```

5. Expected results

The genotype from the original vcf (<>/TypeTE/test_data/test_data_nonref.vcf) are the following

|         | 1_72639020 | 10_69994906 |
|---------|------------|-------------|
| NA07056 | 1          | 0           |
| NA11830 | 0          | 1           |
| NA12144 | 1          | 1           |

After running the test, you can convert your output vcf.gz into a 012 table using:

```sh
vcftools --gzvcf TEST_dataALU.TypeTE.vcf.gz --012
```

The new genotype should be 

|         | 1_72639020 | 10_69994906 |
|---------|------------|-------------|
| NA07056 | 2          | 0           |
| NA11830 | 0          | 2           |
| NA12144 | 2          | 1           |

```diff
- The results of this test run are not expected to reflect the true genotypes -
- since they are generated with only 3 individuals                            -
```


## Reference-insertions

We will here genotype two reference loci in the same three individuals:

1. Copy the parameterfile_Ref.init present in <yourpath>/TypeTE/test_data to the main folder
  
```sh
cp parameterfile_NoRef.init ../
cd ../
```

2. Edit the parameterfile_NoRef.init according to your dependancies and local path (but do not change anything else!)

3. Run TypeTE

```sh
nohup ./run_TypeTE_R.sh &> TypeTE_TESTRUN_ref.log &
```
4. Expected results

The genotype from the original vcf (<>/TypeTE/test_data/test_data_ref.vcf) are the following

|         | 5_88043138 | 6_7717367 |
|---------|------------|-------------|
| NA07056 | 1          | 1           |
| NA11830 | 1          | 2           |
| NA12144 | 1          | 1           |

After running the test, you can convert your output vcf.gz into a 012 table using:

```sh
vcftools --gzvcf TEST_dataALU.TypeTE.vcf.gz --012
```

The new genotype should be 

|         | 5_88043138 | 6_7717367 |
|---------|------------|-------------|
| NA07056 | 0          | 0           |
| NA11830 | 1          | 1           |
| NA12144 | 1          | 1           |

```diff
- The results of this test run are not expected to reflect the true genotypes -
- since they are generated with only 3 individuals                            -
```
