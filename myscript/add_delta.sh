#!/bin/bash
# Author: jyhou@nwpu-aslp.org
# Data: 2016/10/16
# This script used to add delta to a feature and write it 

nj=4
cmd=run.pl
delta_order=2
source_name="fbank"
cmvn=true
compress=true
echo "$0 $@"  # Print the command line for logging

if [ -f path.sh ]; then . ./path.sh; fi
. parse_options.sh || exit 1;

if [ $# -lt 1 ] || [ $# -gt 3 ]; then
   echo "Usage: $0 [options] <data-dir> [<add-delta-dir>]  [<log-dir>]";
   echo "e.g.: $0 data/train  data/train_add-delta  data/train_add-delta/log"
   echo "Note: <log-dir> defaults to <add-data-dir>/log, and <add-delta-dir> defaults to <data-dir>_add-delta"
   echo "Options: "
   echo "  --delta-order (1|2)                              # delta order, defulat 2"
   echo "  --cmvn (true|false)                              # whether cmvn, defulat ture"
   echo "  --nj <nj>                                        # number of parallel jobs"
   echo "  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs."
   exit 1;
fi

sourcedir=$1
if [ $# -ge 2 ]; then
    targetdir=$2
else
    targetdir=${1}_add-delta
fi
if [ $# -ge 3 ]; then
    logdir=$3
else
    logdir=${1}_add-delta/log
fi

mkdir -p $targetdir
mkdir -p $logdir
rootdir=`pwd`
targetdir="${rootdir}/${targetdir}"
if [ -f $sourcedir/feats.scp ]; then
    mkdir -p $targetdir/data
    split_scps=""
    for n in $(seq $nj); do
        split_scps="$split_scps $logdir/feats.$n.scp"
    done
    utils/split_scp.pl $sourcedir/feats.scp $split_scps || exit 1;
    if $cmvn; then
        $cmd JOB=1:$nj $logdir/${source_name}_add_delta.JOB.log \
        apply-cmvn --utt2spk=ark:$sourcedir/utt2spk scp:$sourcedir/cmvn.scp scp:$logdir/feats.JOB.scp ark:- \| \
        add-deltas --delta-order=$delta_order ark:- ark:- \| \
        copy-feats --compress=$compress ark:- ark,scp:$targetdir/data/${source_name}_add_delta.JOB.ark,$targetdir/data/${source_name}_add_delta.JOB.scp || exit 1;
    else
        $cmd JOB=1:$nj $logdir/${source_name}_add_delta.JOB.log \
        add-delta --delta-order=$delta_order scp:$logdir/feats.JOB.scp ark:- \| \
        copy-feats ark:- ark,scp:$targetdir/data/${source_name}_add_delta.JOB.ark,$targetdir/data/${source_name}_add_delta.JOB.scp || exit 1;

    fi
else
    echo "Error: no feats.scp find in source data dir ";
    exit 1;
fi

rm $logdir/feats.*.scp

for n in $(seq $nj); do
  cat $targetdir/data/${source_name}_add_delta.$n.scp || exit 1;
done > $targetdir/feats.scp

