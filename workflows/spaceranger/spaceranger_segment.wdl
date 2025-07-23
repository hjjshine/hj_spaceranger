version 1.0

workflow spaceranger_segment {
    input {
        # Unique job id
        String sample_id

        # Spaceranger output directory, gs url
        String output_directory

        # Brightfield tissue H&E image in .jpg or .tiff format.
        File image
        
        # spaceranger version
        String spaceranger_version

        # Which docker registry to use: cumulusprod (default) or quay.io/cumulus
        String docker_registry

        # Google cloud zones, default to "us-central1-b", which is consistent with CromWell's genomics.default-zones attribute
        String zones = "us-central1-b"
        
        # Number of cpus per spaceranger job
        Int num_cpu = 32
        
        # Memory string, e.g. 120G
        String memory = "120G"
        
        # Disk space in GB
        Int disk_space = 500
        
        # Number of preemptible tries
        Int preemptible = 2
        
        # Arn string of AWS queue
        String awsQueueArn = ""
        
        # Backend
        String backend
    }

    call run_spaceranger_segment {
        input:
            sample_id = sample_id,
            output_directory = output_directory,
            image = image,
            spaceranger_version = spaceranger_version,
            docker_registry = docker_registry,
            zones = zones,
            num_cpu = num_cpu,
            memory = memory,
            disk_space = disk_space,
            preemptible = preemptible,
            awsQueueArn = awsQueueArn,
            backend = backend
    }

    output {
        String output_segment_directory = run_spaceranger_segment.output_segment_directory
        String output_nucleus_instance_mask = run_spaceranger_segment.output_nucleus_instance_mask
        String output_nucleus_segmentations = run_spaceranger_segment.output_nucleus_segmentations
        String output_web_summary = run_spaceranger_segment.output_web_summary
        File monitoringLog = run_spaceranger_segment.monitoringLog
    }
}

task run_spaceranger_segment {
    input {
        String sample_id
        String output_directory
        File image
        String spaceranger_version
        String docker_registry
        String zones
        Int num_cpu
        String memory
        Int disk_space
        Int preemptible
        String awsQueueArn
        String backend
    }

    command {
        set -e
        export TMPDIR=/tmp
        export BACKEND=~{backend}
        monitor_script.sh > monitoring.log &

        python <<CODE
        import os
        import re
        import sys
        from subprocess import check_call, CalledProcessError, DEVNULL, STDOUT
        from packaging import version

        mem_size = re.findall(r"\d+", "~{memory}")[0]
        call_args = ['spaceranger', 'segment', '--id=~{sample_id}', '--tissue-image=~{image}', '--jobmode=local', '--localcores=~{num_cpu}', '--localmem='+mem_size]
        print(' '.join(call_args))
        check_call(call_args)
        CODE

        strato sync results/outs "~{output_directory}/~{sample_id}"
    }

    output {
        # Outputs:
        # - nucleus_instance_mask: /path/to/outs/nucleus_instance_mask.tiff
        # - nucleus_segmentations: /path/to/outs/nucleus_segmentations.geojson
        # - websummary:           /path/to/outs/websummary.html

        String output_segment_directory = "~{output_directory}/~{sample_id}"
        String output_nucleus_instance_mask = "~{output_directory}/~{sample_id}/nucleus_instance_mask.tiff"
        String output_nucleus_segmentations = "~{output_directory}/~{sample_id}/nucleus_segmentations.geojson"
        String output_web_summary = "~{output_directory}/~{sample_id}/web_summary.html"
        File monitoringLog = "monitoring.log"
    }

    runtime {
        docker: "~{docker_registry}/spaceranger:~{spaceranger_version}"
        zones: zones
        memory: memory
        bootDiskSizeGb: 12
        disks: "local-disk ~{disk_space} HDD"
        cpu: num_cpu
        preemptible: preemptible
        queueArn: awsQueueArn
    }
}
