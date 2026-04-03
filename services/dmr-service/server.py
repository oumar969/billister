from flask import Flask, jsonify, request
from flask_cors import CORS
import requests
from bs4 import BeautifulSoup
import logging
import time
from typing import Optional, Dict, Any
import os

app = Flask(__name__)
# CORS is essential - allows Flutter app to call this server
CORS(app)

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Motorregister configuration
MOTORREGISTER_URL = "https://motorregister.skat.dk/dmr-kerne/koeretoejdetaljer/visKoeretoej"
MOTORREGISTER_HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'da-DK,da;q=0.9',
    'Accept-Encoding': 'gzip, deflate, br',
    'DNT': '1',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
}

# Mock data for development/testing
MOCK_DATA = {
    'AB12345': {'make': 'Toyota', 'model': 'Yaris', 'year': 2020, 'fuelType': 'Benzin', 'transmission': 'Manual', 'kilometers': 45000, 'color': 'Rød', 'co2Emissions': 110},
    'CD67890': {'make': 'Honda', 'model': 'Civic', 'year': 2019, 'fuelType': 'Diesel', 'transmission': 'Automat', 'kilometers': 62000, 'color': 'Sort', 'co2Emissions': 95},
    'EF34567': {'make': 'Volkswagen', 'model': 'Golf', 'year': 2021, 'fuelType': 'Hybrid', 'transmission': 'Manual', 'kilometers': 28000, 'color': 'Hvid', 'co2Emissions': 85},
    'GH89012': {'make': 'BMW', 'model': '320i', 'year': 2018, 'fuelType': 'Benzin', 'transmission': 'Automat', 'kilometers': 78000, 'color': 'Grå', 'co2Emissions': 125},
}

USE_MOCK_DATA = os.getenv('USE_MOCK_DATA', 'true').lower() == 'true'

def lookup_motorregister(plate: str) -> Optional[Dict[str, Any]]:
    """
    Lookup vehicle data from motorregister.skat.dk
    Returns dict with vehicle data or None if not found
    """
    try:
        logger.info(f"🔍 Querying motorregister for plate: {plate}")
        
        # Make request to motorregister
        response = requests.get(
            MOTORREGISTER_URL,
            params={'nummerPlade': plate},
            headers=MOTORREGISTER_HEADERS,
            timeout=10
        )
        response.raise_for_status()
        
        html = response.text
        
        # Check if vehicle was found
        if "Køretøj ikke fundet" in html or "ikke fundet" in html.lower():
            logger.warning(f"❌ Vehicle not found in registry: {plate}")
            return None
        
        # Parse HTML
        soup = BeautifulSoup(html, 'html.parser')
        vehicle_data = {}
        
        # Try to extract common vehicle fields
        # Note: HTML structure may vary, so we try multiple selectors
        table_rows = soup.find_all('tr')
        for row in table_rows:
            cells = row.find_all('td')
            if len(cells) >= 2:
                label = cells[0].get_text(strip=True).lower()
                value = cells[1].get_text(strip=True)
                
                # Map Danish labels to English keys
                if 'mærke' in label or 'merk' in label:
                    vehicle_data['make'] = value
                elif 'type' in label or 'model' in label:
                    vehicle_data['model'] = value
                elif 'årgang' in label or 'år' in label or 'year' in label:
                    try:
                        vehicle_data['year'] = int(value) if value else None
                    except:
                        pass
                elif 'brændstof' in label or 'fuel' in label:
                    vehicle_data['fuelType'] = value
                elif 'transmission' in label or 'gear' in label:
                    vehicle_data['transmission'] = value
                elif 'kilometer' in label or 'km' in label:
                    vehicle_data['kilometers'] = value
                elif 'co2' in label:
                    vehicle_data['co2Emissions'] = value
                elif 'farve' in label or 'color' in label or 'colour' in label:
                    vehicle_data['color'] = value
        
        # If we found any data, return success
        if vehicle_data:
            logger.info(f"✅ Found vehicle: {vehicle_data.get('make', 'Unknown')} {vehicle_data.get('model', '')}")
            return vehicle_data
        else:
            logger.warning(f"⚠️  No vehicle data extracted for plate: {plate}")
            return None
            
    except requests.exceptions.Timeout:
        logger.error(f"⏱️  Timeout querying motorregister for {plate}")
        return None
    except Exception as e:
        logger.error(f"💥 Error querying motorregister: {str(e)}")
        return None

@app.route('/api/vehicles/plate/<plate>', methods=['GET'])
def get_vehicle(plate):
    """
    Lookup vehicle by license plate from motorregister.skat.dk
    Returns vehicle data as JSON or 404 if not found
    """
    try:
        plate = plate.upper().strip()
        logger.info(f"📋 Received lookup request for plate: {plate}")
        
        # Check mock data first (for development)
        if USE_MOCK_DATA and plate in MOCK_DATA:
            logger.info(f"🎭 Using mock data for plate: {plate}")
            return jsonify({
                "success": True,
                "data": {
                    "licensePlate": plate,
                    **MOCK_DATA[plate]
                }
            }), 200
        
        # Add small delay to avoid rate limiting
        time.sleep(0.5)
        
        # Lookup vehicle
        vehicle = lookup_motorregister(plate)
        
        if vehicle:
            return jsonify({
                "success": True,
                "data": {
                    "licensePlate": plate,
                    "make": vehicle.get('make', ''),
                    "model": vehicle.get('model', ''),
                    "year": vehicle.get('year'),
                    "fuelType": vehicle.get('fuelType', ''),
                    "transmission": vehicle.get('transmission', ''),
                    "kilometers": vehicle.get('kilometers'),
                    "color": vehicle.get('color', ''),
                    "co2Emissions": vehicle.get('co2Emissions'),
                }
            }), 200
        else:
            return jsonify({
                "success": False,
                "error": "Køretøj ikke fundet",
                "message": f"No vehicle found for plate {plate} in motorregister"
            }), 404
            
    except Exception as e:
        logger.error(f"💥 Unhandled error in get_vehicle: {str(e)}")
        return jsonify({
            "success": False,
            "error": "Server error",
            "message": str(e)
        }), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "ok", "service": "Vehicle Lookup", "mockData": USE_MOCK_DATA}), 200

if __name__ == '__main__':
    PORT = 8000
    print("=" * 60)
    print("🚗 Vehicle Lookup Server (Motorregister)")
    print("=" * 60)
    print(f"📍 Starting on http://localhost:{PORT}")
    print(f"🔗 API endpoint: http://localhost:{PORT}/api/vehicles/plate/")
    print(f"✅ Health check: http://localhost:{PORT}/health")
    if USE_MOCK_DATA:
        print(f"🎭 Mock Data ENABLED - use these test plates:")
        for plate in MOCK_DATA.keys():
            print(f"   - {plate}")
    else:
        print(f"📡 Mock Data DISABLED - using real motorregister.skat.dk")
    print("=" * 60)
    print("Press Ctrl+C to stop\n")
    
    app.run(host='0.0.0.0', port=PORT, debug=False)
    print(f"✅ Health check: http://localhost:{PORT}/health")
    print("=" * 60)
    print("Press Ctrl+C to stop\n")
    
    # Run with debug=True for development
    app.run(host='0.0.0.0', port=PORT, debug=False)
