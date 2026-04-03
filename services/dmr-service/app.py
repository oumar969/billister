"""
Danish Motor Registry (DMR) Lookup Service
Wrapper around dmr.py for .NET backend
"""
from flask import Flask, request, jsonify
from flask_cors import CORS
import logging
from datetime import datetime

try:
    from dmr import DMR
except ImportError:
    print("ERROR: dmr.py not installed. Run: pip install dmr.py")
    DMR = None

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    if DMR is None:
        return jsonify({"status": "error", "message": "dmr.py not available"}), 503
    return jsonify({"status": "ok", "service": "DMR Service"}), 200


@app.route('/api/vehicles/plate/<plate>', methods=['GET'])
def lookup_plate(plate):
    """
    GET /api/vehicles/plate/{plate}
    
    Lookup vehicle by license plate
    Example: GET /api/vehicles/plate/CW87553
    
    Returns:
    - 200: {data: {make, model, year, fuelType, ...}}
    - 404: {error: "Vehicle not found"}
    - 400: {error: "Invalid plate format"}
    """
    try:
        if DMR is None:
            return jsonify({"error": "Service unavailable", "message": "dmr.py not installed"}), 503
        
        logger.info(f"🔍 Lookup plate: {plate}")
        
        # Validate plate format
        if not DMR.validate_license_plate(plate):
            logger.warning(f"❌ Invalid format: {plate}")
            return jsonify({
                "error": "Invalid license plate format",
                "plate": plate
            }), 400
        
        # Get vehicle
        vehicle = DMR.get_by_plate(plate)
        
        if vehicle is None:
            logger.info(f"❌ Not found: {plate}")
            return jsonify({
                "error": "Vehicle not found",
                "plate": plate,
                "message": "Køretøjet blev ikke fundet i motorregisteret"
            }), 404
        
        # Success
        vehicle_data = vehicle.model_dump()
        logger.info(f"✅ Found: {vehicle.make} {vehicle.model} ({plate})")
        
        return jsonify({
            "data": vehicle_data,
            "plate": plate,
            "make": vehicle.make,
            "model": vehicle.model
        }), 200
        
    except Exception as e:
        logger.error(f"💥 Error: {str(e)}", exc_info=True)
        return jsonify({
            "error": "Lookup failed",
            "message": str(e),
            "plate": plate
        }), 500


@app.route('/api/vehicles/validate/<plate>', methods=['GET'])
def validate_plate(plate):
    """
    GET /api/vehicles/validate/{plate}
    
    Validate license plate format
    """
    try:
        if DMR is None:
            return jsonify({"error": "Service unavailable"}), 503
        
        is_valid = DMR.validate_license_plate(plate)
        return jsonify({
            "plate": plate,
            "isValid": is_valid
        }), 200
        
    except Exception as e:
        logger.error(f"Validation error: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route('/api/info', methods=['GET'])
def info():
    """Service information"""
    return jsonify({
        "service": "DMR Python Service",
        "version": "1.0.0",
        "status": "ok" if DMR else "error",
        "description": "Danish Motor Registry lookup wrapper",
        "endpoints": [
            "GET /health",
            "GET /api/info",
            "GET /api/vehicles/plate/{plate}",
            "GET /api/vehicles/validate/{plate}"
        ]
    }), 200


if __name__ == '__main__':
    if DMR is None:
        print("ERROR: dmr.py is required. Install with: pip install dmr.py")
        exit(1)
    
    logger.info("🚀 Starting DMR Service on http://localhost:5001")
    app.run(host='127.0.0.1', port=5001, debug=False, threaded=True)

