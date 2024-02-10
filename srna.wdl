version 1.0

workflow sRNA_pipeline {
    input {
        # input
        File fastq
        File pip_config
        File db
        String sample_name
    }
    call sRNA_pipeline_run{
        input:
            fastq = fastq,
            pip_config = pip_config,
            db = db,
            sample_name = sample_name,
    }
    output{
        File log1 = sRNA_pipeline_run.log1
        File log2 = sRNA_pipeline_run.log2
        File log3 = sRNA_pipeline_run.log3
        File preprocess = sRNA_pipeline_run.preprocess
        File cutadapt = sRNA_pipeline_run.cutadapt
        File processed_dist = sRNA_pipeline_run.processed_dist
        File processed_fa = sRNA_pipeline_run.processed_fa
        File processed_feature = sRNA_pipeline_run.processed_feature
        File processed_profile = sRNA_pipeline_run.processed_profile
        File alignment = sRNA_pipeline_run.alignment
        File summary = sRNA_pipeline_run.summary
        File profile = sRNA_pipeline_run.profile
        File feature = sRNA_pipeline_run.feature
        File matchCount = sRNA_pipeline_run.matchCount
    }

}

task sRNA_pipeline_run {
    input {
        # input
        File fastq
        File pip_config
        File db
        String sample_name
    }
    command {
        set -e pipefail

        fastq_abs=${fastq}
        pip_config_abs=${pip_config}
        db_abs=${db}

        if [[ $fastq_abs != /* ]]; then
            fastq_abs=$PWD/$fastq_abs
        fi
        if [[ $pip_config_abs != /* ]]; then
            pip_config_abs=$PWD/$pip_config_abs
        fi
        if [[ $db_abs != /* ]]; then
            db_abs=$PWD/$db
        fi
        
        fastq_abs=$(dirname "$fastq_abs" | cut -d '/' -f 1-)
        # preprocess fastq file
        echo /app/sRNAnalyzer/preprocess.pl --config $pip_config_abs > process.sh
        chmod 755 process.sh
        tmp_db=$PWD
        cp $fastq_abs/* ./
        ./process.sh 2&> ~{sample_name}_step1.log
        
        # # mapping and quantification
        # cd ../
        tar -xvf $db_abs 
        sed -i "1s|^|base:$PWD/sRNA_DBs\n|" $PWD/sRNA_DBs/DB_config.conf
        sed -i '2d' $PWD/sRNA_DBs/DB_config.conf
        echo /app/sRNAnalyzer/align.pl $tmp_db $pip_config_abs $PWD/sRNA_DBs/DB_config.conf > alignment.sh
        chmod 755 alignment.sh
        ./alignment.sh 2&> ~{sample_name}_step2.log

        # result summary
        mkdir -p rawdata/result
        chmod -R 777 rawdata/result
        echo /app/sRNAnalyzer/summarize.pl $PWD/sRNA_DBs/DB_config.conf --project $tmp_db/~{sample_name} > summary.sh
        chmod 755 summary.sh
        ./summary.sh  2&> ~{sample_name}_step3.log
    }
    output {    
        File log1="~{sample_name}_step1.log"
        File log2="~{sample_name}_step2.log"
        File log3="~{sample_name}_step3.log"
        File preprocess="process.sh"
        File cutadapt="~{sample_name}_Cutadapt.report"
        File processed_dist="~{sample_name}_Processed.dist"
        File processed_fa="~{sample_name}_Processed.fa"
        File processed_feature="~{sample_name}_Processed.feature"
        File processed_profile="~{sample_name}_Processed.profile"
        File alignment="alignment.sh"
        File summary="summary.sh"
        File profile="~{sample_name}.profile"
        File feature="~{sample_name}_des.feature"
        File matchCount="~{sample_name}_matchCount.sum"
    }
    runtime {
        docker: "registry-vpc.miracle.ac.cn/gznl/srna_new"
        continueOnReturnCode: 0
    }
}
