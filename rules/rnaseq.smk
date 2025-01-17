# download transcriptome annotation
rule txome_gtf:
    input:
        storage(
            "ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_43/gencode.v43.basic.annotation.gtf.gz",
        ),
    output:
        "rnaseq/ref/txome.chr{chrom}.gtf",
    cache: "omit-software"
    shell:
        "gzip -dc {input} | grep ^chr{wildcards.chrom} > {output}"


# download repeatmasker annotation
rule rmsk_gtf:
    input:
        storage(
            "https://labshare.cshl.edu/shares/mhammelllab/www-data/TEtranscripts/TE_GTF/GRCh38_Ensembl_rmsk_TE.gtf.gz",
        ),
    output:
        "rnaseq/ref/rmsk.chr{chrom}.gtf",
    cache: "omit-software"
    shell:
        "gzip -dc {input} | grep ^{wildcards.chrom} | awk '{{print \"chr\"$0}}' > {output}"


rule telocal_locInd:
    input:
        rules.rmsk_gtf.output,
    output:
        "rnaseq/ref/rmsk.chr{chrom}.gtf.locInd",
    conda:
        "../envs/telocal.yaml"
    script:
        "../scripts/telocal_locInd.py"


# download genome fasta
rule genome_fa:
    input:
        storage(
            "http://hgdownload.soe.ucsc.edu/goldenPath/hg38/chromosomes/chr{chrom}.fa.gz",
        ),
    output:
        "rnaseq/ref/genome.chr{chrom}.fa",
    cache: "omit-software"
    shell:
        "gzip -dc {input} > {output}"


# download transcriptome fasta
rule txome_fa:
    input:
        fa=storage(
            "ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_43/gencode.v43.transcripts.fa.gz",
        ),
        gtf=rules.txome_gtf.output,
    output:
        multiext(
            "rnaseq/ref/",
            "names.chr{chrom}.lst",
            "txome.chr{chrom}.fa",
        ),
    shell:
        """
        grep -o 'ENST[0-9]*\.[0-9]' {input.gtf} | sort | uniq | awk '{{print $1".*"}}' > {output[0]}
        gzip -dc {input.fa} | seqkit grep -f {output[0]} -r > {output[1]}
        """


rule reads:
    input:
        storage(
            query="ftp://ftp.ebi.ac.uk/biostudies/fire/E-GEUV-/001/E-GEUV-1/Files/E-GEUV-1/processed/NA20778.4.M_120208_1.bam",
            keep_local=True,
        ),
        storage(
            query="ftp://ftp.ebi.ac.uk/biostudies/fire/E-GEUV-/001/E-GEUV-1/Files/E-GEUV-1/processed/NA20778.4.M_120208_1.bam.bai",
            keep_local=True,
        ),
    output:
        bam="rnaseq/{sample}.chr{chrom}.bam",
        fq1="rnaseq/{sample}.chr{chrom}.1.fq.gz",
        fq2="rnaseq/{sample}.chr{chrom}.2.fq.gz",
    shell:
        """
        touch -m {input[1]}
        samtools view -b {input[0]} chr{wildcards.chrom} > {output.bam}
        samtools fastq -1 {output.fq1} -2 {output.fq2} -0 /dev/null -s /dev/null {output.bam} 2> /dev/null
        """


rule rnaseq:
    input:
        expand(
            [
                "rnaseq/ref/txome.chr{chrom}.gtf",
                "rnaseq/ref/genome.chr{chrom}.fa",
                "rnaseq/ref/txome.chr{chrom}.fa",
                "rnaseq/ref/rmsk.chr{chrom}.gtf",
                "rnaseq/ref/rmsk.chr{chrom}.gtf.locInd",
            ],
            chrom=21,
        ),
        expand(
            rules.reads.output,
            sample=["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l"],
            chrom=21,
        ),
