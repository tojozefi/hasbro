#!/bin/bash
set -x

#REGION=$1
VNET_CLUSTERNAME=$1
COMBINED_PARAMS=$2

run_moosefs_bench () {
  CLUSTER_NAME=${VNET_CLUSTERNAME}-${1}
  COUNT=$2
  RUN_ID=`uuidgen`

  _params=`mktemp`
  jq -s '.[0] * .[1]' $COMBINED_PARAMS params-moosefs.json > $_params
  cat $_params

  cyclecloud import_cluster $CLUSTER_NAME -c moosefs -f moosefs.txt  \
    -p $_params \
    -P InitialChunkCount=${COUNT} \
    -P VnetEnvCluster=$VNET_CLUSTERNAME 
  
  cyclecloud start_cluster $CLUSTER_NAME

  cyclecloud import_cluster ${CLUSTER_NAME}-io -c bench -f io-bench.txt \
    -p $COMBINED_PARAMS \
    -P BenchClusterName=$CLUSTER_NAME \
    -P TargetName=${1} \
    -P TargetSize=${COUNT} \
    -P RunId=${RUN_ID} \
    -P StorageCluster=$CLUSTER_NAME \
    -P SendReport=true \
	  -P MooseFSMount="/bench" \
	  -P MoosefsProjectVersion="1.0.0" \
    -P VnetEnvCluster=$VNET_CLUSTERNAME

  cyclecloud start_cluster ${CLUSTER_NAME}-io

}

run_moosefs_bench M1 4 
run_moosefs_bench M2 8 
run_moosefs_bench M3 16 
