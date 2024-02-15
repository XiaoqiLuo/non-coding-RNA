# Small RNA Sequencing 
This workspace provides a pipeline for processing small RNA sequencing data. It will handle fastq files to the small RNA sequencing quantified matrix. In addition, the workspace also provides a notebook for differential expression analysis with the small RNA sequencing quantified matrix.

## Workflow 
This pipeline is adapted from sRNAnalyzer, a flexible and customizable pipeline for small RNA sequencing data analysis. This pipeline consists of three main functional modules, data pre-processing, sequence mapping/comparison and result summary. 

<img style="width:600px" src="https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5716150/bin/gkx999fig1.jpg" align="center" />

### Data pre-processing module
- **Cutadapt** Adapter sequences trimming and empty reads removing. Adapter trimming is especially important for sRNA-Seq data analysis, since most of the sequence reads are short and may contain part or all of the adapter sequences. If the adapter sequences are not completely removed, mapping accuracy will be significantly affected.
- **Prinseq** Quality control. Remove low-quality reads.
- **fastx_collapser** generate a file where identical reads are collapsed together to accelerate sequence alignment.

### Sequence mapping and alignment module
- **Bowtie** maps read sequences against database sequences by applying full alignment.

### Result summarization module
The result summarization module provides reports for various mapping results. The results can be summarized at different levels—from individual transcripts (such as individual miRNAs) to different phyla.
The miRNA mapping results The pipeline can summarize read counts for each individual mature or precursor miRNA, as well as aggregate read counts for each nucleotide across individual precursor miRNAs. Moreover, sRNAnalyzer provides mismatch counts and rates for all the possible 16 mismatch types (A|T|G|C > A|T|G|C|N) at each position. This function allows researchers to review miRNA sequence variations in the sample.


## Reference

- Workflows<br>
Wu, Xiaogang et al. “sRNAnalyzer-a flexible and customizable small RNA sequencing data analysis pipeline.” Nucleic acids research vol. 45,21 (2017): 12140-12151. doi:10.1093/nar/gkx999

- Notebooks<br>
Credit to small RNA sequencing differential expression analysis tutorial provided by Abreu RNA lab, University of Edinburgh: https://cei.bio.ed.ac.uk/R_Seq_2021/practical08.html

