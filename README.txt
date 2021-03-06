
IRAP - Integrated RNA-Seq Analysis Pipeline


Contents

1. Install
2. Update
3. Run IRAP 
4. Output files
5. Report problems
6. How to get help


============
* 1. Install
============

1.1 Get IRAP from the repository
   git clone http://nunofonseca.github.io/irap irap_clone

1.2 Install IRAP and all dependencies (3rd party software) to a directory (e.g. irap_install)
   ./irap_clone/scripts/irap_install.sh -a irap_install -s irap_clone

 Dependencies: check wiki for full list (https://github.com/nunofonseca/irap/wiki)

1.3 Setup the shell environment using the irap_setup.sh file: e.g., assuming that you installed IRAP in irap_install you could setup the environment using
   source irap_install/irap_setup.sh
or, assuming that you use Bash as your shell, add the contents of the irap_setup.sh file to your ~/.bash_profile file.

===========
* 2. Update
===========

2.1 Go to the irap directory obtained from the repository (see point 1 above in Install)
2.2 Get the updates
    git pull
2.3 Quick update the installation
    ./scripts/irap_install.sh -u -s .

==============
* 3. Run IRAP
==============

3.1. Prepare your  configuration file (an example is available in docs/myexp.conf)

3.2. Add the required data to the data directory (see docs/myexp.conf for a brief explanation):
       i) reference genome (file in FASTA format)
       ii) annotation (file in GTF format)
       iii) reads  (files in FASTQ format)

3.3. Run the analysis (this may take a long time)
    o Minimal command line options, e.g.,
       irap conf=myexp.conf

    o Define or override options given in the configuration file, e.g.,
       irap conf=myexp.conf mapper=tophat1 quant_method=htseq1 de_method=deseq

    o Use the irap_lsf command to speed up the analysis by exploiting
       multiple computers in a cluster with the LSF job scheduler.
       irap_lsf accepts the same parameters as irap but splits the
       analysis into multiple jobs with the aim of reducing the time
       to analyze the data, e.g,

       irap_lsf conf=myexp.conf 
       irap_lsf conf=myexp.conf mapper=tophat1 quant_method=htseq1 de_method=deseq
         
3.4. Check your results
    o Check the status of the files (created files versus expected files)
       irap [your options used to run the analysis] status

3.5. Get the list of programs used, their version and citation (if available)
       irap [your options used to run the analysis] show_citations

Features *under development*

3.6. Generate a report based on the results produced (this may take a long time to complete)
       irap [same options used to run the analysis] report

3.7. Setup and upload some results as tracks to a web based genome
       browser (this may take a long time to complete).  
       irap [same options used to run the analysis] report_browser

=================
* 4. Output files 
=================

All output files produced by IRAP will be placed in sub-folders under
the folder with the name of the experiment defined in the
configuration file. The directory tree created has the following
structure (where <X> denotes the value of the parameter X):

<name>/
  + data
  + report
  + <mapper>/
       + <quant_method>/
	       + <de_method>/
       
       
 Contents of the different folders:

 - data/: contains mainly the FASTQ files (filtered if the qc option
 is enabled) with the reads given as input to the mapper <mapper>.

 - <mapper>/: contains all the output files generated by the mapper
 <mapper>. It also includes the BAM files sorted by name, by
 chromosomal position and respective indexes.

 - <quant_method>/: contains the output files generated by the
  quantification method <quant_method> together with TSV files
  containing a matrix with the number of reads per gene
  (genes.raw.<quant_method>.tsv), transcript
  (transcripts.raw.<quant_method>tsv) and exon
  (exons.raw.<quant_method>.tsv) for each BAM file.

 - <de_method>/: contains the output files generated by the
  differential expression method <de_method> and a summary tsv file
  (<contrast>.genes_de.tsv), for each contrast (defined in the
  configuration file), with fold change, p-value, adjusted p-value,
  gene name, GO, and other information for each gene. Currently, IRAP
  only supports differential expression analysis at gene level.

====================
* 5. Report problems 
====================

Errors may occur while running one of the many different pieces of
software included in IRAP (e.g., a mapper, a quantification method,
etc). If this happens then the error should be reported directly to
the developers of the program.

The authors of IRAP always appreciate receiving suggestions for
improvements, and reports of bugs in the pipeline or in the
documentation. Please submit them through
http://nunofonseca.github.io/irap/

