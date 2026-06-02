#include <ros/ros.h>
#include <geometry_msgs/PoseStamped.h>
#include <geometry_msgs/TwistStamped.h>

namespace px4_rotor_sim {

class MavrosVrpnForwarderNode {
public:
    explicit MavrosVrpnForwarderNode(ros::NodeHandle& nh) {
        pose_pub_ = nh.advertise<geometry_msgs::PoseStamped>("pose", 10);
        twist_pub_ = nh.advertise<geometry_msgs::TwistStamped>("twist", 10);

        pose_sub_ = nh.subscribe("mavros/local_position/pose", 10,
                                 &MavrosVrpnForwarderNode::poseCallback, this);
        twist_sub_ = nh.subscribe("mavros/local_position/velocity_local", 10,
                                  &MavrosVrpnForwarderNode::twistCallback, this);

        ROS_INFO("[MavrosVrpnForwarderNode] Forwarding mavros/local_position/pose -> pose");
        ROS_INFO("[MavrosVrpnForwarderNode] Forwarding mavros/local_position/velocity_local -> twist");
    }

private:
    void poseCallback(const geometry_msgs::PoseStamped::ConstPtr& msg) {
        if (!msg) {
            return;
        }
        pose_pub_.publish(*msg);
    }

    void twistCallback(const geometry_msgs::TwistStamped::ConstPtr& msg) {
        if (!msg) {
            return;
        }
        twist_pub_.publish(*msg);
    }

    ros::Subscriber pose_sub_;
    ros::Subscriber twist_sub_;
    ros::Publisher pose_pub_;
    ros::Publisher twist_pub_;
};

}  // namespace px4_rotor_sim

int main(int argc, char** argv) {
    ros::init(argc, argv, "mavros_vrpn_forwarder_node");
    ros::NodeHandle nh;

    px4_rotor_sim::MavrosVrpnForwarderNode node(nh);
    ros::spin();
    return 0;
}
