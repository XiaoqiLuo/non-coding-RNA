version 1.0

workflow lncRNA_pipeline {
    input {
        # input
        File fastq1
        File fastq2
        String samplename
        File ref_fasta_indexes
        File splice_site
        File annotate_gtf
    }
    call lncRNA_pipeline_run{
        input:
            fastq1 = fastq1,
            fastq2 = fastq2,
            samplename = samplename,
            ref_fasta_indexes = ref_fasta_indexes,
            splice_site = splice_site
    }
    call stringtie{
        input:
            samplename = samplename,
            bam = lncRNA_pipeline_run.bam,
            annotate_gtf = annotate_gtf
    }
    output{
        File clean_fq1 = lncRNA_pipeline_run.clean_fq1
        File clean_fq2 = lncRNA_pipeline_run.clean_fq2
        File novel_splicesite_bed = lncRNA_pipeline_run.novel_splicesite_bed
        File bam = lncRNA_pipeline_run.bam
        File sorted_bam = stringtie.sorted_bam
        File stringtie_gtf = stringtie.stringtie_gtf
    }

}

task lncRNA_pipeline_run {
    input {
        # input
        File fastq1
        File fastq2
        String samplename
        File ref_fasta_indexes
        File splice_site
        String MEMORY = "84 GB"
        String DISK = "100 GB"
    }
    command {
        set -e pipefail

        # quality control
        # make sure paths are absolute
        fastq1_abs=${fastq1}
        if [[ $fastq1_abs != /* ]]; then
            fastq1_abs=$fastq1_abs
        fi
        fastq2_abs=${fastq2}
        if [[ $fastq2_abs != /* ]]; then
            fastq2_abs=$fastq2_abs
        fi
        ref_fasta_indexes_abs=${ref_fasta_indexes}
        if [[ $ref_fasta_indexes_abs != /* ]]; then
            ref_fasta_indexes_abs=$ref_fasta_indexes_abs
        fi
        splice_site_abs=${splice_site}
        if [[ $splice_site_abs != /* ]]; then
            splice_site_abs=$splice_site_abs
        fi


        fastp -i $fastq1_abs -I $fastq2_abs -o ${samplename}_clean_1.fastq.gz -O ${samplename}_clean_2.fastq.gz --html ${samplename}.html --correction -w 23 -l 60

        # read alignment with hisat2
        tar -xzvf $ref_fasta_indexes_abs

        hisat2 -p 32 --dta -x $PWD/hisat2/hg38 -1 ${samplename}_clean_1.fastq.gz -2 ${samplename}_clean_2.fastq.gz \
            --add-chrname --rna-strandness RF --rg-id ${samplename} --rg SM:${samplename} \
            --rg PL:illumina --rg CN:Novogene -S ${samplename}.sam \
            --known-splicesite-infile $splice_site_abs \
            --novel-splicesite-outfile gencode.v27.annotation.splice_site.bed --seed 168 

        sambamba view ${samplename}.sam -S -f bam -t 26 | sambamba sort --sort-by-name -t 20 -o ${samplename}_sort.bam /dev/stdin
        rm ${samplename}.sam

    }   
    output {
        File clean_fq1="${samplename}_clean_1.fastq.gz"
        File clean_fq2="${samplename}_clean_2.fastq.gz"
        File novel_splicesite_bed="gencode.v27.annotation.splice_site.bed"
        File bam = "${samplename}_sort.bam" 
        # File stringtie_gtf = "${samplename}.stringtie.gtf"
    }
    runtime {
        docker: "registry-vpc.miracle.ac.cn/gznl/lncrna"
        continueOnReturnCode: 0
        cpu:"10"
        memory:"${MEMORY}" 
        disk: "${DISK}"
    }
}

task stringtie {
    input {
        # input
        String samplename
        File bam
        File annotate_gtf
        String MEMORY = "84 GB"
        String DISK = "100 GB"
    }
    command <<<
        set -e pipefail
        
        sambamba view -t 20 -h ~{bam} |sed 's/SN:chrMT/SN:chrM/g'|sed -r 's/\tchrMT/\tchrM/g' | sed \
         -r "s/chr(GL[0-9]{6})/\1/g" |sambamba view -t 20 -f bam -S -o ~{samplename}_sorted.bam /dev/stdin && sambamba sort -t 10 \
         -o ~{samplename}_sortedbycoord.bam ~{samplename}_sorted.bam
        
        # transcript assemble with stringtie
        stringtie -a 10 --rf -p 15 -G ~{annotate_gtf} -o ~{samplename}.stringtie.gtf ~{samplename}_sortedbycoord.bam 
    >>>
    output {
        File sorted_bam = "${samplename}_sortedbycoord.bam"
        File stringtie_gtf = "${samplename}.stringtie.gtf"
    }
    runtime {
        docker: "registry-vpc.miracle.ac.cn/gznl/lncrna"
        continueOnReturnCode: 0
        cpu:"10"
        memory:"${MEMORY}" 
        disk: "${DISK}"
    }
}
