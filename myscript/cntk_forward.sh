#!/bin/bash

# Author: jyhou@nwpu-aslp.org
# Date: 24/10/2016

# Script for CNTK neural network forward

cntk_command=write
num_utts_per_iter=20
minibatch_size=256
label_dim=
feat_dim=
feats=
counts=
deviceId=
traceLevel=1
output_ext=BLSTM_encoder_4_3
config_file=

[ -f path.sh ] && . ./path.sh
. parse_options.sh || exit 1;

if [ $# != 2 ]; then
    echo "Usage: $0 <model_dir> <output_dir>"
    echo "e.g.: $0 "
    exit 1;
fi
model_dir=$1
output_dir=$2

cntk_feat="cntk ExpDir=$model_dir modelName=$cntk_model DeviceNumber=$deviceId"
cntk_feat="$cntk_feat featDim=$feat_dim inputCounts=$counts inputFeats=$feats"
cntk_feat="$cntk_feat labelDim=$label_dim utteranceNum=$num_utts_per_iter configFile=$config_file"
copy-feats-to-htk --output-dir=${output_dir} --output-ext=$output_ext "ark:$cntk_feat"
