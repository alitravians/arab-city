#!/usr/bin/env python3
"""Upload FBX mesh files to Roblox using Open Cloud Assets API."""

import os
import json
import time
import requests

API_KEY = open("/tmp/asset_api_key.txt").read().strip()
EXPORTS_DIR = "/home/ubuntu/repos/arab-city/blender_models/exports"
CREATOR_ID = "3562121656"  # User ID for aboodised

UPLOAD_URL = "https://apis.roblox.com/assets/v1/assets"

MODELS = [
    "residential_house.fbx",
    "apartment_building.fbx",
    "bank.fbx",
    "hospital.fbx",
    "mall.fbx",
    "police_station.fbx",
    "fire_station.fbx",
    "airport_terminal.fbx",
    "vip_lounge.fbx",
    "car_dealership.fbx",
    "furniture_livingroom.fbx",
    "furniture_bedroom.fbx",
    "furniture_kitchen.fbx",
    "furniture_office.fbx",
]

DISPLAY_NAMES = {
    "residential_house.fbx": "ArabCity Residential House",
    "apartment_building.fbx": "ArabCity Apartment Building",
    "bank.fbx": "ArabCity Bank",
    "hospital.fbx": "ArabCity Hospital",
    "mall.fbx": "ArabCity Mall",
    "police_station.fbx": "ArabCity Police Station",
    "fire_station.fbx": "ArabCity Fire Station",
    "airport_terminal.fbx": "ArabCity Airport Terminal",
    "vip_lounge.fbx": "ArabCity VIP Lounge",
    "car_dealership.fbx": "ArabCity Car Dealership",
    "furniture_livingroom.fbx": "ArabCity Living Room Furniture",
    "furniture_bedroom.fbx": "ArabCity Bedroom Furniture",
    "furniture_kitchen.fbx": "ArabCity Kitchen Furniture",
    "furniture_office.fbx": "ArabCity Office Furniture",
}


def upload_model(filename):
    """Upload a single FBX file as a Model asset."""
    filepath = os.path.join(EXPORTS_DIR, filename)
    display_name = DISPLAY_NAMES.get(filename, filename.replace(".fbx", ""))

    # Create the request metadata
    request_body = {
        "assetType": "Model",
        "displayName": display_name,
        "description": f"3D building model for Arab City game - {display_name}",
        "creationContext": {
            "creator": {
                "userId": CREATOR_ID
            }
        }
    }

    headers = {
        "x-api-key": API_KEY,
    }

    with open(filepath, "rb") as f:
        files = {
            "request": (None, json.dumps(request_body), "application/json"),
            "fileContent": (filename, f, "application/octet-stream"),
        }
        
        print(f"Uploading {filename} ({os.path.getsize(filepath)} bytes)...")
        resp = requests.post(UPLOAD_URL, headers=headers, files=files)

    if resp.status_code in (200, 201):
        data = resp.json()
        print(f"  SUCCESS: {json.dumps(data, indent=2)}")
        return data
    else:
        print(f"  ERROR {resp.status_code}: {resp.text}")
        return None


def check_operation(operation_path):
    """Check the status of an asset upload operation."""
    url = f"https://apis.roblox.com/{operation_path}"
    headers = {"x-api-key": API_KEY}
    resp = requests.get(url, headers=headers)
    if resp.status_code == 200:
        return resp.json()
    return None


def main():
    results = {}
    
    for filename in MODELS:
        result = upload_model(filename)
        if result:
            results[filename] = result
        time.sleep(2)  # Rate limiting
    
    # Save results
    output_path = "/home/ubuntu/repos/arab-city/blender_models/upload_results.json"
    with open(output_path, "w") as f:
        json.dump(results, f, indent=2)
    
    print(f"\n\nResults saved to {output_path}")
    print(f"Successfully uploaded: {len(results)}/{len(MODELS)}")
    
    # Wait and check operations
    print("\nChecking operation statuses...")
    time.sleep(5)
    
    for filename, result in results.items():
        if "path" in result:
            status = check_operation(result["path"])
            if status:
                print(f"  {filename}: {json.dumps(status, indent=2)}")


if __name__ == "__main__":
    main()
