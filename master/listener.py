import subprocess
from flask import Flask, request, jsonify
from flask_cors import CORS


app = Flask(__name__)
CORS(app)

# File paths
token_path = "./resources/token.txt"
join_path = "./resources/join.txt"
whitelist_path = './resources/whitelist.txt'


def token_validation(token):
    # Validate token by comparing with configured token in token.txt
    try:
        with open(token_path, 'r') as tf:
            configured_token = tf.read().strip()
    except FileNotFoundError:
        return None
    return token == configured_token
    

@app.route('/network/<string:mac>/join', methods=["POST"])
def join_network(mac):
    """
    Handles the request for a device to join the network.

    Parameters:
        mac (str): The MAC address of the device requesting to join the network.

    Returns:
        Response: A JSON response indicating the status of the join request.
    """

    # Retrieve JSON Request
    req = request.get_json()

    # Check if the token is in the request
    if 'token' not in req:
        return jsonify({"error": "Token is required"}), 400
    
    token = req["token"]
    
    # Token validation
    validation = token_validation(token)
    if validation == None or validation == False:
        return jsonify({"error": "Configured token not found." if validation == None else "Invalid token."}), 500

    # Validate MAC address (simple validation)
    if len(mac.split(":")) != 6:
        return jsonify({"error": "Invalid MAC address format"}), 400

    # Retrieve ip from request
    device_ip = req["req_ip"]

    # Return response with the Docker join token and device IP
    try:
        with open(join_path, 'r') as jf:
            docker_join_token = jf.read().strip()
            # If join_token is empty docker swarm is not init
            if not docker_join_token:
                # wait for execution
                try:
                    subprocess.check_output([ "docker", "swarm", "init", f"--advertise-addr={device_ip}" ])
                except subprocess.CalledProcessError as e:
                    print("Swarm already in use")
                # Store token
                jtk = subprocess.check_output([ "docker", "swarm", "join-token", "worker" ], stderr=subprocess.STDOUT)
                docker_join_token = jtk.decode("utf-8").strip()
                with open(join_path, 'w') as jf:
                    jf.write(docker_join_token)
    except FileNotFoundError:
        return jsonify({"error": "Join token not found"}), 500

    docker_join_token = docker_join_token.split()
    tkn = docker_join_token[-2]
    ip_port = docker_join_token[-1]
    ip_port = ip_port.split(":")
    ip_port = ip_port[-1]
    
    return jsonify({
        "token": tkn,
        "ip": f"{device_ip}:{ip_port}"
    })


@app.route('/network/whitelist/<string:mac>/add', methods=["POST"])
def add_to_whitelist(mac):
    """
    Adds a MAC address to the network's whitelist.

    Parameters:
        mac (str): The MAC address to be added to the whitelist.

    Returns:
        Response: A JSON response indicating the status of the whitelist addition.
    """

    # Retrieve JSON Request
    req = request.get_json()

    # Check if the token is in the request
    if 'token' not in req:
        return jsonify({"error": "Token is required"}), 400
    
    token = req["token"]
    
    # Token validation
    validation = token_validation(token)
    if validation == None or validation == False:
        return jsonify({"error": "Configured token not found." if validation == None else "Invalid token."}), 500

    # Validate MAC address (simple validation)
    if len(mac.split(":")) != 6:
        return jsonify({"error": "Invalid MAC address format"}), 400

    # Add MAC address to the whitelist file
    try:
        with open(whitelist_path, 'a') as wlf:
            wlf.write(mac + "\n")
    except FileNotFoundError:
        return jsonify({"error": "Whitelist file not found"}), 500

    return jsonify({"message": f"MAC address {mac} added to whitelist successfully"}), 200

    
@app.route('/network/whitelist/<string:mac>/remove', methods=["POST"])
def remove_from_whitelist(mac):
    """
    Removes a MAC address from the network's whitelist.

    Parameters:
        mac (str): The MAC address to be removed from the whitelist.

    Returns:
        Response: A JSON response indicating the status of the whitelist removal.
    """

    # Retrieve JSON Request
    req = request.get_json()

    # Get token from request
    if 'token' not in req:
        return jsonify({"error": "Token is required"}), 400
    
    token = req["token"]

    # Token validation
    validation = token_validation(token)
    if validation is None or not validation:
        return jsonify({"error": "Configured token not found." if validation is None else "Invalid token."}), 500

    # Validate MAC address (simple validation)
    if len(mac.split(":")) != 6:
        return jsonify({"error": "Invalid MAC address format"}), 400

    # Remove MAC address from whitelist file
    try:
        with open(whitelist_path, 'r') as wlf:
            whitelist = wlf.readlines()
        
        # Remove the MAC address from the list
        with open(whitelist_path, 'w') as wlf:
            for line in whitelist:
                if line.strip() != mac:
                    wlf.write(line)
        
    except FileNotFoundError:
        return jsonify({"error": "Whitelist file not found"}), 500

    return jsonify({"message": f"MAC address {mac} removed from whitelist successfully"}), 200


@app.route('/network/whitelist/set', methods=["POST"])
def set_whitelist():
    """
    Sets the whitelist with a new list of MAC addresses.

    Parameters:
        None

    Returns:
        Response: A JSON response indicating the status of the whitelist update.
    """

    # Retrieve JSON Request
    req = request.get_json()

    # Get token from request
    if 'token' not in req:
        return jsonify({"error": "Token is required"}), 400
    token = req["token"]

    # Token validation
    validation = token_validation(token)
    if validation is None or not validation:
        return jsonify({"error": "Configured token not found." if validation is None else "Invalid token."}), 500

    # Validate whitelist (must be an array of MAC addresses)
    if 'whitelist' not in req or not isinstance(req['whitelist'], list):
        return jsonify({"error": "Whitelist must be provided as an array of MAC addresses."}), 400

    whitelist = req["whitelist"]

    # Validate each MAC address format
    for mac in whitelist:
        if len(mac.split(":")) != 6:
            return jsonify({"error": f"Invalid MAC address format: {mac}"}), 400

    # Write the whitelist to the file
    try:
        with open(whitelist_path, 'w') as wlf:
            for mac in whitelist:
                wlf.write(mac + "\n")
    except FileNotFoundError:
        return jsonify({"error": "Whitelist file not found"}), 500

    return jsonify({"message": "Whitelist updated successfully"}), 200
    
    
@app.route('/network/update/<string:join_token>', methods=["PUT"])
def update_docker_token(join_token):
    """
    Updates the Docker join token in the `join.txt` file.

    Parameters:
        join_token (str): The new Docker join token to be written to the `join.txt` file.

    Returns:
        Response: A JSON response indicating the status of the Docker join token update.
"""

    # Update the join token in join.txt
    try:
        with open(join_path, 'w') as jf:
            jf.write(join_token + "\n")
    except FileNotFoundError:
        return jsonify({"error": "join.txt file not found"}), 500

    return jsonify({"message": f"Docker join token updated successfully to {join_token}"}), 200

@app.route('/network/update/token', methods=["PUT"])
def update_token():
    # Retrieve JSON Request
    req = request.get_json()

    # Get token from request
    if 'new_token' not in req or 'old_token' not in req:
        return jsonify({"error": "old_token and new_token are required"}), 400
    old_token = req["old_token"]
    token = req["new_token"]
    
    # Token validation
    validation = token_validation(old_token)
    if validation is None or not validation:
        return jsonify({"error": "Configured token not found." if validation is None else "Invalid token."}), 500
    
    # Update the join token in join.txt
    try:
        with open(token_path, 'w') as tf:
            tf.write(token + "\n")
    except FileNotFoundError:
        return jsonify({"error": "token.txt file not found"}), 500

    return jsonify({"message": f"Main token updated successfully to {token}"}), 200


if __name__ == '__main__':
    with open(join_path, 'w') as jf:
        jf.write("")
    app.run(host='0.0.0.0', port=32100, debug=True)