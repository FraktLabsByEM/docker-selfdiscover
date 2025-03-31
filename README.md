# Docker Self-discover

### General Description

This project aims to facilitate the automatic integration of devices into a network, validating their access via a server and performing background configuration tasks. It consists of two main parts: **Master** and **Worker**. The **Master** handles the server and configuration, while the **Worker** scans for devices in the network and automatically integrates them into the system.

### Main Components

1. **Listener** (Master)
   - **listener.py**: A Flask server that handles requests from devices attempting to join the network. It validates the requests using a token and MAC address, and allows token and whitelist updates.
   - **init.sh**: Configuration script to set up the Conda environment and run the `listener.py` server.
   - **setup-master.sh**: Script to set up and run the `listener.py` service at system startup.

2. **Search Parent** (Worker)
   - **search-parent.sh**: Script that scans the network for devices and sends requests to a server to integrate those devices into the network.
   - **setup-worker.sh**: Script to set up and run the service that executes `search-parent.sh` at system startup.

---

## Installation and Setup

### 1. Installing `Listener` (Master)

#### Step 1: Set up the Environment
Make sure Anaconda and Python are installed. The `listener.py` server uses a specific Conda environment.

#### Step 2: Activate the Environment
Run the `init.sh` script to activate the Conda environment and start the server:

```bash
bash init.sh
```

#### Step 3: Service Configuration
To ensure the server runs at system startup, execute the `setup-master.sh` script:

```bash
bash setup-master.sh
```

This script will:
- Set the execution permissions for `init.sh`.
- Create a `systemd` service to run the server at system startup.
- Start the service and ensure it runs automatically on boot.

---

### 2. Installing `Search Parent` (Worker)

#### Step 1: Verify Dependencies
The `search-parent.sh` script depends on network tools such as `nmap` and `curl`. Ensure these tools are installed on the system.

#### Step 2: Set up the Service
To turn `search-parent.sh` into a service that runs at system startup, execute the `setup-worker.sh` script:

```bash
bash setup-worker.sh
```

This script will:
- Grant execution permissions to `search-parent.sh`.
- Create a `systemd` service to run `search-parent.sh` at system startup.
- Reload the `systemd` daemon and enable the service.

---

## Technical Details

### `listener.py` (Flask Server)
The `listener.py` server exposes several routes to manage requests from devices in the network:

1. **POST `/network/<mac>/join`**: Allows a device to join the network if a valid token and MAC address are provided. The server returns a Docker join token.
2. **POST `/network/whitelist/<mac>/add`**: Adds a MAC address to the whitelist.
3. **POST `/network/whitelist/<mac>/remove`**: Removes a MAC address from the whitelist.
4. **POST `/network/whitelist/set`**: Sets a new whitelist of MAC addresses.
5. **PUT `/network/update/<join_token>`**: Updates the Docker join token.
6. **PUT `/network/update/token`**: Updates the main authentication token.

### `search-parent.sh` (Worker)
The `search-parent.sh` script performs a scan of devices on the local network using `nmap`, and sends POST requests to the devices found to attempt to integrate them into the network using the `listener.py` server.

1. **Network Scan**: Uses `nmap` to discover devices on the same subnet.
2. **POST Request**: For each device found, a POST request is made to the server with the authentication token and the device’s IP address.

---

## Commercial Use

This project is designed to be used in automated network environments where devices need to be integrated into the network seamlessly without manual intervention. Some potential commercial applications include:

- **IoT Networks**: Automating the integration of devices into local networks for Internet of Things (IoT) solutions.
- **Enterprise Network Management**: Streamlining the process of managing corporate networks by automating device integration.
- **Security Systems**: Automatically verifying devices connecting to the network, enhancing network security.

---

## Contributing

Contributions are welcome! To improve this project, please follow these steps:

1. Fork this repository.
2. Create a branch for your new feature.
3. Make your changes and ensure the tests pass.
4. Submit a pull request detailing the changes you’ve made.

---

## License

This project is licensed under the MIT License.

---