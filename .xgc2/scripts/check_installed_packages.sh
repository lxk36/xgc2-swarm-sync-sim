#!/usr/bin/env bash
set -euo pipefail

ROS_DISTRO="${ROS_DISTRO:-noetic}"
ARCH="$(dpkg --print-architecture)"

source "/opt/ros/${ROS_DISTRO}/setup.bash"

required_debs=(
  ros-noetic-xgc2-sss-sim-env
  ros-noetic-xgc2-sss-px4-rotor-sim
  ros-noetic-xgc2-sss-tello-sim
  ros-noetic-xgc2-sss-ugv-sim
  ros-noetic-xgc2-swarm-sync-sim
)
required_ros_packages=(
  sss_sim_env
  px4_rotor_sim
  tello_sim
  ugv_sim
)

if [[ "${ARCH}" == "amd64" ]]; then
  required_debs+=(ros-noetic-xgc2-sss-fw-plane-sim)
  required_ros_packages+=(fw_plane_sim)
fi

for package in "${required_debs[@]}"; do
  dpkg -s "${package}" >/dev/null
done

for ros_pkg in "${required_ros_packages[@]}"; do
  test "$(rospack find "${ros_pkg}")" = "/opt/ros/${ROS_DISTRO}/share/${ros_pkg}"
done

roslaunch --files sss_sim_env sim_clock.launch >/tmp/xgc2-sss-sim-clock-files.txt
roslaunch --files px4_rotor_sim px4_rotor_sim_single.launch open_rviz:=false >/tmp/xgc2-sss-px4-files.txt
roslaunch --files tello_sim tello_sim_single.launch open_rviz:=false >/tmp/xgc2-sss-tello-files.txt
roslaunch --files ugv_sim ugv_sim_single.launch open_rviz:=false >/tmp/xgc2-sss-ugv-files.txt

if [[ "${ARCH}" == "amd64" ]]; then
  roslaunch --files fw_plane_sim fw_sim_single.launch open_rviz:=false >/tmp/xgc2-sss-fw-files.txt
fi

check_paths=(
  "/opt/ros/${ROS_DISTRO}/lib/sss_sim_env"
  "/opt/ros/${ROS_DISTRO}/lib/px4_rotor_sim"
  "/opt/ros/${ROS_DISTRO}/lib/tello_sim"
  "/opt/ros/${ROS_DISTRO}/lib/ugv_sim"
  "/opt/ros/${ROS_DISTRO}/lib/libsim_clock.so"
  "/opt/ros/${ROS_DISTRO}/lib/libClockUpdater.so"
  "/opt/ros/${ROS_DISTRO}/lib/libsss_timer.so"
  "/opt/ros/${ROS_DISTRO}/lib/libsss_sleep.so"
  "/opt/ros/${ROS_DISTRO}/lib/libpx4_rotor_dynamics.so"
  "/opt/ros/${ROS_DISTRO}/lib/libpx4_lib.so"
  "/opt/ros/${ROS_DISTRO}/lib/libmc_pos_control.so"
  "/opt/ros/${ROS_DISTRO}/lib/libmc_att_control.so"
  "/opt/ros/${ROS_DISTRO}/lib/libcommander.so"
  "/opt/ros/${ROS_DISTRO}/lib/libpx4_mavlink.so"
  "/opt/ros/${ROS_DISTRO}/lib/libpx4_sitl.so"
  "/opt/ros/${ROS_DISTRO}/lib/libMavrosSim.so"
  "/opt/ros/${ROS_DISTRO}/lib/libpx4_rotor_visualizer.so"
  "/opt/ros/${ROS_DISTRO}/lib/libmavros_px4_quadrotor_sim_nodelet.so"
  "/opt/ros/${ROS_DISTRO}/lib/libtello_dynamics.so"
  "/opt/ros/${ROS_DISTRO}/lib/libtello_driver_sim.so"
  "/opt/ros/${ROS_DISTRO}/lib/libtello_quadrotor_sim_nodelet.so"
  "/opt/ros/${ROS_DISTRO}/lib/libugv_dynamics.so"
  "/opt/ros/${ROS_DISTRO}/lib/libwheeltec_driver_sim.so"
  "/opt/ros/${ROS_DISTRO}/lib/libwheeltec_ugv_sim_nodelet.so"
)

if [[ "${ARCH}" == "amd64" ]]; then
  check_paths+=(
    "/opt/ros/${ROS_DISTRO}/lib/fw_plane_sim"
    "/opt/ros/${ROS_DISTRO}/lib/libpx4_lib_fw.so"
    "/opt/ros/${ROS_DISTRO}/lib/libfw_plane_visualizer.so"
    "/opt/ros/${ROS_DISTRO}/lib/libfw_sim_nodelet.so"
    "/opt/ros/${ROS_DISTRO}/lib/libBHDynamic.so"
  )
fi

while IFS= read -r file; do
  if ! file -b "${file}" | grep -q '^ELF'; then
    continue
  fi
  if ! ldd "${file}" | awk '/not found/ {missing=1} END {exit missing ? 1 : 0}'; then
    echo "missing shared library dependency in ${file}" >&2
    ldd "${file}" >&2 || true
    exit 1
  fi
done < <(
  for path in "${check_paths[@]}"; do
    if [[ -d "${path}" ]]; then
      find "${path}" -type f \( -perm -0100 -o -name '*.so' \)
    elif [[ -f "${path}" ]]; then
      printf '%s\n' "${path}"
    fi
  done | sort -u
)

echo "Installed package check passed for ${ARCH}"
