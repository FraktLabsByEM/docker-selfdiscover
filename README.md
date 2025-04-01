

# Docker Self Discover

---

# 1. Introduction

## What is Docker Self Discover?

Docker Self Discover is a project designed to simplify the configuration of a Docker Swarm cluster in environments with multiple worker nodes. This system automates the process of node discovery on the local network, eliminating the need to know each node's IP address in advance. The goal is to streamline the deployment of Docker Swarm in distributed projects, improving scalability and efficiency.

## What is it for?

Docker Self Discover allows worker nodes to automatically discover and join a Docker Swarm cluster. Once set up, any worker node added to the system will be able to find and join the cluster without manual intervention, reducing the time and effort required to configure a Swarm environment on multiple devices.

## Benefits and Use Cases

### Benefits:
- **Automated node discovery**: Nodes can automatically discover each other on the same network without manual configuration.
- **Ease of installation**: The installation process is simple and automated through scripts.
- **Scalability**: Ideal for environments where new nodes are frequently added.
- **ARM architecture compatibility**: Compatible with devices like Raspberry Pi, making it ideal for lightweight hardware projects.
- **Security**: A password authentication system is used to protect communication between nodes.

### Use Cases:
- **Microservice networks**: Docker Self Discover facilitates the creation and management of microservice networks that require a Docker Swarm cluster for workload distribution.
- **IoT and distributed devices**: Ideal for environments with multiple devices, such as Raspberry Pi, that need to connect to a cluster Docker without manual intervention.
- **Scalable infrastructure**: In projects where new worker nodes need to be added frequently, Docker Self Discover simplifies the setup.

---

# 2. Requirements

Before starting with the Docker Self Discover setup, make sure you have the following system and tool requirements.

## System Requirements

- **Operating system**: Linux (Ubuntu, Debian, Raspbian, or any Debian-based distribution).
- **Architecture**: x86_64 or ARM (compatible with Raspberry Pi and similar devices).
- **Docker**: Docker must be installed on each node that will join the cluster. Docker Self Discover works specifically with Docker Swarm.
- **Local Network**: All worker nodes must be on the same local network so they can discover each other.
- **Internet connection**: Needed for downloading dependencies and initial setup.

## Required Tools

1. **Miniconda**: For managing Python virtual environments, especially on platforms like Raspberry Pi where installing Anaconda might not be viable due to resource consumption.
   - It will be installed automatically if not present.

2. **Nmap**: Network scanning tool used to discover devices on the same local network.
   - It must be installed on the system.

3. **Curl**: Command-line tool used to make HTTP requests from the worker node to other nodes on the network.
   - It will also be installed automatically if not present.

4. **Python 3.9**: Python 3.9 or higher is recommended. The project uses Conda to manage the virtual environment.
   - Conda will configure the environment automatically if not present.

## Hardware Requirements

- **Master node**: At least 1 node should be configured as the master node to initialize the Docker Swarm cluster.
- **Worker nodes**: These can be physical servers or devices like Raspberry Pi or other lightweight systems. Each of these nodes must be able to run Docker and have network access.

## Network Setup

- Ensure that the nodes can communicate with each other without firewall restrictions or other configurations blocking traffic on Docker Swarm's port (default is TCP port 2377).

---

# 3. Installation

This section will guide you through the necessary steps to install Docker Self Discover on your nodes automatically. The process is done through two scripts: `install.sh` and `setup.sh`. The `install.sh` script detects the node type and automatically redirects to `setup.sh`, which will handle the installation and setup, asking for information only when necessary.

## 3.1. Automatic Installation on the Worker Node

1. **Run the installation script**

   On the worker node, simply run the `install.sh` script. This script will ask for the node type and automatically redirect to `setup.sh` for installation.

   ```bash
   sudo bash install.sh
   ```

2. **Automated installation process**

   The `install.sh` script will automatically do the following:

   - Ask for the node type (worker or master) and redirect to the corresponding script.
   - Run `setup.sh`, which will configure the system, install necessary dependencies, and ask for required information.

3. **Password Setup**

   During the execution of the `setup.sh` script, you will be asked to enter a custom password for the node. This password will be saved internally in the working directory and will later be used by the `search-parent.sh` script for secure communication between nodes.

   ```bash
   Please enter a custom password for this node:
   ```

4. **Installation completion**

   The script will complete the installation of all required dependencies (such as Conda, Docker, and Docker Compose) and set up a systemd service to run the service every time the node is powered on and connected to the network. When the process is finished, you can continue setting up other worker nodes if necessary.

   ```bash
   Configuration finished on this worker node. You can continue setting up other worker nodes.
   ```

Now, the process is fully automated and only requires you to enter the password during the script execution.

> **⚠️ Important Note:**
>
> Only nodes that have been added to the **whitelist** of the API can automatically join the cluster. Make sure the node is on the list before trying to join.

---

# 4. API - Node Manager

This Flask application exposes several endpoints that interact with Docker Swarm and manage devices joining the network and interaction with a whitelist of MAC addresses. The endpoints provide functionality for validating tokens, adding/removing MAC addresses from the whitelist, and updating Docker join tokens.

---

#### 1. **POST /network/<string:mac>/join**

- **Description**: This endpoint handles a device request to join the network. It validates the provided token and MAC address, then returns a Docker join token and the device's IP address if successful.
  
- **Parameters**:
  - `mac` (str): The MAC address of the device trying to join the network.

- **Request JSON Body**:
  ```json
  {
    "token": "your_token",
    "req_ip": "device_ip"
  }
  ```

- **Response**:
  - **Success**: Returns the Docker join token and the device's IP address.
  ```json
  {
    "token": "docker_token",
    "ip": "device_ip:port"
  }
  ```
  - **Error**: Returns error messages if validation fails.
  ```json
  {
    "error": "Error message"
  }
  ```

---

#### 2. **POST /network/whitelist/<string:mac>/add**

- **Description**: This endpoint adds a MAC address to the network's whitelist. It validates the token and the format of the MAC address.

- **Parameters**:
  - `mac` (str): The MAC address to add to the whitelist.

- **Request JSON Body**:
  ```json
  {
    "token": "your_token"
  }
  ```

- **Response**:
  - **Success**: A message confirming the MAC address was added to the whitelist.
  ```json
  {
    "message": "MAC address successfully added to the whitelist"
  }
  ```
  - **Error**: Returns error messages if validation fails.
  ```json
  {
    "error": "Error message"
  }
  ```

---

#### 3. **POST /network/whitelist/<string:mac>/remove**

- **Description**: This endpoint removes a MAC address from the network's whitelist. It also validates the token and the MAC address format.

- **Parameters**:
  - `mac` (str): The MAC address to remove from the whitelist.

- **Request JSON Body**:
  ```json
  {
    "token": "your_token"
  }
  ```

- **Response**:
  - **Success**: A message confirming the MAC address was removed from the whitelist.
  ```json
  {
    "message": "MAC address successfully removed from the whitelist"
  }
  ```
  - **Error**: Returns error messages if validation fails.
  ```json
  {
    "error": "Error message"
  }
  ```

---

#### 4. **POST /network/whitelist/set**

- **Description**: This endpoint sets the whitelist with a new list of MAC addresses. It validates the provided token and the format of the MAC addresses.

- **Request JSON Body**:
  ```json
  {
    "token": "your_token",
    "whitelist": [
      "mac_address_1",
      "mac_address_2",
      "mac_address_3"
    ]
  }
  ```

- **Response**:
  - **Success**: A message confirming the whitelist was successfully updated.
  ```json
  {
    "message": "Whitelist successfully updated"
  }
  ```
  - **Error**: Returns error messages if validation fails.
  ```json
  {
    "error": "Error message"
  }
  ```

---

Aquí tienes la traducción al inglés:  

---

#### 5. **PUT /network/update/<string:join_token>**  

- **Description**: This endpoint updates the Docker join token stored in the `join.txt` file. It requires the new join token to be provided.  

- **Parameters**:  
  - `join_token` (str): The new Docker join token.  

- **JSON Request Body**:  
  - None required. The token is passed in the URL.  

- **Response**:  
  - **Success**: A message confirming that the Docker join token was successfully updated.  
  ```json
  {
    "message": "Docker join token successfully updated"
  }
  ```  
  - **Error**: Returns error messages if there is a problem with the file or the request.  
  ```json
  {
    "error": "Error message"
  }
  ```  

---

#### 6. **PUT /network/update/token**  

- **Description**: This endpoint updates the main token stored in the `token.txt` file. It requires both the old token and the new token.  

- **JSON Request Body**:  
  ```json
  {
    "old_token": "old_token",
    "new_token": "new_token"
  }
  ```  

- **Response**:  
  - **Success**: A message confirming that the main token was successfully updated.  
  ```json
  {
    "message": "Main token successfully updated"
  }
  ```  
  - **Error**: Returns error messages if validation fails or the file is not found.  
  ```json
  {
    "error": "Error message"
  }
  ```  

---

### **Common Error Responses**  

- **Invalid MAC address format**: If the MAC address is not in the correct format (e.g., `XX:XX:XX:XX:XX:XX`), an error message will be returned.  

  Example:  
  ```json
  {
    "error": "Invalid MAC address format"
  }
  ```  

- **Invalid token**: If the provided token does not match the configured token in `token.txt`, an error message will be returned.  

  Example:  
  ```json
  {
    "error": "Invalid token"
  }
  ```  

- **File not found**: If the expected file (e.g., `token.txt`, `join.txt`, `whitelist.txt`) is missing from the server, a "File not found" error will be returned.  

  Example:  
  ```json
  {
    "error": "File not found"
  }
  ```  

---

# 5. Troubleshooting  

Below are some common issues and how to resolve them.  

## 4.1. The `search-parent.service` is not active  

If the service is not active, check the service logs to see what happened:  

```bash
sudo journalctl -u search-parent.service
```  

This will provide detailed information about possible script errors or configuration issues. Make sure that the `password.txt` file is present and that the password is correctly configured.  

## 4.2. Error joining the Docker cluster  

If a node fails to join the Docker cluster, ensure that:  

- The access token is correctly configured.  
- The local network is properly set up and the nodes can communicate with each other.  
- Port 2377 (used by Docker Swarm for node communication) is open in the firewall of all nodes.  

---

# 6. Maintenance  

To keep Docker Self Discover updated and functional, perform the following steps regularly:  

1. **Update the system and dependencies**: Ensure that the operating system and dependencies such as Docker, Docker Compose, and Miniconda are up to date.  

   ```bash
   sudo apt update && sudo apt upgrade -y
   ```  

2. **Check service logs**: Regularly check the logs of the `search-parent.service` to ensure that there are no errors or issues requiring intervention.  

   ```bash
   sudo journalctl -u search-parent.service
   ```  

3. **Restart the service after changes**: If you modify node configurations or scripts, restart the service to apply the changes:  

   ```bash
   sudo systemctl restart search-parent.service
   ```  

---

# 7. Contributing  

If you want to contribute to the Docker Self Discover project, follow these steps:  

1. **Fork** the repository on GitHub.  
2. Make your changes and ensure the code works correctly.  
3. Submit a **pull request** describing the modifications made.  

Make sure to follow coding best practices and perform tests before submitting a pull request.  

### **You can also open issues if you find a new feature that should be implemented.**  

---

# 8. ToDo:  

- Add other architectures support
- Validate tail crop
- API - Master node (node management features)
- API - Worker Node 
- Web interface
- Dashboard Manager  
- Dashboard Worker  

---

Let me know if you need any adjustments! 🚀
