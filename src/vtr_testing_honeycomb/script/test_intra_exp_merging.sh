# Get arguments
ODO_INPUT=$1

# Log
echo "Running change detection on sequence ${LOC_INPUT} to reference sequence ${ODO_INPUT}, run id set to 0"

# Source the VTR environment with the testing package
source ${VTRHROOT}/install/setup.bash

ros2 run vtr_testing_honeycomb vtr_testing_honeycomb_intra_exp_merging \
  --ros-args -r __ns:=/vtr \
  --params-file ${VTRHROOT}/src/vtr_testing_honeycomb/config/honeycomb.yaml \
  -p data_dir:=${VTRHRESULT}/${ODO_INPUT}/${ODO_INPUT} \
  -p run_id:=0
