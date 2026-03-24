"""
Order Service (Service B)
Microservice for managing customer orders stored in DynamoDB.
"""
import os
import json
import uuid
import boto3
from flask import Flask, jsonify, request
from botocore.exceptions import ClientError

app = Flask(__name__)

AWS_REGION     = os.environ.get("AWS_REGION", "us-east-1")
DYNAMODB_TABLE = os.environ.get("DYNAMODB_TABLE", "dce042-dev-app-data")

dynamodb = boto3.resource("dynamodb", region_name=AWS_REGION)
table    = dynamodb.Table(DYNAMODB_TABLE)

# ── Health check ──────────────────────────────────────────────────────────────
@app.route("/health")
def health():
    return jsonify({"status": "healthy", "service": "order-service"}), 200

# ── List all orders ───────────────────────────────────────────────────────────
@app.route("/orders", methods=["GET"])
def list_orders():
    try:
        response = table.query(
            KeyConditionExpression="PK = :pk",
            ExpressionAttributeValues={":pk": "ORDER"}
        )
        return jsonify({"orders": response.get("Items", [])}), 200
    except ClientError as e:
        return jsonify({"error": str(e)}), 500

# ── Get single order ──────────────────────────────────────────────────────────
@app.route("/orders/<order_id>", methods=["GET"])
def get_order(order_id):
    try:
        response = table.get_item(Key={"PK": "ORDER", "SK": order_id})
        item = response.get("Item")
        if not item:
            return jsonify({"error": "Order not found"}), 404
        return jsonify(item), 200
    except ClientError as e:
        return jsonify({"error": str(e)}), 500

# ── Create order ──────────────────────────────────────────────────────────────
@app.route("/orders", methods=["POST"])
def create_order():
    data = request.get_json()
    if not data or "product_id" not in data:
        return jsonify({"error": "product_id is required"}), 400

    order_id = str(uuid.uuid4())
    item = {
        "PK":         "ORDER",
        "SK":         order_id,
        "product_id": data["product_id"],
        "quantity":   int(data.get("quantity", 1)),
        "status":     "PENDING",
        "customer":   data.get("customer", "anonymous"),
    }
    try:
        table.put_item(Item=item)
        return jsonify(item), 201
    except ClientError as e:
        return jsonify({"error": str(e)}), 500

# ── Update order status ───────────────────────────────────────────────────────
@app.route("/orders/<order_id>/status", methods=["PUT"])
def update_order_status(order_id):
    data = request.get_json()
    status = data.get("status") if data else None
    if not status:
        return jsonify({"error": "status is required"}), 400

    try:
        table.update_item(
            Key={"PK": "ORDER", "SK": order_id},
            UpdateExpression="SET #s = :s",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={":s": status},
        )
        return jsonify({"order_id": order_id, "status": status}), 200
    except ClientError as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5001))
    app.run(host="0.0.0.0", port=port)
