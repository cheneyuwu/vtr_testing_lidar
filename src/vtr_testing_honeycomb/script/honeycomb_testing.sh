echo "This script contains instructions to run all tests, do not run this script directly."
exit 1

## First launch RViz for visualization
source /opt/ros/galactic/setup.bash                   # source the ROS environment
ros2 run rviz2 rviz2 -d ${VTRSRC}/rviz/honeycomb.rviz # launch rviz

## Then in another terminal, launch rqt_reconfigure for control
## current supported dynamic reconfigure parameters: control_test.play and controL_test.delay_millisec
source /opt/ros/galactic/setup.bash
ros2 run rqt_reconfigure rqt_reconfigure

############################################################
#### Now start another terminal and run testing scripts ####

## Terminal Setup (Run Following Once)

## Define the following environment variables VTRH=VTR Honeycomb
export VTRHROOT=/ext0/ASRL/vtr_testing_lidar
export VTRHDATA=${VTRDATA}/utias_20211230_multiple_terrain/dome_inside
export VTRHRESULT=${VTRTEMP}/testing/multienv
mkdir -p ${VTRHRESULT}

# Source the VTR environment with the testing package
source ${VTRHROOT}/install/setup.bash

# Choose a Teach (ODO_INPUT) and Repeat (LOC_INPUT) run from boreas dataset
# parkinglot static
ODO_INPUT=rosbag2_2021_11_01-18_05_58
LOC_INPUT=rosbag2_2021_11_01-18_10_03
# parkinglot with you
ODO_INPUT=rosbag2_2022_01_09-19_00_08
LOC_INPUT=rosbag2_2022_01_09-18_55_25
# backyard
ODO_INPUT=rosbag2_2021_12_30-14_31_27
LOC_INPUT=rosbag2_2021_12_30-14_37_51
# dome inside
ODO_INPUT=rosbag2_2022_01_30-22_34_29
LOC_INPUT=rosbag2_2022_01_30-22_36_16

## Some use flags
##   --prefix 'gdb -ex run --args'

## Using ONE of the following commands to launch a test

# (TEST 1) Perform data preprocessing on a sequence (e.g. keypoint extraction)
bash ${VTRHROOT}/src/vtr_testing_honeycomb/script/test_preprocessing.sh ${ODO_INPUT}

# (TEST 2) Perform odometry on a sequence
bash ${VTRHROOT}/src/vtr_testing_honeycomb/script/test_odometry.sh ${ODO_INPUT}

# (TEST 3) Perform localization on a sequence (only run this after TEST 2)
bash ${VTRHROOT}/src/vtr_testing_honeycomb/script/test_localization.sh ${ODO_INPUT} ${LOC_INPUT}

# Perform localization + planning on a sequence directly (with a specified point map version)
ros2 run vtr_testing_honeycomb vtr_testing_honeycomb_localization_planning \
  --ros-args -p use_sim_time:=true -r __ns:=/vtr --params-file ${VTRHROOT}/config/honeycomb.yaml \
  -p data_dir:=${VTRHRESULT}/${ODO_INPUT}/${LOC_INPUT} \
  -p odo_dir:=${VTRHDATA}/${ODO_INPUT} \
  -p loc_dir:=${VTRHDATA}/${LOC_INPUT}

# Perform change detection offline
bash ${VTRHROOT}/src/vtr_testing_honeycomb/script/test_change_detection.sh ${ODO_INPUT} ${LOC_INPUT}

# Perform offline tasks
ros2 run vtr_testing_honeycomb vtr_testing_honeycomb_intra_exp_merging \
  --ros-args -r __ns:=/vtr --params-file ${VTRHROOT}/config/honeycomb.yaml \
  -p data_dir:=${VTRHRESULT}/${ODO_INPUT}/${ODO_INPUT}

ros2 run vtr_testing_honeycomb vtr_testing_honeycomb_dynamic_detection \
  --ros-args -r __ns:=/vtr --params-file ${VTRHROOT}/config/honeycomb.yaml \
  -p data_dir:=${VTRHRESULT}/${ODO_INPUT}/${ODO_INPUT}

ros2 run vtr_testing_honeycomb vtr_testing_honeycomb_inter_exp_merging \
  --ros-args -r __ns:=/vtr --params-file ${VTRHROOT}/config/honeycomb.yaml \
  -p data_dir:=${VTRHRESULT}/${ODO_INPUT}/${ODO_INPUT}

ros2 run vtr_testing_honeycomb vtr_testing_honeycomb_terrain_assessment \
  --ros-args -r __ns:=/vtr --params-file ${VTRHROOT}/config/honeycomb.yaml \
  -p data_dir:=${VTRHRESULT}/${ODO_INPUT}/${ODO_INPUT}

ros2 run vtr_testing_honeycomb vtr_testing_honeycomb_intra_exp_merging \
  --ros-args -r __ns:=/vtr --params-file ${VTRHROOT}/config/honeycomb.yaml \
  -p data_dir:=${VTRHRESULT}/${ODO_INPUT}/${LOC_INPUT} \
  -p run_id:=1

ros2 run vtr_testing_honeycomb vtr_testing_honeycomb_change_detection \
  --ros-args -r __ns:=/vtr --params-file ${VTRHROOT}/config/honeycomb.yaml \
  -p data_dir:=${VTRHRESULT}/${ODO_INPUT}/${LOC_INPUT} \
  -p run_id:=1