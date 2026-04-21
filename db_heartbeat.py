import os
from supabase import create_client

# We use get() so the script doesn't crash if keys are missing
url = os.environ.get("SUPABASE_SPECVAULT_DATA_API_URL")
key = os.environ.get("SUPABASE_SPECVAULT_SRKEY")

def heartbeat():
    if not url or not key:
        print("Error: Secrets not found in environment.")
        return

    try:
        # Initialize with service_role key (bypasses RLS)
        supabase = create_client(url, key)
        
        # The lightest possible 'activity' to trigger Supabase
        response = supabase.rpc("version").execute()
        
        if response.data:
            print(f"Success: SpecVault is awake.")
            print(f"DB Version: {response.data}")
            print(f"Activity recorded using service_role permissions.")
    except Exception as e:
        print(f"Heartbeat failed: {e}")

if __name__ == "__main__":
    heartbeat()
