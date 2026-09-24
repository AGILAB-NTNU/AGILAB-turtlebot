import rclpy
from example_interfaces.srv import AddTwoInts
from rclpy.node import Node


class AddServiceServer(Node):
    def __init__(self):
        super().__init__("add_service_server")
        self.srv = self.create_service(AddTwoInts, "add_two_ints", self.add_callback)

    def add_callback(self, request, response):
        response.sum = request.a + request.b
        self.get_logger().info(f"Request: {request.a} + {request.b} = {response.sum}")
        return response


def main(args=None):
    rclpy.init(args=args)
    node = AddServiceServer()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()
