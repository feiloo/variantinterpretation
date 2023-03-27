process BCFTOOLS_VEP_TO_TSV {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::bcftools=1.16"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bcftools:1.16--hfe4b78e_1':
        'quay.io/biocontainers/bcftools:1.16--hfe4b78e_1' }"

    input:
    tuple val(meta), path(vcf)

    output:
    tuple val(meta), path("*.tsv")      , emit: tsv
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    bcftools +split-vep -l ${vcf} | \\
    awk '{print \$2}' | \\
    paste -sd "\\t" | \\
    awk '{print "CHROM\\tPOS\\tID\\tREF\\tALT\\tQUAL\\tFILTER\\tFORMAT\\tFORMAT.1\\t"\$0}' > ${prefix}.tsv
    bcftools +split-vep ${vcf} \\
        $args \\
        -A tab \\
        -O u \\
        -f '%CHROM\\t %POS\\t %ID\\t %REF\\t %ALT\\t %QUAL\\t %FILTER\\t %FORMAT\\t %CSQ \\n' >> ${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch "${prefix}.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """
}
