#!/bin/sh


#  Paths to things we run.

bin="/N/scratch/bochman/conda_envs/canu/bin"

pn=/N/scratch/bochman/conda_envs/canu/bin/perl
pe=`command -v $pn`
pv=`command    $pn --version | grep version`

jn=/N/scratch/bochman/conda_envs/canu/lib/jvm/bin/java
je=`command -v $jn`
if [ "x$je" = "x" ]; then
   je=$jn
fi
jv=`command    $jn -showversion 2>&1 | head -n 1`

cn=/N/scratch/bochman/conda_envs/canu/bin/canu
ce=`command -v $cn`
cv=`command    $cn -version`

#  Report paths.

echo ""
echo "Found perl (from '$pn'):"
echo "  $pe"
echo "  $pv"
echo ""
echo "Found java (from '$jn'):"
echo "  $je"
echo "  $jv"
echo ""
echo "Found canu (from '$cn'):"
echo "  $ce"
echo "  $cv"
echo ""

#  Environment for any object storage.

export CANU_OBJECT_STORE_CLIENT=
export CANU_OBJECT_STORE_CLIENT_UA=
export CANU_OBJECT_STORE_CLIENT_DA=
export CANU_OBJECT_STORE_NAMESPACE=
export CANU_OBJECT_STORE_PROJECT=




/N/scratch/bochman/conda_envs/canu/bin/sqStoreCreate \
  -o ./YH156_canu.seqStore.BUILDING \
  -minlength 1000 \
  -genomesize 12000000 \
  -coverage   200 \
  -bias       0 \
  -raw -nanopore YH156_combined.filt /N/scratch/bochman/yeast_id/results/YH156_v2/filtered/YH156_combined.filt.fastq.gz \
&& \
mv ./YH156_canu.seqStore.BUILDING ./YH156_canu.seqStore \
&& \
exit 0

exit 1
