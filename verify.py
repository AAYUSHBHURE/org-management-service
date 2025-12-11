import requests
import sys

BASE_URL = "http://127.0.0.1:8000"

def test_create_org():
    print("\n[TEST] Create Organization")
    payload = {
        "organization_name": "TechCorp",
        "email": "admin@techcorp.com",
        "password": "securepassword123"
    }
    response = requests.post(f"{BASE_URL}/org/create", json=payload)
    if response.status_code == 200:
        print("PASS: Organization created.")
        print(response.json())
        return True
    else:
        # If it already exists from a previous run, that's okay, we can proceed to test login.
        if response.status_code == 400 and "already exists" in response.text:
            print("INFO: Organization already exists. Proceeding.")
            return True
        print(f"FAIL: {response.status_code} - {response.text}")
        return False

def test_create_duplicate_org():
    print("\n[TEST] Create Duplicate Organization")
    payload = {
        "organization_name": "TechCorp",
        "email": "admin@techcorp.com",
        "password": "securepassword123"
    }
    response = requests.post(f"{BASE_URL}/org/create", json=payload)
    if response.status_code == 400:
        print("PASS: Duplicate creation prevented.")
        return True
    else:
        print(f"FAIL: Expected 400, got {response.status_code} - {response.text}")
        return False

def test_admin_login():
    print("\n[TEST] Admin Login")
    payload = {
        "email": "admin@techcorp.com",
        "password": "securepassword123"
    }
    response = requests.post(f"{BASE_URL}/admin/login", json=payload)
    if response.status_code == 200:
        data = response.json()
        print("PASS: Login successful.")
        return data["access_token"]
    else:
        print(f"FAIL: {response.status_code} - {response.text}")
        return None

def test_get_org():
    print("\n[TEST] Get Organization")
    response = requests.get(f"{BASE_URL}/org/get?organization_name=TechCorp")
    if response.status_code == 200:
        print("PASS: Organization fetched.")
        print(response.json())
        return True
    else:
        print(f"FAIL: {response.status_code} - {response.text}")
        return False

def test_update_org():
    print("\n[TEST] Update Organization")
    payload = {
        "organization_name": "TechCorp",
        "email": "newadmin@techcorp.com"
    }
    response = requests.put(f"{BASE_URL}/org/update", json=payload)
    if response.status_code == 200:
        print("PASS: Organization updated.")
        print(response.json())
        return True
    else:
        print(f"FAIL: {response.status_code} - {response.text}")
        return False

def test_delete_org():
    print("\n[TEST] Delete Organization")
    response = requests.delete(f"{BASE_URL}/org/delete?organization_name=TechCorp")
    if response.status_code == 200:
        print("PASS: Organization deleted.")
        return True
    else:
        print(f"FAIL: {response.status_code} - {response.text}")
        return False

def main():
    if not test_create_org(): sys.exit(1)
    if not test_create_duplicate_org(): sys.exit(1)
    
    token = test_admin_login()
    if not token: sys.exit(1)
    
    if not test_get_org(): sys.exit(1)
    if not test_update_org(): sys.exit(1)
    
    # We delete at the end to clean up
    if not test_delete_org(): sys.exit(1)
    
    print("\n[SUMMARY] All tests passed!")

if __name__ == "__main__":
    try:
        main()
    except requests.exceptions.ConnectionError:
        print("FAIL: Could not connect to server. Is it running?")
