#!/bin/bash
# Single script to launch the mycobot with Gazebo, RViz, and MoveIt 2

echo "Starting robot model $ROBOT_MODEL"

cleanup() {
    echo "Cleaning up..."
    sleep 5.0
    pkill -9 -f "ros2|gazebo|gz|nav2|amcl|bt_navigator|nav_to_pose|rviz2|assisted_teleop|cmd_vel_relay|robot_state_publisher|joint_state_publisher|move_to_free|mqtt|autodock|cliff_detection|moveit|move_group|basic_navigator"
}

# Set up cleanup trap
trap 'cleanup' SIGINT SIGTERM

echo "Launching Gazebo simulation..."
ros2 launch mycobot_gazebo mycobot.gazebo.launch.py \
    load_controllers:=true \
    world_file:=pick_and_place_demo.world \
    use_camera:=true \
    use_rviz:=false \
    use_robot_state_pub:=true \
    use_sim_time:=true \
    robot_model:=$ROBOT_MODEL \
    x:=0.0 \
    y:=0.0 \
    z:=0.05 \
    roll:=0.0 \
    pitch:=0.0 \
    yaw:=0.0 &

sed -i "/relative_path: urdf/c\    relative_path: urdf/robots/${ROBOT_MODEL}.urdf.xacro" /root/ros2_ws/src/third-party/mycobot-ros2/mycobot_moveit_config/.setup_assistant
sed -i "/relative_path: config/c\    relative_path: config/${ROBOT_MODEL}/${ROBOT_MODEL}.srdf" /root/ros2_ws/src/third-party/mycobot-ros2/mycobot_moveit_config/.setup_assistant
sleep 15
ros2 launch mycobot_moveit_config move_group.launch.py robot_name:=$ROBOT_MODEL &

echo "Adjusting camera position..."
gz service -s /gui/move_to/pose --reqtype gz.msgs.GUICamera --reptype gz.msgs.Boolean --timeout 2000 --req "pose: {position: {x: 1.36, y: -0.58, z: 0.95} orientation: {x: -0.26, y: 0.1, z: 0.89, w: 0.35}}"

# Keep the script running until Ctrl+C
wait