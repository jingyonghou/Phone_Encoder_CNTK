#!/usr/bin/bash
dir=scp
mkdir -p $dir
for x in test_dev93; do

        feats=data/${x}_add-delta/feats.scp
        labels=data/${x}_label/labels.scp
        weights_frame=data/${x}_weight_frame/weights_frame.scp
        weights_boundary=data/${x}_weight_boundary/weights_boundary.scp
        python myscript/check_scp.py $feats $labels $weights_frame $weights_boundary ${dir}/
        
        cp $labels $dir/labels.scp
        cp $weights_frame $dir/weights_frame.scp
        cp $weights_boundary $dir/weights_boundary.scp
done

