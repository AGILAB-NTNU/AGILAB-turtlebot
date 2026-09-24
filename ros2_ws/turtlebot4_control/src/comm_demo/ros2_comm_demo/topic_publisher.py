import rclpy
from rclpy.node import Node
from std_msgs.msg import String


class TopicPublisher(Node):
    def __init__(self):
        super().__init__("topic_publisher")
        self.publisher_ = self.create_publisher(String, "demo_topic", 10)
        self.timer = self.create_timer(1.0, self.publish_message)
        self.count = 0

    def publish_message(self):
        msg = String()
        msg.data = f"Hello ROS2 Topic {self.count}"
        self.publisher_.publish(msg)
        self.get_logger().info(f"Publish: {msg.data}")
        self.count += 1


def main(args=None):
    rclpy.init(args=args)
    node = TopicPublisher()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()
