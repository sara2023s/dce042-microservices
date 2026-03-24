"""
Product Service (Service A)
Microservice for managing product catalogue stored in DynamoDB.
"""
import os
import json
import uuid
import boto3
from flask import Flask, jsonify, request
from botocore.exceptions import ClientError

app = Flask(__name__)

# ── AWS clients ───────────────────────────────────────────────────────────────
AWS_REGION     = os.environ.get("AWS_REGION", "us-east-1")
DYNAMODB_TABLE = os.environ.get("DYNAMODB_TABLE", "dce042-dev-app-data")

dynamodb = boto3.resource("dynamodb", region_name=AWS_REGION)
table    = dynamodb.Table(DYNAMODB_TABLE)

# ── Health check ──────────────────────────────────────────────────────────────
@app.route("/health")
def health():
    return jsonify({"status": "healthy", "service": "product-service"}), 200

# ── List all products ─────────────────────────────────────────────────────────
@app.route("/products", methods=["GET"])
def list_products():
    try:
        response = table.query(
            KeyConditionExpression="PK = :pk",
            ExpressionAttributeValues={":pk": "PRODUCT"}
        )
        return jsonify({"products": response.get("Items", [])}), 200
    except ClientError as e:
        return jsonify({"error": str(e)}), 500

# ── Get single product ────────────────────────────────────────────────────────
@app.route("/products/<product_id>", methods=["GET"])
def get_product(product_id):
    try:
        response = table.get_item(Key={"PK": "PRODUCT", "SK": product_id})
        item = response.get("Item")
        if not item:
            return jsonify({"error": "Product not found"}), 404
        return jsonify(item), 200
    except ClientError as e:
        return jsonify({"error": str(e)}), 500

# ── Create product ────────────────────────────────────────────────────────────
@app.route("/products", methods=["POST"])
def create_product():
    data = request.get_json()
    if not data or "name" not in data:
        return jsonify({"error": "name is required"}), 400

    product_id = str(uuid.uuid4())
    item = {
        "PK":          "PRODUCT",
        "SK":          product_id,
        "name":        data["name"],
        "description": data.get("description", ""),
        "price":       str(data.get("price", "0.00")),
    }
    try:
        table.put_item(Item=item)
        return jsonify(item), 201
    except ClientError as e:
        return jsonify({"error": str(e)}), 500

# ── Delete product ────────────────────────────────────────────────────────────
@app.route("/products/<product_id>", methods=["DELETE"])
def delete_product(product_id):
    try:
        table.delete_item(Key={"PK": "PRODUCT", "SK": product_id})
        return jsonify({"message": "deleted"}), 200
    except ClientError as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
