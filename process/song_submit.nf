#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// processes resources
params.cpus = 1
params.mem = 1

// required params w/ default
params.container_version = "4.2.1"

// optional if secret mounted from pod else required
params.api_token = "" // song/score API token for download process

// required params, no default
// --song_url         song url for download process
// --score_url        score url for download process

process songSubmit {
    pod secret: workflow.runName + "-secret", mountPath: "/tmp/" + workflow.runName
    
    cpus params.cpus
    memory "${params.mem} GB"
 
    container "overture/song-client:${params.container_version}"
    
    tag "${study_id}"
    label "songSubmit"
    
    input:
        val study_id
        path payload
    
    output:
        stdout()

    script:
        accessToken = params.api_token ? params.api_token : "`cat /tmp/${workflow.runName}/secret`"
        """
        export CLIENT_SERVER_URL=${params.song_url}
        export CLIENT_STUDY_ID=${study_id}
        export CLIENT_ACCESS_TOKEN=${accessToken}

        set -euxo pipefail
        sing submit -f ${payload} | jq -er .analysisId | tr -d '\\n'
        """
}
