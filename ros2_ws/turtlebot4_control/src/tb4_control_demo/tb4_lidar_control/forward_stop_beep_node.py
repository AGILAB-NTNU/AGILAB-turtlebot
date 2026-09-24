import math

import rclpy
from geometry_msgs.msg import Twist
from irobot_create_msgs.msg import AudioNote, AudioNoteVector
from rclpy.node import Node
from rclpy.qos import HistoryPolicy, QoSProfile, ReliabilityPolicy
from sensor_msgs.msg import LaserScan


class ForwardStopBeepNode(Node):
    def __init__(self):
        super().__init__("forward_stop_beep_node")

        self.safe_distance = 0.5  # 距離小於 0.5 m 就停止並叫
        self.forward_speed = 0.08  # 前進速度 m/s
        self.front_angle_deg = 30.0  # 偵測前方 30 度範圍

        self.state = "FORWARD"
        self.beep_sent = False

        self.scan_sub = self.create_subscription(
            LaserScan, "/scan", self.scan_callback, 10
        )

        self.cmd_pub = self.create_publisher(Twist, "/cmd_vel", 10)

        # /cmd_audio 官方要求 reliable QoS，這裡明確設定
        audio_qos = QoSProfile(
            reliability=ReliabilityPolicy.RELIABLE,
            history=HistoryPolicy.KEEP_LAST,
            depth=10,
        )

        self.audio_pub = self.create_publisher(AudioNoteVector, "/cmd_audio", audio_qos)

        self.timer = self.create_timer(0.1, self.control_loop)

        self.get_logger().info("Forward stop beep node started.")
        self.get_logger().info(
            f"safe_distance={self.safe_distance:.2f} m, "
            f"front_angle={self.front_angle_deg:.1f} deg"
        )

    def scan_callback(self, scan_msg):
        if self.state != "FORWARD":
            return

        half_angle_rad = math.radians(self.front_angle_deg / 2.0)
        valid_distances = []

        for i, distance in enumerate(scan_msg.ranges):
            angle = scan_msg.angle_min + i * scan_msg.angle_increment

            # 取正前方 +/- front_angle_deg/2 的範圍
            if -half_angle_rad <= angle <= half_angle_rad:
                if (
                    not math.isinf(distance)
                    and not math.isnan(distance)
                    and distance > 0.0
                ):
                    valid_distances.append(distance)

        if len(valid_distances) == 0:
            self.get_logger().warn("No valid front LiDAR data.")
            return

        front_distance = min(valid_distances)

        self.get_logger().info(f"Front distance: {front_distance:.2f} m")

        if front_distance < self.safe_distance:
            self.get_logger().warn(
                f"Obstacle detected at {front_distance:.2f} m. Stop and beep."
            )
            self.state = "STOP"
            self.publish_stop()
            self.play_beep()

    def control_loop(self):
        if self.state == "FORWARD":
            cmd = Twist()
            cmd.linear.x = self.forward_speed
            cmd.angular.z = 0.0
            self.cmd_pub.publish(cmd)

        elif self.state == "STOP":
            self.publish_stop()

    def publish_stop(self):
        cmd = Twist()
        cmd.linear.x = 0.0
        cmd.angular.z = 0.0
        self.cmd_pub.publish(cmd)

    def play_beep(self):
        if self.beep_sent:
            return

        msg = AudioNoteVector()
        msg.append = False

        note1 = AudioNote()
        note1.frequency = 440
        note1.max_runtime.sec = 1
        note1.max_runtime.nanosec = 0

        note2 = AudioNote()
        note2.frequency = 880
        note2.max_runtime.sec = 1
        note2.max_runtime.nanosec = 0

        msg.notes = [note1, note2]

        self.audio_pub.publish(msg)
        self.beep_sent = True

        self.get_logger().info("Beep sound sent to /cmd_audio.")


def main(args=None):
    rclpy.init(args=args)

    node = ForwardStopBeepNode()

    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass

    node.publish_stop()
    node.get_logger().info("Stop command sent.")

    node.destroy_node()
    rclpy.shutdown()


if __name__ == "__main__":
    main()
