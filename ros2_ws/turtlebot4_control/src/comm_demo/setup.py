from setuptools import find_packages, setup

package_name = 'ros2_comm_demo'

setup(
    name=package_name,
    version='0.0.0',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='helson',
    maintainer_email='helson@todo.todo',
    description='TODO: Package description',
    license='TODO: License declaration',
    extras_require={
        'test': [
            'pytest',
        ],
    },
   entry_points={
    'console_scripts': [
        'topic_publisher = ros2_comm_demo.topic_publisher:main',
        'topic_subscriber = ros2_comm_demo.topic_subscriber:main',
        'service_server = ros2_comm_demo.service_server:main',
        'service_client = ros2_comm_demo.service_client:main',
        'action_server = ros2_comm_demo.action_server:main',
        'action_client = ros2_comm_demo.action_client:main',
    ],
},
)
