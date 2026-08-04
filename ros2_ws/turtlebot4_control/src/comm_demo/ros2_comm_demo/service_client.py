import sys

import rclpy
from example_interfaces.srv import AddTwoInts
from rclpy.node import Node


class AddServiceClient(Node):
    def __init__(self):
        super().__init__("add_service_client")
        self.client = self.create_client(AddTwoInts, "add_two_ints")

        while not self.client.wait_for_service(timeout_sec=1.0):
            self.get_logger().info("Waiting for service...")

    def send_request(self, a, b):
        request = AddTwoInts.Request()
        request.a = a
        request.b = b
        future = self.client.call_async(request)
        rclpy.spin_until_future_complete(self, future)
        return future.result()


def main(args=None):
    rclpy.init(args=args)

    node = AddServiceClient()
    a = int(sys.argv[1])
    b = int(sys.argv[2])

    response = node.send_request(a, b)
    node.get_logger().info(f"Result: {response.sum}")

    node.destroy_node()
    rclpy.shutdown()
