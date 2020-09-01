#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// processes resources
params.cpus = 1
params.mem = 1

// test data
test_data_dir = "data"

include { songScoreDownload } from '../workflow/song_score_download' params(params)
include { songScoreUpload as sequencingAlignmentUpload } from '../workflow/song_score_upload' params(params)
include { sequencingAlignmentPayloadGen } from '../process/sequencing_alignment_payload_gen'

sequencing_alignment = Channel.fromPath("${test_data_dir}/sequencing_alignment_upload/*").collect()

process mountSecret {
  input:
    val apiKey
    
  script:
    """
      mkdir /tmp/$workflow.runName
      echo $apiKey > /tmp/$workflow.runName/secret
    """
}

workflow {
  // Mount secret so processes have access to it
  mountSecret(params.apiKey)

  // Download sequencing_experiment files
  songScoreDownload(params.study_id, params.analysis_id)

  // sequencing_experiment to sequencing_alignment payload generator
  sequencingAlignmentPayloadGen(songScoreDownload.out.analysis_json, sequencing_alignment)

  // Upload same files with sequencing_alignment payload
  sequencingAlignmentUpload(params.study_id, sequencingAlignmentPayloadGen.out.analysis, sequencingAlignmentPayloadGen.out.upload_files)
}
